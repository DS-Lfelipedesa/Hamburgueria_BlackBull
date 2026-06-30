# Hamburgueria BlackBull - Pipeline de Dados e Tratamento SQL

Projeto de dados desenvolvido para consolidar planilhas operacionais de uma hamburgueria, carregar os dados em um banco SQLite e preparar uma camada tratada para analises em SQL e BI.

O projeto segue uma arquitetura simples em camadas:

```text
Planilhas Excel -> raw -> stg -> analises / BI
```

## Objetivo

Criar um fluxo local de dados capaz de:

- Ler planilhas Excel de diferentes areas do negocio.
- Consolidar os arquivos por area.
- Criar tabelas brutas no SQLite.
- Atualizar as tabelas raw somente quando houver alteracao nos dados.
- Tratar os dados da camada raw para a camada stg usando SQL persistente.
- Disponibilizar uma base organizada para consultas no DBeaver e analises em Power BI.

## Tecnologias Utilizadas

- Python
- Pandas
- SQLite
- SQL
- DBeaver
- Python-dotenv
- OpenPyXL
- Excel
- Power BI

## Estrutura Atual do Projeto

```text
Hamburgueria_BlackBull/
|
|-- data/
|   |-- raw/
|       |-- Financeiro/
|       |-- Marketing/
|       |-- Pedidos/
|       |-- RedesSociais/
|
|-- db/
|   |-- blackbull.db
|
|-- src/
|   |-- pipeline_dados.py
|   |-- sql/
|       |-- 01_validacao_raw_financeiro.sql
|       |-- 02_build_stg_financeiro.sql
|       |-- 03_validacao_stg_financeiro.sql
|
|-- .env
|-- .env.example
|-- .gitattributes
|-- .gitignore
|-- Briefing_BI_Hamburgueria.docx
|-- Executar_pipeline.bat
|-- README.md
|-- requirements.txt
```

## Camadas de Dados

### Camada raw

A camada raw representa os dados brutos consolidados a partir das planilhas Excel.

As tabelas raw sao criadas pelo pipeline Python:

```text
raw_financeiro
raw_marketing
raw_pedidos
raw_redessociais
```

Essas tabelas devem manter os dados o mais proximo possivel da origem.

### Camada stg

A camada stg representa os dados tratados e padronizados para analise.

Exemplo ja implementado:

```text
stg_financeiro
```

A tabela `stg_financeiro` e criada a partir da `raw_financeiro` por scripts SQL persistentes.

## Fluxo de Execucao

O fluxo recomendado do projeto e:

```text
1. Atualizar ou adicionar planilhas em data/raw/
2. Executar o pipeline Python
3. Validar a camada raw no DBeaver
4. Executar o script de criacao da camada stg
5. Validar a camada stg no DBeaver
6. Usar a camada stg para analises e BI
```

## Configuracao do Ambiente

Crie um arquivo `.env` com base no `.env.example`.

Exemplo:

```text
PASTA_FINANCEIRO=D:\PROJETOS\Hamburgueria_BlackBull\data\raw\Financeiro
PASTA_MARKETING=D:\PROJETOS\Hamburgueria_BlackBull\data\raw\Marketing
PASTA_PEDIDOS=D:\PROJETOS\Hamburgueria_BlackBull\data\raw\Pedidos
PASTA_REDESSOCIAIS=D:\PROJETOS\Hamburgueria_BlackBull\data\raw\RedesSociais
```

## Instalacao das Dependencias

Instale as dependencias com:

```bash
pip install -r requirements.txt
```

O arquivo `requirements.txt` contem:

```text
pandas
python-dotenv
openpyxl
```

## Execucao do Pipeline Python

Pelo terminal, na raiz do projeto:

```bash
python src/pipeline_dados.py
```

Ou execute:

```text
Executar_pipeline.bat
```

O pipeline gera ou atualiza o banco:

```text
db/blackbull.db
```

## Tratamento SQL no DBeaver

Os scripts SQL ficam em:

```text
src/sql/
```

Para executar scripts com mais de uma query no DBeaver, use:

```text
Alt + X
```

Use `Ctrl + Enter` apenas quando quiser executar uma query isolada.

## Scripts da Tabela Financeiro

### 01_validacao_raw_financeiro.sql

Valida a tabela bruta `raw_financeiro` antes do tratamento.

Este script verifica:

- Quantidade de registros.
- Campos nulos ou vazios.
- Distribuicao de categorias.
- Distribuicao de centros de custo.
- Tipos financeiros.
- Formas de pagamento.
- Fornecedores ou origens.

### 02_build_stg_financeiro.sql

Cria ou recria a tabela `stg_financeiro`.

Principais tratamentos aplicados:

- Separacao de data e hora.
- Padronizacao do tipo financeiro.
- Padronizacao de categorias.
- Remocao de espacos em textos.
- Conversao de `PedidoID` para inteiro.
- Regra de negocio para `pedido_id`:
  - Receita pode ter pedido associado.
  - Despesa sempre deve ter `pedido_id` nulo.
- Criacao de `valor_movimento`:
  - Receita positiva.
  - Despesa negativa.
- Criacao de flags de auditoria.

### 03_validacao_stg_financeiro.sql

Valida a tabela tratada `stg_financeiro`.

Este script verifica:

- Total de linhas da staging.
- Datas invalidas.
- Tipos invalidos.
- Valores invalidos.
- Pedidos recuperados.
- Despesas com `pedido_id` preenchido.
- Distribuicao por categoria.
- Distribuicao por centro de custo.
- Distribuicao por forma de pagamento.

## Processo Recomendado para Atualizacao dos Dados

Sempre que as planilhas raw forem alteradas:

```text
1. Execute src/pipeline_dados.py
2. Execute 01_validacao_raw_financeiro.sql
3. Execute 02_build_stg_financeiro.sql
4. Execute 03_validacao_stg_financeiro.sql
```

Se todas as validacoes estiverem corretas, a camada `stg_financeiro` esta pronta para consumo analitico.

## Boas Praticas do Projeto

- Manter as planilhas originais em `data/raw/`.
- Manter o banco SQLite em `db/`.
- Manter scripts SQL persistentes em `src/sql/`.
- Nunca tratar dados manualmente direto no banco sem registrar a regra em SQL.
- Criar um conjunto de 3 scripts por tabela tratada:
  - validacao da raw
  - criacao da stg
  - validacao da stg
- Usar nomes padronizados:
  - `raw_nome_tabela`
  - `stg_nome_tabela`

## Sugestoes de Melhorias

- Atualizar o `.env.example` com caminhos compatíveis com `data/raw/`.
- Corrigir possiveis problemas de encoding no `pipeline_dados.py`.
- Remover codigo duplicado de criacao do caminho do banco no pipeline.
- Adicionar validacao para extensoes e arquivos temporarios do Excel.
- Criar logs de execucao do pipeline.
- Criar scripts SQL para as demais tabelas raw.
- Avaliar se `db/blackbull.db` deve ser versionado ou ignorado no Git, dependendo do objetivo do portfolio.
- Criar uma pasta `docs/` para briefing, dicionario de dados e premissas.
- Criar uma pasta `notebooks/` somente se houver analises exploratorias em Jupyter.

## Proximas Etapas

- Criar scripts `raw -> stg` para marketing.
- Criar scripts `raw -> stg` para pedidos.
- Criar scripts `raw -> stg` para redes sociais.
- Criar camada analitica com indicadores finais.
- Conectar o Power BI preferencialmente na camada stg ou em views analiticas.

## Status Atual

O projeto ja possui:

- Pipeline Python para consolidacao das planilhas.
- Banco SQLite em `db/blackbull.db`.
- Scripts SQL persistentes para tratamento da tabela financeiro.
- Camada `stg_financeiro` criada e validada.

O projeto esta pronto para evoluir o tratamento das demais tabelas.
