-- 01_validacao_raw_financeiro.sql
-- Objetivo: diagnosticar qualidade e padronizacao da raw_financeiro
-- Execute antes de recriar a stg_financeiro.

SELECT
    COUNT(*) AS total_linhas,
    SUM(CASE WHEN Data IS NULL OR TRIM(Data) = '' THEN 1 ELSE 0 END) AS data_vazia,
    SUM(CASE WHEN Tipo IS NULL OR TRIM(Tipo) = '' THEN 1 ELSE 0 END) AS tipo_vazio,
    SUM(CASE WHEN Categoria IS NULL OR TRIM(Categoria) = '' THEN 1 ELSE 0 END) AS categoria_vazia,
    SUM(CASE WHEN CentroCusto IS NULL OR TRIM(CentroCusto) = '' THEN 1 ELSE 0 END) AS centro_custo_vazio,
    SUM(CASE WHEN Descricao IS NULL OR TRIM(Descricao) = '' THEN 1 ELSE 0 END) AS descricao_vazia,
    SUM(CASE WHEN PedidoID IS NULL THEN 1 ELSE 0 END) AS pedido_id_vazio,
    SUM(CASE WHEN FormaPagamento IS NULL OR TRIM(FormaPagamento) = '' THEN 1 ELSE 0 END) AS forma_pagamento_vazia,
    SUM(CASE WHEN Valor IS NULL THEN 1 ELSE 0 END) AS valor_vazio,
    SUM(CASE WHEN FornecedorOrigem IS NULL OR TRIM(FornecedorOrigem) = '' THEN 1 ELSE 0 END) AS fornecedor_origem_vazio,
    SUM(CASE WHEN Observacao IS NULL OR TRIM(Observacao) = '' THEN 1 ELSE 0 END) AS observacao_vazia
FROM raw_financeiro;


SELECT
    Categoria,
    COUNT(*) AS qtd
FROM raw_financeiro
GROUP BY Categoria
ORDER BY qtd DESC;


SELECT
    CentroCusto,
    COUNT(*) AS qtd
FROM raw_financeiro
GROUP BY CentroCusto
ORDER BY qtd DESC;


SELECT
    Tipo,
    COUNT(*) AS qtd,
    MIN(Valor) AS menor_valor,
    MAX(Valor) AS maior_valor
FROM raw_financeiro
GROUP BY Tipo
ORDER BY qtd DESC;


SELECT
    FormaPagamento,
    COUNT(*) AS qtd
FROM raw_financeiro
GROUP BY FormaPagamento
ORDER BY qtd DESC;


SELECT
    FornecedorOrigem,
    COUNT(*) AS qtd
FROM raw_financeiro
GROUP BY FornecedorOrigem
ORDER BY qtd DESC;