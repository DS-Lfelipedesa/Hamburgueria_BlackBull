-- Validacao geral do modelo financeiro.
-- Esta etapa confere se a camada fato foi carregada corretamente
-- a partir da stg_financeiro e se os relacionamentos com as dimensoes estao consistentes.


-- 1. Comparacao entre stg_financeiro valida e fato_financeiro.
-- A fato carrega somente linhas validas.
-- Por isso, a stg tambem precisa ser filtrada pelas mesmas flags usadas no build da fato.

SELECT
    'stg_financeiro_valida' AS origem,
    COUNT(*) AS qtd_linhas,
    ROUND(SUM(valor_original), 2) AS total_valor_original,
    ROUND(SUM(valor_abs), 2) AS total_valor_abs,
    ROUND(SUM(valor_movimento), 2) AS total_valor_movimento
FROM stg_financeiro
WHERE flag_data_invalida = 0
AND flag_tipo_invalido = 0
AND flag_valor_invalido = 0

UNION ALL

SELECT
    'fato_financeiro' AS origem,
    COUNT(*) AS qtd_linhas,
    ROUND(SUM(valor_original), 2) AS total_valor_original,
    ROUND(SUM(valor_abs), 2) AS total_valor_abs,
    ROUND(SUM(valor_movimento), 2) AS total_valor_movimento
FROM fato_financeiro;


-- 2. Validacao de duplicidade na fato.
-- A chave_movimento deve ser unica.
-- Se esta query retornar linhas, existem movimentos duplicados na fato.

SELECT
    chave_movimento,
    COUNT(*) AS qtd_ocorrencias
FROM fato_financeiro
GROUP BY chave_movimento
HAVING COUNT(*) > 1;


-- 3. Validacao resumida de chaves dimensionais ausentes.
-- Se qualquer coluna retornar valor maior que zero,
-- significa que existem linhas na fato sem relacionamento com alguma dimensao.

SELECT
    SUM(CASE WHEN id_data IS NULL THEN 1 ELSE 0 END) AS sem_dim_data,
    SUM(CASE WHEN id_tipo_movimento IS NULL THEN 1 ELSE 0 END) AS sem_dim_tipo_movimento,
    SUM(CASE WHEN id_categoria_financeira IS NULL THEN 1 ELSE 0 END) AS sem_dim_categoria_financeira,
    SUM(CASE WHEN id_centro_custo IS NULL THEN 1 ELSE 0 END) AS sem_dim_centro_custo,
    SUM(CASE WHEN id_forma_pagamento IS NULL THEN 1 ELSE 0 END) AS sem_dim_forma_pagamento,
    SUM(CASE WHEN id_fornecedor_origem IS NULL THEN 1 ELSE 0 END) AS sem_dim_fornecedor_origem
FROM fato_financeiro;


-- 4. Diagnostico detalhado de linhas sem dimensao.
-- Esta query mostra quais movimentos ficaram com algum ID dimensional nulo.

SELECT
    id_fato_financeiro,
    data_hora,
    data_movimento,
    pedido_id,
    descricao,
    valor_movimento,
    id_data,
    id_tipo_movimento,
    id_categoria_financeira,
    id_centro_custo,
    id_forma_pagamento,
    id_fornecedor_origem
FROM fato_financeiro
WHERE id_data IS NULL
OR id_tipo_movimento IS NULL
OR id_categoria_financeira IS NULL
OR id_centro_custo IS NULL
OR id_forma_pagamento IS NULL
OR id_fornecedor_origem IS NULL;


-- 5. Validacao dos totais por tipo de movimento.
-- Esta consulta confirma se Receita e Despesa foram relacionadas corretamente.

SELECT
    dt.tipo_movimento,
    COUNT(*) AS qtd_linhas,
    ROUND(SUM(f.valor_original), 2) AS total_valor_original,
    ROUND(SUM(f.valor_abs), 2) AS total_valor_abs,
    ROUND(SUM(f.valor_movimento), 2) AS total_valor_movimento
FROM fato_financeiro f
LEFT JOIN dim_tipo_movimento dt
    ON f.id_tipo_movimento = dt.id_tipo_movimento
GROUP BY dt.tipo_movimento
ORDER BY dt.tipo_movimento;


-- 6. Validacao dos totais por categoria financeira.
-- Ajuda a conferir se a fato esta distribuindo corretamente os movimentos por categoria.

SELECT
    dc.categoria_financeira,
    COUNT(*) AS qtd_linhas,
    ROUND(SUM(f.valor_movimento), 2) AS total_valor_movimento
FROM fato_financeiro f
LEFT JOIN dim_categoria_financeira dc
    ON f.id_categoria_financeira = dc.id_categoria_financeira
GROUP BY dc.categoria_financeira
ORDER BY total_valor_movimento DESC;


-- 7. Validacao dos totais por forma de pagamento.
-- Permite conferir se as formas de pagamento foram relacionadas corretamente.

SELECT
    dfp.forma_pagamento,
    COUNT(*) AS qtd_linhas,
    ROUND(SUM(f.valor_movimento), 2) AS total_valor_movimento
FROM fato_financeiro f
LEFT JOIN dim_forma_pagamento dfp
    ON f.id_forma_pagamento = dfp.id_forma_pagamento
GROUP BY dfp.forma_pagamento
ORDER BY total_valor_movimento DESC;


-- 8. Validacao dos totais por data.
-- Confere se os movimentos estao relacionados corretamente com a dim_data.

SELECT
    dd.data,
    dd.ano,
    dd.mes_numero,
    dd.mes_nome,
    COUNT(*) AS qtd_linhas,
    ROUND(SUM(f.valor_movimento), 2) AS total_valor_movimento
FROM fato_financeiro f
LEFT JOIN dim_data dd
    ON f.id_data = dd.id_data
GROUP BY
    dd.data,
    dd.ano,
    dd.mes_numero,
    dd.mes_nome
ORDER BY dd.data;


-- 9. Validacao das dimensoes criadas.
-- Mostra a quantidade de registros em cada dimensao financeira.

SELECT
    'dim_data' AS dimensao,
    COUNT(*) AS qtd_registros
FROM dim_data

UNION ALL

SELECT
    'dim_tipo_movimento' AS dimensao,
    COUNT(*) AS qtd_registros
FROM dim_tipo_movimento

UNION ALL

SELECT
    'dim_categoria_financeira' AS dimensao,
    COUNT(*) AS qtd_registros
FROM dim_categoria_financeira

UNION ALL

SELECT
    'dim_centro_custo' AS dimensao,
    COUNT(*) AS qtd_registros
FROM dim_centro_custo

UNION ALL

SELECT
    'dim_forma_pagamento' AS dimensao,
    COUNT(*) AS qtd_registros
FROM dim_forma_pagamento

UNION ALL

SELECT
    'dim_fornecedor_origem' AS dimensao,
    COUNT(*) AS qtd_registros
FROM dim_fornecedor_origem;