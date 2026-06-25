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
consol_financeiro = pd.DataFrame()
for arquivo in planilhas_financeiro:
    df = pd.read_excel(arquivo)
    consol_financeiro = pd.concat([consol_financeiro, df])
consol_financeiro.head()
consol_marketing = pd.DataFrame()
for arquivo in planilhas_marketing:
    df= pd.read_excel(arquivo)
    consol_marketing = pd.concat([consol_marketing,df])
consol_marketing.head()
#Criar DB com dados consolidados e tratados para consultas em SQL
consol_pedidos = pd.DataFrame()
for arquivo in planilhas_pedidos:
    df= pd.read_excel(arquivo)
    consol_pedidos = pd.concat([consol_pedidos, df])
consol_pedidos.head()
consol_redessociais = pd.DataFrame()
for arquivo in planilhas_redessociais:
    df = pd.read_excel(arquivo)
    consol_redessociais = pd.concat([consol_redessociais, df])
consol_redessociais.head()
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
caminho_db = os.path.join("src", "queries", "schema.db")
os.makedirs(os.path.dirname(caminho_db), exist_ok=True)

conn = sqlite3.connect(caminho_db)

# Salvar cada DataFrame como uma tabela
consol_financeiro.to_sql("financeiro", conn, if_exists="replace", index=False)
consol_marketing.to_sql("marketing", conn, if_exists="replace", index=False)
consol_pedidos.to_sql("pedidos", conn, if_exists="replace", index=False)
consol_redessociais.to_sql("redes_sociais", conn, if_exists="replace", index=False)

# Fechar conexão
conn.close()

print("Banco de dados criado com sucesso!")
