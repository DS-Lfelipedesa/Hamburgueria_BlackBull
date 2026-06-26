# Hamburgueria BlackBull - Pipeline de Dados

Projeto de dados desenvolvido para consolidar planilhas operacionais de uma hamburgueria ficticia e transformar essas informacoes em uma base estruturada para consultas SQL e analises em BI.

O projeto simula um cenario real de negocio, no qual diferentes areas da empresa geram arquivos Excel separados, dificultando a analise integrada dos dados.

## Objetivo

Criar um pipeline em Python capaz de:

- Ler multiplas planilhas Excel de diferentes areas da empresa;
- Consolidar os arquivos por categoria de dados;
- Criar tabelas em um banco SQLite;
- Atualizar o banco somente quando houver alteracoes nos dados de origem;
- Disponibilizar uma base organizada para tratamento em SQL e posterior analise em Power BI.

## Contexto do Projeto

A empresa possui dados distribuidos em planilhas de diferentes areas:

- Financeiro
- Marketing
- Pedidos
- Redes Sociais

Ao todo, o projeto considera 208 arquivos `.xlsx`, que sao consolidados automaticamente pelo pipeline.

Os dados e o nome da empresa foram alterados para preservar informacoes sensiveis.

## Tecnologias Utilizadas

- Python
- Pandas
- SQLite
- SQL
- Python-dotenv
- Excel
- Power BI

## Estrutura do Projeto

```text
Hamburgueria_BlackBull/
|
|-- Financeiro/
|-- Marketing/
|-- Pedidos/
|-- RedesSociais/
|
|-- src/
|   |-- pipeline_dados.py
|   |-- queries/
|       |-- blackbull.db
|
|-- .env.example
|-- .gitignore
|-- .gitattributes
|-- Executar_pipeline.bat
|-- README.md
|-- Briefing_BI_Hamburgueria.docx
```

## Funcionamento do Pipeline

O pipeline segue as etapas abaixo:

```text
Planilhas Excel
      ->
Leitura dos arquivos por area
      ->
Consolidacao dos dados com Pandas
      ->
Tratamento basico de compatibilidade com SQLite
      ->
Comparacao com a versao atual do banco
      ->
Atualizacao das tabelas somente se houver mudancas
      ->
Banco SQLite disponivel para consultas e analises
```

## Tabelas Geradas

O banco SQLite gerado contem tabelas separadas por area:

```text
financeiro_raw
marketing_raw
pedidos_raw
redes_sociais_raw
```

As tabelas com sufixo `_raw` representam a camada bruta consolidada dos dados, antes dos tratamentos analiticos.

## Como Executar o Projeto

### 1. Clone o repositorio

```bash
git clone <url-do-repositorio>
```

### 2. Acesse a pasta do projeto

```bash
cd Hamburgueria_BlackBull
```

### 3. Crie o arquivo `.env`

Use o arquivo `.env.example` como referencia:

```text
PASTA_FINANCEIRO=
PASTA_MARKETING=
PASTA_PEDIDOS=
PASTA_REDESSOCIAIS=
```

Preencha cada variavel com o caminho correspondente das pastas de dados.

Exemplo:

```text
PASTA_FINANCEIRO=D:\PROJETOS\Hamburgueria_BlackBull\Financeiro
PASTA_MARKETING=D:\PROJETOS\Hamburgueria_BlackBull\Marketing
PASTA_PEDIDOS=D:\PROJETOS\Hamburgueria_BlackBull\Pedidos
PASTA_REDESSOCIAIS=D:\PROJETOS\Hamburgueria_BlackBull\RedesSociais
```

### 4. Instale as dependencias

```bash
pip install pandas python-dotenv openpyxl
```

### 5. Execute o pipeline

Pelo terminal:

```bash
python src/pipeline_dados.py
```

Ou execute o arquivo:

```text
Executar_pipeline.bat
```

## Saida do Processo

Ao final da execucao, o pipeline informa se o banco foi atualizado ou se continua igual a ultima versao.

Exemplos de mensagens:

```text
Banco de dados atualizado com sucesso.
```

ou

```text
Banco de dados continua igual a ultima versao.
```

O banco gerado fica disponivel em:

```text
src/queries/blackbull.db
```

## Possiveis Analises

Com os dados consolidados, e possivel construir analises como:

- Faturamento por periodo;
- Ticket medio;
- Volume de pedidos;
- Desempenho de campanhas de marketing;
- Engajamento em redes sociais;
- Relacao entre acoes de marketing e vendas;
- Evolucao dos principais indicadores operacionais.

## Proximas Etapas

Melhorias previstas para evolucao do projeto:

- Criar scripts SQL para tratamento das tabelas brutas;
- Separar camada `raw` e camada tratada;
- Criar consultas analiticas para indicadores de negocio;
- Desenvolver dashboard em Power BI;
- Adicionar logs de execucao;
- Criar arquivo `requirements.txt`;
- Melhorar validacoes de entrada e tratamento de erros.

## Sobre o Projeto

Este projeto foi desenvolvido como parte de um portfolio de dados, com foco em demonstrar habilidades de:

- Automacao de processos com Python;
- Manipulacao de dados com Pandas;
- Modelagem inicial de base analitica;
- Criacao de pipeline local de dados;
- Organizacao de projeto para analise de dados;
- Preparacao de dados para SQL e BI.
