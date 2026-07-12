"""
Orquestrador local do pipeline BlackBull.

Roda:
1. backup do banco atual;
2. carga raw via pipeline_dados.py;
3. SQLs de staging, dimensoes, fatos e validacoes;
4. testes de integridade;
5. restore automatico se algo quebrar.

"""

from __future__ import annotations

import argparse
import logging
import shutil
import sqlite3
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
DB_PATH = ROOT_DIR / "db" / "blackbull.db"
PIPELINE_PATH = ROOT_DIR / "src" / "pipeline_dados.py"
SQL_DIR = ROOT_DIR / "src" / "sql"
LOG_DIR = ROOT_DIR / "logs"
BACKUP_DIR = ROOT_DIR / "db" / "backups"


@dataclass(frozen=True)
class SqlStep:
    phase: str
    relative_path: str
    required: bool = True


SQL_STEPS: list[SqlStep] = [
    # Staging primeiro. Todas as dimensoes e fatos dependem disso.
    SqlStep("staging", "financeiro/02_build_stg_financeiro.sql"),
    SqlStep("staging", "pedidos/02_build_stg_pedidos.sql"),
    SqlStep("staging", "marketing/02_build_stg_marketing.sql"),
    SqlStep("staging", "redes_sociais/02_build_stg_redes_sociais.sql"),

    # Dimensoes. Algumas ainda estao em pastas de dominio, mas sao usadas
    # por mais de uma fato. TODO: mover dimensoes compartilhadas depois.
    SqlStep("dimensions", "financeiro/04_build_dim_financeiro.sql"),
    SqlStep("dimensions", "pedidos/04_build_dim_produto.sql"),
    SqlStep("dimensions", "pedidos/05_build_dim_cliente.sql"),
    SqlStep("dimensions", "pedidos/06_build_dim_canal.sql"),
    SqlStep("dimensions", "pedidos/07_build_dim_plataforma.sql"),
    SqlStep("dimensions", "pedidos/08_build_dim_bairro.sql"),
    SqlStep("dimensions", "pedidos/09_build_dim_status_pedido.sql"),
    SqlStep("dimensions", "pedidos/10_build_dim_forma_pagamento.sql"),
    SqlStep("dimensions", "pedidos/11_build_dim_cupom.sql"),
    SqlStep("dimensions", "marketing/04_build_dim_campanha_marketing.sql"),
    SqlStep("dimensions", "marketing/05_build_dim_plataforma_marketing.sql"),
    SqlStep("dimensions", "marketing/06_build_dim_cupom.sql"),
    SqlStep("dimensions", "redes_sociais/04_build_dim_rede_social.sql"),
    SqlStep("dimensions", "redes_sociais/05_build_dim_tipo_conteudo.sql"),
    SqlStep("dimensions", "redes_sociais/06_build_dim_tema_conteudo.sql"),

    # Fatos depois de todas as dimensoes ficarem prontas.
    SqlStep("facts", "financeiro/05_build_fato_financeiro.sql"),
    SqlStep("facts", "pedidos/12_build_fato_pedidos.sql"),
    SqlStep("facts", "marketing/08_build_fato_marketing.sql"),
    SqlStep("facts", "redes_sociais/07_build_fato_redes_sociais.sql"),

    # Validacoes SQL existentes. O orquestrador tambem faz checks em Python
    # porque os SELECTs daqui nao viram falha automaticamente.
    SqlStep("sql_validations", "financeiro/06_validacao_modelo_financeiro.sql"),
    SqlStep("sql_validations", "pedidos/13_validacao_modelo_pedidos.sql"),
    SqlStep("sql_validations", "marketing/09_validacao_modelo_marketing.sql"),
    SqlStep("sql_validations", "redes_sociais/08_validacao_modelo_redes_sociais.sql"),
]


class PipelineError(RuntimeError):
    pass


def setup_logging() -> Path:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_path = LOG_DIR / f"orquestrador_{stamp}.log"

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s",
        handlers=[
            logging.FileHandler(log_path, encoding="utf-8"),
            logging.StreamHandler(sys.stdout),
        ],
    )

    return log_path


def make_backup() -> Path | None:
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    if not DB_PATH.exists():
        logging.warning("Banco ainda nao existe. Nao ha backup para criar.")
        return None

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = BACKUP_DIR / f"blackbull_before_orquestrador_{stamp}.db"
    shutil.copy2(DB_PATH, backup_path)
    logging.info("Backup criado: %s", backup_path)
    return backup_path


def restore_backup(backup_path: Path | None) -> None:
    if backup_path is None:
        logging.warning("Sem backup para restaurar.")
        return

    if not backup_path.exists():
        logging.error("Backup esperado nao encontrado: %s", backup_path)
        return

    shutil.copy2(backup_path, DB_PATH)
    logging.warning("Banco restaurado a partir do backup: %s", backup_path)


def run_raw_pipeline(skip_raw: bool) -> None:
    if skip_raw:
        logging.info("Carga raw pulada por parametro --skip-raw.")
        return

    if not PIPELINE_PATH.exists():
        raise PipelineError(f"pipeline_dados.py nao encontrado: {PIPELINE_PATH}")

    logging.info("Rodando pipeline raw: %s", PIPELINE_PATH)
    start = time.perf_counter()
    result = subprocess.run(
        [sys.executable, str(PIPELINE_PATH)],
        cwd=ROOT_DIR,
        capture_output=True,
        text=True,
        check=False,
    )

    logging.info("Saida pipeline raw:\n%s", result.stdout.strip())
    if result.stderr.strip():
        logging.warning("Erros/avisos pipeline raw:\n%s", result.stderr.strip())

    if result.returncode != 0:
        raise PipelineError(f"pipeline_dados.py falhou com codigo {result.returncode}")

    logging.info("Pipeline raw finalizado em %.2fs", time.perf_counter() - start)


def execute_sql_file(conn: sqlite3.Connection, step: SqlStep) -> None:
    path = SQL_DIR / step.relative_path
    if not path.exists():
        if step.required:
            raise PipelineError(f"SQL obrigatorio nao encontrado: {path}")
        logging.warning("SQL opcional nao encontrado: %s", path)
        return

    sql = path.read_text(encoding="utf-8-sig")
    logging.info("[%s] Executando %s", step.phase, step.relative_path)

    start = time.perf_counter()
    try:
        conn.executescript(sql)
        conn.commit()
    except Exception:
        conn.rollback()
        raise

    logging.info("[%s] OK em %.2fs", step.phase, time.perf_counter() - start)


def run_sql_steps() -> None:
    if not DB_PATH.exists():
        raise PipelineError(f"Banco nao encontrado para execucao SQL: {DB_PATH}")

    logging.info("Conectando no banco: %s", DB_PATH)
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute("PRAGMA foreign_keys = OFF;")
        conn.execute("PRAGMA busy_timeout = 30000;")

        for step in SQL_STEPS:
            execute_sql_file(conn, step)


def fetch_one(conn: sqlite3.Connection, sql: str) -> tuple:
    row = conn.execute(sql).fetchone()
    return tuple(row or ())


def assert_equal(name: str, left, right) -> None:
    if left != right:
        raise PipelineError(f"{name}: esperado igualdade, recebido {left!r} vs {right!r}")


def assert_zero(name: str, value: int | None) -> None:
    value = 0 if value is None else value
    if value != 0:
        raise PipelineError(f"{name}: esperado 0, recebido {value}")


def assert_close(name: str, left: float | None, right: float | None, tolerance: float = 0.01) -> None:
    left = 0.0 if left is None else float(left)
    right = 0.0 if right is None else float(right)
    if abs(left - right) > tolerance:
        raise PipelineError(f"{name}: valores diferentes {left} vs {right}")


def validate_database() -> None:
    logging.info("Iniciando validacoes finais em Python.")

    with sqlite3.connect(DB_PATH) as conn:
        integrity = fetch_one(conn, "PRAGMA integrity_check;")[0]
        if integrity != "ok":
            raise PipelineError(f"PRAGMA integrity_check falhou: {integrity}")
        logging.info("PRAGMA integrity_check: ok")

        required_tables = [
            "raw_financeiro", "stg_financeiro", "fato_financeiro",
            "raw_pedidos", "stg_pedidos", "fato_pedidos",
            "raw_marketing", "stg_marketing", "fato_marketing",
            "raw_redessociais", "stg_redes_sociais", "fato_redes_sociais",
            "dim_data", "dim_forma_pagamento", "dim_campanha_marketing",
        ]
        for table in required_tables:
            exists = fetch_one(
                conn,
                f"SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='{table}';",
            )[0]
            if exists != 1:
                raise PipelineError(f"Tabela obrigatoria ausente: {table}")

        logging.info("Tabelas obrigatorias encontradas.")

        validate_raw_vs_stg(conn)
        validate_financeiro(conn)
        validate_pedidos(conn)
        validate_marketing(conn)
        validate_redes_sociais(conn)

    logging.info("Validacoes finais concluidas com sucesso.")


def validate_raw_vs_stg(conn: sqlite3.Connection) -> None:
    pairs = [
        ("financeiro", "raw_financeiro", "stg_financeiro"),
        ("pedidos", "raw_pedidos", "stg_pedidos"),
        ("marketing", "raw_marketing", "stg_marketing"),
        ("redes_sociais", "raw_redessociais", "stg_redes_sociais"),
    ]

    for name, raw_table, stg_table in pairs:
        raw_count = fetch_one(conn, f"SELECT COUNT(*) FROM {raw_table};")[0]
        stg_count = fetch_one(conn, f"SELECT COUNT(*) FROM {stg_table};")[0]
        assert_equal(f"{name} raw x stg", raw_count, stg_count)
        logging.info("[%s] raw x stg: %s linhas", name, raw_count)


def validate_financeiro(conn: sqlite3.Connection) -> None:
    stg_count, stg_total = fetch_one(
        conn,
        """
        SELECT COUNT(*), ROUND(SUM(valor_movimento), 2)
        FROM stg_financeiro
        WHERE flag_data_invalida = 0
          AND flag_tipo_invalido = 0
          AND flag_valor_invalido = 0;
        """,
    )
    fato_count, fato_total = fetch_one(
        conn,
        "SELECT COUNT(*), ROUND(SUM(valor_movimento), 2) FROM fato_financeiro;",
    )

    assert_equal("financeiro qtd stg valida x fato", stg_count, fato_count)
    assert_close("financeiro total stg valida x fato", stg_total, fato_total)

    sem_dim = fetch_one(
        conn,
        """
        SELECT COUNT(*)
        FROM fato_financeiro f
        LEFT JOIN dim_data dd ON dd.id_data = f.id_data
        LEFT JOIN dim_tipo_movimento dt ON dt.id_tipo_movimento = f.id_tipo_movimento
        LEFT JOIN dim_categoria_financeira dc ON dc.id_categoria_financeira = f.id_categoria_financeira
        LEFT JOIN dim_centro_custo dcc ON dcc.id_centro_custo = f.id_centro_custo
        LEFT JOIN dim_forma_pagamento dfp ON dfp.id_forma_pagamento = f.id_forma_pagamento
        LEFT JOIN dim_fornecedor_origem dfo ON dfo.id_fornecedor_origem = f.id_fornecedor_origem
        WHERE dd.id_data IS NULL
           OR dt.id_tipo_movimento IS NULL
           OR dc.id_categoria_financeira IS NULL
           OR dcc.id_centro_custo IS NULL
           OR dfp.id_forma_pagamento IS NULL
           OR dfo.id_fornecedor_origem IS NULL;
        """,
    )[0]
    assert_zero("financeiro dimensoes ausentes", sem_dim)
    logging.info("[financeiro] fato validada: %s linhas | total %.2f", fato_count, fato_total)


def validate_pedidos(conn: sqlite3.Connection) -> None:
    stg_count, stg_total = fetch_one(
        conn,
        "SELECT COUNT(*), ROUND(SUM(ValorLiquido), 2) FROM stg_pedidos;",
    )
    fato_count, fato_total = fetch_one(
        conn,
        "SELECT COUNT(*), ROUND(SUM(valor_liquido), 2) FROM fato_pedidos;",
    )
    assert_equal("pedidos qtd stg x fato", stg_count, fato_count)
    assert_close("pedidos total stg x fato", stg_total, fato_total)

    sem_dim_obrigatoria = fetch_one(
        conn,
        """
        SELECT COUNT(*)
        FROM fato_pedidos f
        WHERE id_data IS NULL
           OR id_cliente IS NULL
           OR id_produto IS NULL
           OR id_canal IS NULL
           OR id_plataforma IS NULL
           OR id_status_pedido IS NULL
           OR id_forma_pagamento IS NULL
           OR id_cupom IS NULL;
        """,
    )[0]
    assert_zero("pedidos dimensoes obrigatorias ausentes", sem_dim_obrigatoria)

    bairro_fora_regra = fetch_one(
        conn,
        """
        SELECT COUNT(*)
        FROM fato_pedidos f
        LEFT JOIN dim_plataforma dp ON dp.id_plataforma = f.id_plataforma
        WHERE f.id_bairro IS NULL
          AND dp.plataforma <> 'Balcao';
        """,
    )[0]
    assert_zero("pedidos bairro nulo fora da regra Balcao", bairro_fora_regra)
    logging.info("[pedidos] fato validada: %s linhas | total %.2f", fato_count, fato_total)


def validate_marketing(conn: sqlite3.Connection) -> None:
    stg_count, stg_total = fetch_one(
        conn,
        "SELECT COUNT(*), ROUND(SUM(Investimento), 2) FROM stg_marketing;",
    )
    fato_count, fato_total = fetch_one(
        conn,
        "SELECT COUNT(*), ROUND(SUM(investimento), 2) FROM fato_marketing;",
    )
    assert_equal("marketing qtd stg x fato", stg_count, fato_count)
    assert_close("marketing investimento stg x fato", stg_total, fato_total)

    sem_dim = fetch_one(
        conn,
        """
        SELECT COUNT(*)
        FROM fato_marketing f
        WHERE id_campanha_marketing IS NULL
           OR id_plataforma_marketing IS NULL
           OR id_data_inicio IS NULL
           OR id_data_fim IS NULL
           OR (flag_sem_cupom = 0 AND id_cupom IS NULL);
        """,
    )[0]
    assert_zero("marketing dimensoes ausentes", sem_dim)
    logging.info("[marketing] fato validada: %s linhas | investimento %.2f", fato_count, fato_total)


def validate_redes_sociais(conn: sqlite3.Connection) -> None:
    stg_count, stg_alcance, stg_cliques = fetch_one(
        conn,
        """
        SELECT COUNT(*), SUM(alcance), SUM(cliques)
        FROM stg_redes_sociais
        WHERE flag_post_id_invalido = 0
          AND flag_data_invalida = 0
          AND flag_metricas_invalidas = 0;
        """,
    )
    fato_count, fato_alcance, fato_cliques = fetch_one(
        conn,
        "SELECT COUNT(*), SUM(alcance), SUM(cliques) FROM fato_redes_sociais;",
    )
    assert_equal("redes sociais qtd stg valida x fato", stg_count, fato_count)
    assert_equal("redes sociais alcance stg x fato", stg_alcance, fato_alcance)
    assert_equal("redes sociais cliques stg x fato", stg_cliques, fato_cliques)

    sem_dim = fetch_one(
        conn,
        """
        SELECT COUNT(*)
        FROM fato_redes_sociais f
        WHERE id_data IS NULL
           OR id_rede_social IS NULL
           OR id_tipo_conteudo IS NULL
           OR id_tema_conteudo IS NULL
           OR (campanha_id IS NOT NULL AND id_campanha_marketing IS NULL);
        """,
    )[0]
    assert_zero("redes sociais dimensoes ausentes", sem_dim)
    logging.info("[redes_sociais] fato validada: %s linhas | alcance %s", fato_count, fato_alcance)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Orquestra o pipeline local de dados da Hamburgueria BlackBull."
    )
    parser.add_argument(
        "--skip-raw",
        action="store_true",
        help="Nao roda pipeline_dados.py; executa apenas os SQLs e validacoes.",
    )
    parser.add_argument(
        "--keep-broken-db",
        action="store_true",
        help="Nao restaura o backup automaticamente se houver erro. Use so para debug.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    log_path = setup_logging()
    backup_path: Path | None = None
    started = time.perf_counter()

    logging.info("Inicio do orquestrador BlackBull")
    logging.info("Projeto: %s", ROOT_DIR)
    logging.info("Log: %s", log_path)

    try:
        backup_path = make_backup()
        run_raw_pipeline(skip_raw=args.skip_raw)
        run_sql_steps()
        validate_database()
    except Exception as exc:
        logging.exception("Pipeline falhou: %s", exc)
        if args.keep_broken_db:
            logging.warning("Banco quebrado mantido por parametro --keep-broken-db.")
        else:
            restore_backup(backup_path)
        logging.error("PROCESSO FINALIZADO COM ERRO.")
        return 1

    logging.info("PROCESSO CONCLUIDO COM EXITO em %.2fs.", time.perf_counter() - started)
    logging.info("Backup de seguranca mantido em: %s", backup_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
