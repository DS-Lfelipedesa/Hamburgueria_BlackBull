DROP TABLE IF EXISTS stg_financeiro;

CREATE TABLE stg_financeiro AS
SELECT
    datetime(TRIM(Data)) AS data_hora,
    date(TRIM(Data)) AS data_movimento,
    time(TRIM(Data)) AS hora_movimento,
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
        WHEN LOWER(TRIM(Tipo)) = 'receita' AND PedidoID IS NULL AND LOWER(TRIM(Descricao)) LIKE 'recebimento pedido %' THEN CAST(REPLACE(LOWER(TRIM(Descricao)), 'recebimento pedido ', '') AS INTEGER)
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
        WHEN Data IS NULL OR TRIM(Data) = '' THEN 1
        WHEN datetime(TRIM(Data)) IS NULL THEN 1
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
        WHEN LOWER(TRIM(Tipo)) = 'receita' AND PedidoID IS NULL AND LOWER(TRIM(Descricao)) LIKE 'recebimento pedido %' THEN 1
        ELSE 0
    END AS flag_pedido_id_recuperado
FROM raw_financeiro;

