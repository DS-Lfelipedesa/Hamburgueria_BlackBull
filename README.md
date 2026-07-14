# Hamburgueria BlackBull - Pipeline de Dados

Projeto local de engenharia de dados para consolidar planilhas Excel da Hamburgueria BlackBull, carregar uma base SQLite e montar tabelas analíticas para uso em SQL, DBeaver e Power BI.

Status validado em 12/07/2026: pipeline completo executando com sucesso pelo Python e pelo `Executar_pipeline.bat`.

## Visão Geral

O fluxo atual segue estas camadas:

```text
Planilhas Excel -> raw -> staging -> dimensões/fatos -> Power BI
```

Áreas tratadas:

- Financeiro
- Pedidos
- Marketing
- Redes sociais

O banco final fica em:

```text
db/blackbull.db
```

## Estrutura

```text
Hamburgueria_BlackBull/
|-- data/
|   |-- raw/
|       |-- Financeiro/
|       |-- Marketing/
|       |-- Pedidos/
|       |-- RedesSociais/
|-- db/
|   |-- blackbull.db
|   |-- backups/
|-- docs/
|-- logs/
|-- src/
|   |-- pipeline_dados.py
|   |-- orquestrador.py
|   |-- sql/
|       |-- financeiro/
|       |-- pedidos/
|       |-- marketing/
|       |-- redes_sociais/
|-- .env.example
|-- Executar_pipeline.bat
|-- README.md
|-- requirements.txt
```

## Componentes

`src/pipeline_dados.py`

Lê as planilhas Excel configuradas no `.env`, consolida os arquivos por área e grava as tabelas raw no SQLite. A tabela raw só é recriada quando os dados mudam.

`src/orquestrador.py`

Controla a execução completa:

1. Cria backup do banco atual.
2. Executa a carga raw.
3. Executa os SQLs de staging.
4. Recria dimensões.
5. Recria ou atualiza fatos.
6. Executa validações SQL.
7. Executa validações finais em Python.
8. Restaura o backup se houver erro, salvo quando usado `--keep-broken-db`.

`Executar_pipeline.bat`

Atalho para executar o orquestrador no Windows. Em caso de erro, mostra as linhas principais do log mais recente.

## Configuração

Crie o arquivo `.env` a partir de `.env.example`:

```text
PASTA_FINANCEIRO=data\raw\Financeiro
PASTA_MARKETING=data\raw\Marketing
PASTA_PEDIDOS=data\raw\Pedidos
PASTA_REDESSOCIAIS=data\raw\RedesSociais
```

Também é possível usar caminhos absolutos no `.env` quando as planilhas estiverem fora da pasta do projeto, mas evite publicar esses caminhos.

Instale as dependências:

```bash
pip install -r requirements.txt
```

## Execução

Modo recomendado:

```text
Executar_pipeline.bat
```

Pelo terminal:

```bash
python src/orquestrador.py
```

Opções úteis:

```bash
python src/orquestrador.py --skip-raw
python src/orquestrador.py --keep-broken-db
```

Use `--skip-raw` quando quiser reaplicar apenas SQLs e validações sobre o banco atual. Use `--keep-broken-db` somente para debug, porque ele impede o restore automático do backup.

## Saída Analítica

Fatos principais:

- `fato_financeiro`
- `fato_pedidos`
- `fato_marketing`
- `fato_redes_sociais`

Dimensões principais:

- `dim_data`
- `dim_forma_pagamento`
- `dim_cupom`
- `dim_cliente`
- `dim_produto`
- `dim_canal`
- `dim_plataforma`
- `dim_bairro`
- `dim_status_pedido`
- `dim_tipo_movimento`
- `dim_categoria_financeira`
- `dim_centro_custo`
- `dim_fornecedor_origem`
- `dim_campanha_marketing`
- `dim_plataforma_marketing`
- `dim_rede_social`
- `dim_tipo_conteudo`
- `dim_tema_conteudo`

Resultado da última validação:

- Financeiro: 63.360 linhas na fato.
- Pedidos: 108.118 linhas na fato.
- Marketing: 346 linhas na fato.
- Redes sociais: 2.527 linhas na fato.
- `PRAGMA integrity_check`: ok.
- Chaves dimensionais obrigatórias: sem nulos.
- Flags críticas consultadas: sem ocorrências.

## Power BI

A base está pronta para uma demonstração em Power BI usando as tabelas fato e dimensão. O modelo recomendado é estrela, com as fatos no centro e relacionamentos muitos-para-um para as dimensões.

Cuidados antes da demonstração:

- Ocultar tabelas `raw_*` e `stg_*` no Power BI.
- Usar `dim_data` como calendário principal.
- Revisar exposição de identificadores de cliente, pedido e campanha antes de apresentar para público externo.
- Criar medidas DAX no Power BI em vez de alterar fatos para cálculos de apresentação.

## Logs e Backups

Logs de execução:

```text
logs/orquestrador_YYYYMMDD_HHMMSS.log
```

Backups automáticos:

```text
db/backups/
```

O backup é criado antes de cada execução completa. Se o processo falhar, o orquestrador tenta restaurar o banco anterior.

## Pontos de Atenção

- O banco SQLite é local e não tem controle de acesso próprio.
- O `.env`, dados raw, banco, logs e backups devem continuar fora do Git.
- A pasta `db/backups/` pode crescer rápido porque cada execução cria um novo backup.
- A carga raw ainda compara DataFrames inteiros para decidir atualização; funciona para o volume atual, mas não é carga incremental real.
- A integridade relacional é validada por consultas, não por constraints formais de chave estrangeira no SQLite.

## Relatório

O relatório analítico do projeto está em:

```text
docs/RELATORIO_ANALITICO_PROJETO.md
```
