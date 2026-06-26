#Carregar bibliotecas
import pandas as pd
from dotenv import load_dotenv
import os
import sqlite3
load_dotenv()
financeiro = os.getenv("PASTA_FINANCEIRO")
marketing = os.getenv("PASTA_MARKETING")
pedidos = os.getenv("PASTA_PEDIDOS")
redes_sociais = os.getenv("PASTA_REDESSOCIAIS")
#Carregar dados
planilhas_financeiro = [os.path.join(financeiro, arquivo)for arquivo in os.listdir(financeiro)]
planilhas_marketing = [os.path.join(marketing, arquivo)for arquivo in os.listdir(marketing)]
planilhas_pedidos = [os.path.join(pedidos, arquivo)for arquivo in os.listdir(pedidos)]
planilhas_redessociais = [os.path.join(redes_sociais, arquivo)for arquivo in os.listdir(redes_sociais)]
#Criar planilha consolidada de dados financeiros
def consolidar_planilhas(pasta):
    if not pasta or not os.path.exists(pasta):
        raise FileNotFoundError(f"Pasta não encontrada: {pasta}")

    arquivos = [
        os.path.join(pasta, arquivo)
        for arquivo in os.listdir(pasta)
        if arquivo.endswith((".xlsx", ".xls"))
    ]

    if not arquivos:
        return pd.DataFrame()

    dataframes = [pd.read_excel(arquivo) for arquivo in arquivos]

    return pd.concat(dataframes, ignore_index=True)
consol_financeiro = consolidar_planilhas(financeiro)
consol_marketing = consolidar_planilhas(marketing)
consol_pedidos = consolidar_planilhas(pedidos)
consol_redessociais = consolidar_planilhas(redes_sociais)

#Tratamento de dados com formatos não suportados pelo SQLite
def converter_tudo(df):
    for coluna in df.columns:
        df[coluna] = df[coluna].apply(lambda x: str(x) if not isinstance(x, (int, float)) else x)
    return df

consol_financeiro   = converter_tudo(consol_financeiro)
consol_marketing    = converter_tudo(consol_marketing)
consol_pedidos      = converter_tudo(consol_pedidos)
consol_redessociais = converter_tudo(consol_redessociais)
#Converter as planilhas em um DB em SQL para tratamento de dados
# Criar/conectar ao banco
caminho_db = os.path.join("src", "queries", "blackbull.db")
os.makedirs(os.path.dirname(caminho_db), exist_ok=True)

conn = sqlite3.connect(caminho_db)

# Salvar cada DataFrame como uma tabela
def tabela_existe(conn, nome_tabela):
    consulta = """
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        AND name = ?
    """

    resultado = conn.execute(consulta, (nome_tabela,)).fetchone()

    return resultado is not None


def dados_foram_alterados(conn, nome_tabela, df_novo):
    if not tabela_existe(conn, nome_tabela):
        return True

    df_atual = pd.read_sql_query(f"SELECT * FROM {nome_tabela}", conn)

    df_novo = df_novo.reset_index(drop=True)
    df_atual = df_atual.reset_index(drop=True)

    return not df_novo.equals(df_atual)


def salvar_tabela_se_houver_mudanca(conn, nome_tabela, df):
    if dados_foram_alterados(conn, nome_tabela, df):
        df.to_sql(nome_tabela, conn, if_exists="replace", index=False)
        print(f"Tabela {nome_tabela}: atualizada com sucesso.")
        return True

    print(f"Tabela {nome_tabela}: sem alterações.")
    return False

caminho_db = os.path.join("src", "queries", "blackbull.db")
os.makedirs(os.path.dirname(caminho_db), exist_ok=True)

with sqlite3.connect(caminho_db) as conn:
    houve_atualizacao = False

    houve_atualizacao |= salvar_tabela_se_houver_mudanca(
        conn,
        "financeiro_raw",
        consol_financeiro
    )

    houve_atualizacao |= salvar_tabela_se_houver_mudanca(
        conn,
        "marketing_raw",
        consol_marketing
    )

    houve_atualizacao |= salvar_tabela_se_houver_mudanca(
        conn,
        "pedidos_raw",
        consol_pedidos
    )

    houve_atualizacao |= salvar_tabela_se_houver_mudanca(
        conn,
        "redes_sociais_raw",
        consol_redessociais
    )

if houve_atualizacao:
    print("Banco de dados atualizado com sucesso.")
else:
    print("Banco de dados continua igual à última versão.")

# Fechar conexão
conn.close()

print("Processo concluído!")
