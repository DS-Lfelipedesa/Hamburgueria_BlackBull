from __future__ import annotations

import os
import sqlite3
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv


ROOT_DIR = Path(__file__).resolve().parents[1]
DB_PATH = ROOT_DIR / "db" / "blackbull.db"

RAW_TABLES = {
    "raw_financeiro": "PASTA_FINANCEIRO",
    "raw_marketing": "PASTA_MARKETING",
    "raw_pedidos": "PASTA_PEDIDOS",
    "raw_redessociais": "PASTA_REDESSOCIAIS",
}


def carregar_configuracao() -> dict[str, Path]:
    load_dotenv(ROOT_DIR / ".env")

    pastas: dict[str, Path] = {}
    for nome_tabela, variavel in RAW_TABLES.items():
        valor = os.getenv(variavel)
        if not valor:
            raise RuntimeError(f"Variavel {variavel} nao definida no .env")

        pasta = Path(valor)
        if not pasta.is_absolute():
            pasta = ROOT_DIR / pasta

        if not pasta.exists():
            raise FileNotFoundError(f"Pasta nao encontrada para {nome_tabela}: {pasta}")

        pastas[nome_tabela] = pasta

    return pastas


def listar_planilhas(pasta: Path) -> list[Path]:
    arquivos = [
        arquivo
        for arquivo in sorted(pasta.iterdir())
        if arquivo.suffix.lower() in {".xlsx", ".xls"}
        and not arquivo.name.startswith("~$")
    ]
    return arquivos


def consolidar_planilhas(pasta: Path) -> pd.DataFrame:
    arquivos = listar_planilhas(pasta)
    if not arquivos:
        print(f"Nenhuma planilha encontrada em {pasta}")
        return pd.DataFrame()

    partes = []
    for arquivo in arquivos:
        partes.append(pd.read_excel(arquivo))

    print(f"{pasta.name}: {len(arquivos)} arquivo(s) lido(s).")
    return pd.concat(partes, ignore_index=True)


def ajustar_tipos_para_sqlite(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return df

    ajustado = df.copy()
    for coluna in ajustado.columns:
        # Mantem numeros como numero; o resto vira texto para evitar erro no SQLite.
        ajustado[coluna] = ajustado[coluna].apply(
            lambda valor: valor if isinstance(valor, (int, float)) or pd.isna(valor) else str(valor)
        )
    return ajustado


def tabela_existe(conn: sqlite3.Connection, nome_tabela: str) -> bool:
    consulta = """
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
          AND name = ?
    """
    return conn.execute(consulta, (nome_tabela,)).fetchone() is not None


def dados_foram_alterados(conn: sqlite3.Connection, nome_tabela: str, df_novo: pd.DataFrame) -> bool:
    if not tabela_existe(conn, nome_tabela):
        return True

    df_atual = pd.read_sql_query(f'SELECT * FROM "{nome_tabela}"', conn)
    df_novo = df_novo.reset_index(drop=True)
    df_atual = df_atual.reset_index(drop=True)

    return not df_novo.equals(df_atual)


def salvar_tabela_se_houver_mudanca(
    conn: sqlite3.Connection,
    nome_tabela: str,
    df: pd.DataFrame,
) -> bool:
    if dados_foram_alterados(conn, nome_tabela, df):
        df.to_sql(nome_tabela, conn, if_exists="replace", index=False)
        print(f"Tabela {nome_tabela}: atualizada com sucesso.")
        return True

    print(f"Tabela {nome_tabela}: sem alteracoes.")
    return False


def main() -> int:
    pastas = carregar_configuracao()
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)

    houve_atualizacao = False
    with sqlite3.connect(DB_PATH) as conn:
        for nome_tabela, pasta in pastas.items():
            df = consolidar_planilhas(pasta)
            df = ajustar_tipos_para_sqlite(df)
            houve_atualizacao |= salvar_tabela_se_houver_mudanca(conn, nome_tabela, df)

    if houve_atualizacao:
        print("Banco de dados atualizado com sucesso.")
    else:
        print("Banco de dados continua igual a ultima versao.")

    print("Processo concluido.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
