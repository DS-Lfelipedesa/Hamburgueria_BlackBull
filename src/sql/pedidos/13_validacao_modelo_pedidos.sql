-- =========================================================
-- QUERY 13: validacao_modelo_pedidos
-- ORIGEM:
-- stg_pedidos
-- fato_pedidos
-- dimensoes de pedidos
--
-- OBJETIVO:
-- Validar se o modelo final de pedidos esta consistente
-- para consumo no Power BI.
--
-- ESTA QUERY NAO ALTERA DADOS.
--
-- VALIDACOES:
-- 1. Comparar volume da stg com a fato
-- 2. Verificar duplicidade na fato
-- 3. Verificar chaves dimensionais nulas indevidas
-- 4. Verificar registros sem relacionamento com dimensoes
-- 5. Comparar totais financeiros entre stg e fato
-- 6. Exibir amostra final do modelo
-- =========================================================


-- =========================================================
-- 1. COMPARACAO DE VOLUME STG X FATO
--
-- Logica:
-- Como a fato tem grao de item de pedido, ela deve ter
-- o mesmo numero de registros da stg_pedidos.
-- =========================================================

SELECT
    'stg_pedidos' AS tabela,
    COUNT(*) AS total_linhas
FROM stg_pedidos

UNION ALL

SELECT
    'fato_pedidos' AS tabela,
    COUNT(*) AS total_linhas
FROM fato_pedidos;


-- =========================================================
-- 2. VALIDAR DUPLICIDADE NA FATO
--
-- Logica:
-- A chave_pedido_item deve ser unica.
-- Se retornar linhas, existe duplicidade na fato.
-- =========================================================

SELECT
    chave_pedido_item,
    COUNT(*) AS qtd_ocorrencias
FROM fato_pedidos
GROUP BY chave_pedido_item
HAVING COUNT(*) > 1
ORDER BY qtd_ocorrencias DESC;


-- =========================================================
-- 3. VALIDAR CHAVES DIMENSIONAIS NULAS
--
-- Logica:
-- Em geral, as chaves das dimensoes devem estar preenchidas.
--
-- Excecao:
-- id_bairro pode ser NULL quando o pedido nao possui bairro,
-- especialmente nos casos de plataforma Balcao.
-- =========================================================

SELECT
    SUM(CASE WHEN id_data IS NULL THEN 1 ELSE 0 END) AS id_data_nulo,
    SUM(CASE WHEN id_cliente IS NULL THEN 1 ELSE 0 END) AS id_cliente_nulo,
    SUM(CASE WHEN id_produto IS NULL THEN 1 ELSE 0 END) AS id_produto_nulo,
    SUM(CASE WHEN id_canal IS NULL THEN 1 ELSE 0 END) AS id_canal_nulo,
    SUM(CASE WHEN id_plataforma IS NULL THEN 1 ELSE 0 END) AS id_plataforma_nulo,
    SUM(CASE WHEN id_status_pedido IS NULL THEN 1 ELSE 0 END) AS id_status_pedido_nulo,
    SUM(CASE WHEN id_forma_pagamento IS NULL THEN 1 ELSE 0 END) AS id_forma_pagamento_nulo,
    SUM(CASE WHEN id_cupom IS NULL THEN 1 ELSE 0 END) AS id_cupom_nulo,
    SUM(CASE WHEN id_bairro IS NULL THEN 1 ELSE 0 END) AS id_bairro_nulo_total
FROM fato_pedidos;


-- =========================================================
-- 4. VALIDAR ID_BAIRRO NULO SOMENTE QUANDO A PLATAFORMA FOR BALCAO
--
-- Logica:
-- id_bairro NULL e esperado para Balcao.
-- Para outras plataformas, precisamos investigar.
--
-- Se retornar linhas, existem pedidos sem bairro fora da regra.
-- =========================================================

SELECT
    fp.chave_pedido_item,
    fp.pedido_id,
    fp.item_id,
    dp.plataforma,
    fp.id_bairro,
    fp.data_pedido
FROM fato_pedidos fp
LEFT JOIN dim_plataforma dp
    ON dp.id_plataforma = fp.id_plataforma
WHERE fp.id_bairro IS NULL
  AND dp.plataforma <> 'Balcao'
LIMIT 100;


-- =========================================================
-- 5. VALIDAR REGISTROS SEM PRODUTO RELACIONADO
--
-- Logica:
-- Se retornar linhas, algum produto da fato nao encontrou
-- correspondencia na dim_produto.
-- =========================================================

SELECT
    fp.chave_pedido_item,
    fp.pedido_id,
    fp.item_id,
    fp.id_produto
FROM fato_pedidos fp
LEFT JOIN dim_produto dp
    ON dp.id_produto = fp.id_produto
WHERE dp.id_produto IS NULL
LIMIT 100;


-- =========================================================
-- 6. VALIDAR REGISTROS SEM CLIENTE RELACIONADO
-- =========================================================

SELECT
    fp.chave_pedido_item,
    fp.pedido_id,
    fp.item_id,
    fp.id_cliente
FROM fato_pedidos fp
LEFT JOIN dim_cliente dc
    ON dc.id_cliente = fp.id_cliente
WHERE dc.id_cliente IS NULL
LIMIT 100;


-- =========================================================
-- 7. COMPARAR TOTAIS FINANCEIROS STG X FATO
--
-- Logica:
-- A soma dos principais valores deve bater entre stg e fato.
-- Pequenas diferencas nao deveriam ocorrer aqui, pois estamos
-- apenas transportando os valores.
-- =========================================================

SELECT
    'stg_pedidos' AS origem,
    SUM(Quantidade) AS total_quantidade,
    ROUND(SUM(ValorBruto), 2) AS total_valor_bruto,
    ROUND(SUM(Desconto), 2) AS total_desconto,
    ROUND(SUM(ValorLiquido), 2) AS total_valor_liquido,
    ROUND(SUM(TaxaEntrega), 2) AS total_taxa_entrega
FROM stg_pedidos

UNION ALL

SELECT
    'fato_pedidos' AS origem,
    SUM(quantidade) AS total_quantidade,
    ROUND(SUM(valor_bruto), 2) AS total_valor_bruto,
    ROUND(SUM(desconto), 2) AS total_desconto,
    ROUND(SUM(valor_liquido), 2) AS total_valor_liquido,
    ROUND(SUM(taxa_entrega), 2) AS total_taxa_entrega
FROM fato_pedidos;


-- =========================================================
-- 8. VALIDAR DISTRIBUICAO POR STATUS
--
-- Logica:
-- Confere se os status aparecem corretamente via dimensao.
-- =========================================================

SELECT
    dsp.status_pedido,
    COUNT(*) AS qtd_itens,
    ROUND(SUM(fp.valor_liquido), 2) AS total_valor_liquido
FROM fato_pedidos fp
LEFT JOIN dim_status_pedido dsp
    ON dsp.id_status_pedido = fp.id_status_pedido
GROUP BY dsp.status_pedido
ORDER BY qtd_itens DESC;


-- =========================================================
-- 9. VALIDAR DISTRIBUICAO POR CANAL E PLATAFORMA
--
-- Logica:
-- Confere se o modelo estrela permite cruzar canal,
-- plataforma e valores de venda.
-- =========================================================

SELECT
    dc.canal,
    dp.plataforma,
    COUNT(*) AS qtd_itens,
    ROUND(SUM(fp.valor_liquido), 2) AS total_valor_liquido
FROM fato_pedidos fp
LEFT JOIN dim_canal dc
    ON dc.id_canal = fp.id_canal
LEFT JOIN dim_plataforma dp
    ON dp.id_plataforma = fp.id_plataforma
GROUP BY
    dc.canal,
    dp.plataforma
ORDER BY total_valor_liquido DESC;


-- =========================================================
-- 10. AMOSTRA FINAL DO MODELO
--
-- Logica:
-- Exibe dados da fato com descricoes das dimensoes,
-- simulando o que o Power BI vai consumir.
-- =========================================================

SELECT
    fp.id_fato_pedido,
    fp.chave_pedido_item,
    fp.pedido_id,
    fp.item_id,
    fp.data_pedido,
    fp.hora_pedido,

    dprod.produto,
    dprod.categoria_produto,
    dcli.cliente_codigo_origem,
    dcanal.canal,
    dplat.plataforma,
    dbairro.bairro,
    dstatus.status_pedido,
    dfp.forma_pagamento,
    dcupom.cupom,

    fp.quantidade,
    fp.valor_unitario,
    fp.valor_bruto,
    fp.desconto,
    fp.valor_liquido,
    fp.taxa_entrega,

    fp.campanha_id
FROM fato_pedidos fp
LEFT JOIN dim_produto dprod
    ON dprod.id_produto = fp.id_produto
LEFT JOIN dim_cliente dcli
    ON dcli.id_cliente = fp.id_cliente
LEFT JOIN dim_canal dcanal
    ON dcanal.id_canal = fp.id_canal
LEFT JOIN dim_plataforma dplat
    ON dplat.id_plataforma = fp.id_plataforma
LEFT JOIN dim_bairro dbairro
    ON dbairro.id_bairro = fp.id_bairro
LEFT JOIN dim_status_pedido dstatus
    ON dstatus.id_status_pedido = fp.id_status_pedido
LEFT JOIN dim_forma_pagamento dfp
    ON dfp.id_forma_pagamento = fp.id_forma_pagamento
LEFT JOIN dim_cupom dcupom
    ON dcupom.id_cupom = fp.id_cupom
ORDER BY fp.id_fato_pedido
LIMIT 100;