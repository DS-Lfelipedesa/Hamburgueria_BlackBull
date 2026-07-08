-- =========================================================
-- QUERY 02: build_stg_financeiro
-- ORIGEM: raw_financeiro
-- DESTINO: stg_financeiro
--
-- Grao:
-- 1 linha = 1 movimento financeiro vindo da raw.
--
-- NOTE(ai-pass): esta versao corrige datas brasileiras DD/MM/YYYY HH:MM.
-- Antes o SQLite transformava essas datas em NULL e a fato perdia linhas.
-- =========================================================

DROP TABLE IF EXISTS stg_financeiro;

CREATE TABLE stg_financeiro AS
WITH base AS (
    SELECT
        rowid AS id_raw_financeiro,
        TRIM(Data) AS data_original,
        Tipo,
        Categoria,
        CentroCusto,
        Descricao,
        PedidoID,
        FormaPagamento,
        Valor,
        FornecedorOrigem,
        Observacao
    FROM raw_financeiro
),

datas_tratadas AS (
    SELECT
        *,
        CASE
            WHEN data_original LIKE '____-__-__%' THEN datetime(data_original)
            WHEN data_original LIKE '__/__/____%' THEN datetime(
                SUBSTR(data_original, 7, 4) || '-' ||
                SUBSTR(data_original, 4, 2) || '-' ||
                SUBSTR(data_original, 1, 2) ||
                SUBSTR(data_original, 11)
            )
            ELSE NULL
        END AS data_hora_tratada
    FROM base
)

SELECT
    id_raw_financeiro,
    data_original,
    data_hora_tratada AS data_hora,
    date(data_hora_tratada) AS data_movimento,
    time(data_hora_tratada) AS hora_movimento,

    CASE
        WHEN LOWER(TRIM(Tipo)) = 'receita' THEN 'Receita'
        WHEN LOWER(TRIM(Tipo)) = 'despesa' THEN 'Despesa'
        ELSE TRIM(Tipo)
    END AS tipo,

    CASE
        WHEN LOWER(TRIM(Categoria)) = 'insumos' THEN 'Insumos'
        WHEN LOWER(TRIM(Categoria)) = 'administrativo' THEN 'Administrativo'
        WHEN LOWER(TRIM(Categoria)) = 'água' THEN 'Água'
        WHEN LOWER(TRIM(Categoria)) = 'taxas' THEN 'Taxas'
        WHEN LOWER(TRIM(Categoria)) = 'marketing' THEN 'Marketing'
        WHEN LOWER(TRIM(Categoria)) = 'gás' THEN 'Gás'
        WHEN LOWER(TRIM(Categoria)) = 'folha' THEN 'Folha'
        ELSE TRIM(Categoria)
    END AS categoria,

    TRIM(CentroCusto) AS centro_custo,
    TRIM(Descricao) AS descricao,

    CASE
        WHEN LOWER(TRIM(Tipo)) = 'despesa' THEN NULL
        WHEN LOWER(TRIM(Tipo)) = 'receita' AND PedidoID IS NOT NULL THEN CAST(PedidoID AS INTEGER)
        WHEN LOWER(TRIM(Tipo)) = 'receita'
             AND PedidoID IS NULL
             AND LOWER(TRIM(Descricao)) LIKE 'recebimento pedido %'
            THEN CAST(REPLACE(LOWER(TRIM(Descricao)), 'recebimento pedido ', '') AS INTEGER)
        ELSE NULL
    END AS pedido_id,

    TRIM(FormaPagamento) AS forma_pagamento,
    TRIM(FornecedorOrigem) AS fornecedor_origem,
    NULLIF(TRIM(Observacao), '') AS observacao,

    Valor AS valor_original,
    ABS(Valor) AS valor_abs,

    CASE
        WHEN LOWER(TRIM(Tipo)) = 'receita' THEN ABS(Valor)
        WHEN LOWER(TRIM(Tipo)) = 'despesa' THEN -ABS(Valor)
        ELSE Valor
    END AS valor_movimento,

    CASE
        WHEN data_original IS NULL OR TRIM(data_original) = '' THEN 1
        WHEN data_hora_tratada IS NULL THEN 1
        ELSE 0
    END AS flag_data_invalida,

    CASE
        WHEN LOWER(TRIM(Tipo)) NOT IN ('receita', 'despesa') THEN 1
        ELSE 0
    END AS flag_tipo_invalido,

    CASE
        WHEN Valor IS NULL THEN 1
        ELSE 0
    END AS flag_valor_invalido,

    CASE
        WHEN LOWER(TRIM(Tipo)) = 'receita'
             AND PedidoID IS NULL
             AND LOWER(TRIM(Descricao)) LIKE 'recebimento pedido %' THEN 1
        ELSE 0
    END AS flag_pedido_id_recuperado

FROM datas_tratadas;

