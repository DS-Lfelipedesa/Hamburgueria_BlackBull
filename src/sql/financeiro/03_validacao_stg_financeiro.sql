SELECT
    COUNT(*) AS total_linhas,
    SUM(flag_data_invalida) AS datas_invalidas,
    SUM(flag_tipo_invalido) AS tipos_invalidos,
    SUM(flag_valor_invalido) AS valores_invalidos,
    SUM(flag_pedido_id_recuperado) AS pedidos_recuperados
FROM stg_financeiro;
SELECT
    tipo,
    COUNT(*) AS qtd_linhas,
    COUNT(pedido_id) AS qtd_com_pedido_id,
    ROUND(SUM(valor_original), 2) AS soma_valor_original,
    ROUND(SUM(valor_movimento), 2) AS soma_valor_movimento
FROM stg_financeiro
GROUP BY tipo
ORDER BY tipo;
SELECT
    *
FROM stg_financeiro
WHERE tipo = 'Despesa'
AND pedido_id IS NOT NULL;
SELECT
    *
FROM stg_financeiro
WHERE flag_data_invalida = 1
OR flag_tipo_invalido = 1
OR flag_valor_invalido = 1;
SELECT
    categoria,
    COUNT(*) AS qtd_linhas,
    ROUND(SUM(valor_movimento), 2) AS valor_total
FROM stg_financeiro
GROUP BY categoria
ORDER BY qtd_linhas DESC;
SELECT
    centro_custo,
    COUNT(*) AS qtd_linhas,
    ROUND(SUM(valor_movimento), 2) AS valor_total
FROM stg_financeiro
GROUP BY centro_custo
ORDER BY qtd_linhas DESC;
SELECT
    forma_pagamento,
    COUNT(*) AS qtd_linhas,
    ROUND(SUM(valor_movimento), 2) AS valor_total
FROM stg_financeiro
GROUP BY forma_pagamento
ORDER BY qtd_linhas DESC;