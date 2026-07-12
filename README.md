# Hamburgueria BlackBull - Pipeline de Dados

Projeto local de engenharia de dados para consolidar planilhas Excel da Hamburgueria BlackBull, carregar uma base SQLite e montar tabelas analiticas para uso em SQL, DBeaver e Power BI.

Status validado em 12/07/2026: pipeline completo executando com sucesso pelo Python e pelo `Executar_pipeline.bat`.

## Visao Geral

O fluxo atual segue estas camadas:

```text
Planilhas Excel -> raw -> staging -> dimensoes/fatos -> Power BI
```

Areas tratadas:

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

Le as planilhas Excel configuradas no `.env`, consolida os arquivos por area e grava as tabelas raw no SQLite. A tabela raw so e recriada quando os dados mudam.

`src/orquestrador.py`

Controla a execucao completa:

1. Cria backup do banco atual.
2. Executa a carga raw.
3. Executa os SQLs de staging.
4. Recria dimensoes.
5. Recria ou atualiza fatos.
6. Executa validacoes SQL.
7. Executa validacoes finais em Python.
8. Restaura o backup se houver erro, salvo quando usado `--keep-broken-db`.

`Executar_pipeline.bat`

Atalho para executar o orquestrador no Windows. Em caso de erro, mostra as linhas principais do log mais recente.

## Configuracao

Crie o arquivo `.env` a partir de `.env.example`:

```text
PASTA_FINANCEIRO=data\raw\Financeiro
PASTA_MARKETING=data\raw\Marketing
PASTA_PEDIDOS=data\raw\Pedidos
PASTA_REDESSOCIAIS=data\raw\RedesSociais
```

Tambem e possivel usar caminhos absolutos no `.env` quando as planilhas estiverem fora da pasta do projeto, mas evite publicar esses caminhos.

Instale as dependencias:

```bash
pip install -r requirements.txt
```

## Execucao

Modo recomendado:

```text
Executar_pipeline.bat
```

Pelo terminal:

```bash
python src/orquestrador.py
```

Opcoes uteis:

```bash
python src/orquestrador.py --skip-raw
python src/orquestrador.py --keep-broken-db
```

Use `--skip-raw` quando quiser reaplicar apenas SQLs e validacoes sobre o banco atual. Use `--keep-broken-db` somente para debug, porque ele impede o restore automatico do backup.

## Saida Analitica

Fatos principais:

- `fato_financeiro`
- `fato_pedidos`
- `fato_marketing`
- `fato_redes_sociais`

Dimensoes principais:

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

Resultado da ultima validacao:

- Financeiro: 63.360 linhas na fato.
- Pedidos: 108.118 linhas na fato.
- Marketing: 346 linhas na fato.
- Redes sociais: 2.527 linhas na fato.
- `PRAGMA integrity_check`: ok.
- Chaves dimensionais obrigatorias: sem nulos.
- Flags criticas consultadas: sem ocorrencias.

## Power BI

A base esta pronta para uma demonstracao em Power BI usando as tabelas fato e dimensao. O modelo recomendado e estrela, com as fatos no centro e relacionamentos muitos-para-um para as dimensoes.

Cuidados antes da demonstracao:

- Ocultar tabelas `raw_*` e `stg_*` no Power BI.
- Usar `dim_data` como calendario principal.
- Revisar exposicao de identificadores de cliente, pedido e campanha antes de apresentar para publico externo.
- Criar medidas DAX no Power BI em vez de alterar fatos para calculos de apresentacao.

## Logs e Backups

Logs de execucao:

```text
logs/orquestrador_YYYYMMDD_HHMMSS.log
```

Backups automaticos:

```text
db/backups/
```

O backup e criado antes de cada execucao completa. Se o processo falhar, o orquestrador tenta restaurar o banco anterior.

## Pontos de Atencao

- O banco SQLite e local e nao tem controle de acesso proprio.
- O `.env`, dados raw, banco, logs e backups devem continuar fora do Git.
- A pasta `db/backups/` pode crescer rapido porque cada execucao cria um novo backup.
- A carga raw ainda compara DataFrames inteiros para decidir atualizacao; funciona para o volume atual, mas nao e carga incremental real.
- A integridade relacional e validada por consultas, nao por constraints formais de chave estrangeira no SQLite.

## Relatorio

O relatorio analitico do projeto esta em:

```text
docs/RELATORIO_ANALITICO_PROJETO.md
```
