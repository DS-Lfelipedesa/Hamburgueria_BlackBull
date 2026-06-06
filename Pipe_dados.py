#!/usr/bin/env python
# coding: utf-8

# In[1]:


get_ipython().system('pip install python-dotenv')


# In[2]:


#Carregar bibliotecas


# In[3]:


import pandas as pd
from dotenv import load_dotenv
import os


# In[4]:


#Carregar arquivos financeiros


# In[5]:


load_dotenv()
financeiro = os.getenv("PASTA_FINANCEIRO")
marketing = os.getenv("PASTA_MARKETING")
pedidos = os.getenv("PASTA_PEDIDOS")
redes_sociais = os.getenv("PASTA_REDESSOCIAIS")


# In[6]:


#Carregar dados


# In[7]:


planilhas_financeiro = [os.path.join(financeiro, arquivo)for arquivo in os.listdir(financeiro)]
planilhas_marketing = [os.path.join(marketing, arquivo)for arquivo in os.listdir(marketing)]
planilhas_pedidos = [os.path.join(pedidos, arquivo)for arquivo in os.listdir(pedidos)]
planilhas_redessociais = [os.path.join(redes_sociais, arquivo)for arquivo in os.listdir(redes_sociais)]


# In[8]:


#Criar planilha consolidada de dados financeiros


# In[9]:


consol_financeiro = pd.DataFrame()


# In[10]:


for arquivo in planilhas_financeiro:
    df = pd.read_excel(arquivo)
    consol_financeiro = pd.concat([consol_financeiro, df])
#consol_financeiro.head()


# In[11]:


consol_marketing = pd.DataFrame()


# In[12]:


for arquivo in planilhas_marketing:
    df= pd.read_excel(arquivo)
    consol_marketing = pd.concat([consol_marketing,df])
#consol_marketing.head()


# In[13]:


#Criar DB com dados consolidados e tratados para consultas em SQL


# In[14]:


consol_pedidos = pd.DataFrame()


# In[15]:


for arquivo in planilhas_pedidos:
    df= pd.read_excel(arquivo)
    consol_pedidos = pd.concat([consol_pedidos, df])
#consol_pedidos.head()


# In[16]:


consol_redessociais = pd.DataFrame()


# In[17]:


for arquivo in planilhas_redessociais:
    df = pd.read_excel(arquivo)
    consol_redessociais = pd.concat([consol_redessociais, df])
#consol_redessociais.head()


# In[18]:


#Converter as planilhas em um DB em SQL para tratamento de dados


# In[19]:


import sqlite3


# In[20]:


# Criar/conectar ao banco
conn = sqlite3.connect("BlackBull.db")

# Salvar cada DataFrame como uma tabela
consol_financeiro.to_sql("financeiro", conn, if_exists="replace", index=False)
consol_marketing.to_sql("marketing", conn, if_exists="replace", index=False)
consol_pedidos.to_sql("pedidos", conn, if_exists="replace", index=False)
consol_redessociais.to_sql("redes_sociais", conn, if_exists="replace", index=False)

# Fechar conexão
conn.close()

print("Banco de dados criado com sucesso!")


# In[ ]:


jupyter nbconvert --to script Pipe_dados.ipynb
print("Arquivo criado com sucesso!")


# In[ ]:




