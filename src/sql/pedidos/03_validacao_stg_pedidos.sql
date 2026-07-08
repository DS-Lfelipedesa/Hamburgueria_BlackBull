-- =========================================================
-- QUERY 03: validacao_stg_pedidos
-- ORIGEM: stg_pedidos
--
-- OBJETIVO:
-- Validar se a tabela stg_pedidos foi criada corretamente
-- a partir da raw_pedidos.
--
-- ESTA QUERY NAO ALTERA DADOS.
--
-- VALIDACOES:
-- 1. Comparar volume entre raw e stg
-- 2. Verificar padronizacao de canal
-- 3. Verificar padronizacao de plataforma
-- 4. Validar regra Plataforma = Balcao
-- 5. Verificar bairro nulo para Balcao
-- 6. Validar forma de pagamento
-- 7. Validar status do pedido
-- 8. Verificar campos importantes nulos
-- 9. Verificar valores numericos inconsistentes
-- 10. Verificar duplicidade PedidoID + ItemID
-- =========================================================


-- =========================================================
-- 1. COMPARACAO DE VOLUME RAW X STG
--
-- Logica:
-- A staging deve ter a mesma quantidade de linhas da raw,
-- porque nesta etapa estamos tratando dados, nao filtrando.
-- =========================================================

SELECT
    'raw_pedidos' AS tabela,
    COUNT(*) AS total_linhas
FROM raw_pedidos

UNION ALL

SELECT
    'stg_pedidos' AS tabela,
    COUNT(*) AS total_linhas
FROM stg_pedidos;


-- =========================================================
-- 2. VALIDACAO DE CANAL
--
-- Logica:
-- Depois do tratamento, esperamos encontrar valores
-- padronizados como:
-- Salao, Delivery, Retirada, Nao Informado.
-- =========================================================

SELECT
    canal,
    COUNT(*) AS qtd_linhas
FROM stg_pedidos
GROUP BY canal
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 3. VALIDACAO DE PLATAFORMA
--
-- Logica:
-- Verifica se Plataforma foi padronizada sem acento
-- e com primeira letra maiuscula.
-- =========================================================

SELECT
    plataforma,
    COUNT(*) AS qtd_linhas
FROM stg_pedidos
GROUP BY plataforma
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 4. VALIDACAO DA REGRA PLATAFORMA = BALCAO
--
-- Logica:
-- Todo registro com plataforma Balcao deve ter canal = Salao.
--
-- Se esta query retornar linhas, existe erro de tratamento.
-- =========================================================

SELECT
    plataforma,
    canal,
    COUNT(*) AS qtd_linhas
FROM stg_pedidos
WHERE plataforma = 'Balcao'
  AND canal <> 'Salao'
GROUP BY
    plataforma,
    canal;


-- =========================================================
-- 5. VALIDACAO DE BAIRRO PARA PLATAFORMA BALCAO
--
-- Logica:
-- Todo registro com plataforma Balcao deve ter bairro NULL.
--
-- Se esta query retornar linhas, existe erro de tratamento.
-- =========================================================

SELECT
    plataforma,
    bairro,
    COUNT(*) AS qtd_linhas
FROM stg_pedidos
WHERE plataforma = 'Balcao'
  AND bairro IS NOT NULL
GROUP BY
    plataforma,
    bairro;


-- =========================================================
-- 6. VALIDACAO DE BAIRRO PARA OUTRAS PLATAFORMAS
--
-- Logica:
-- Para pedidos que nao sao Balcao, bairro pode existir.
-- Aqui verificamos como os bairros ficaram distribuidos.
-- =========================================================

SELECT
    bairro,
    COUNT(*) AS qtd_linhas
FROM stg_pedidos
WHERE plataforma <> 'Balcao'
GROUP BY bairro
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 7. VALIDACAO DE FORMA DE PAGAMENTO
--
-- Logica:
-- Verifica se valores como Credito, Debito, Pix, Voucher,
-- Dinheiro e Cartao ficaram padronizados.
-- =========================================================

SELECT
    forma_pagamento,
    COUNT(*) AS qtd_linhas
FROM stg_pedidos
GROUP BY forma_pagamento
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 8. VALIDACAO DE STATUS DO PEDIDO
--
-- Logica:
-- Verifica se status como Concluido, Cancelado e Reembolsado
-- ficaram padronizados.
-- =========================================================

SELECT
    status_pedido,
    COUNT(*) AS qtd_linhas
FROM stg_pedidos
GROUP BY status_pedido
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 9. VALIDACAO DE CAMPOS IMPORTANTES NULOS
--
-- Logica:
-- Campos-chave para analise nao deveriam estar nulos,
-- exceto quando existe regra de negocio permitindo isso,
-- como bairro nulo para plataforma Balcao.
-- =========================================================

SELECT
    SUM(CASE WHEN PedidoID IS NULL THEN 1 ELSE 0 END) AS pedido_id_nulo,
    SUM(CASE WHEN ItemID IS NULL OR TRIM(ItemID) = '' THEN 1 ELSE 0 END) AS item_id_nulo,
    SUM(CASE WHEN DataHora IS NULL OR TRIM(DataHora) = '' THEN 1 ELSE 0 END) AS data_hora_nula,
    SUM(CASE WHEN data_pedido IS NULL THEN 1 ELSE 0 END) AS data_pedido_nula,
    SUM(CASE WHEN hora_pedido IS NULL THEN 1 ELSE 0 END) AS hora_pedido_nula,
    SUM(CASE WHEN ClienteID IS NULL OR TRIM(ClienteID) = '' THEN 1 ELSE 0 END) AS cliente_id_nulo,
    SUM(CASE WHEN produto_id IS NULL OR TRIM(produto_id) = '' THEN 1 ELSE 0 END) AS produto_id_nulo,
    SUM(CASE WHEN produto IS NULL OR TRIM(produto) = '' THEN 1 ELSE 0 END) AS produto_nulo,
    SUM(CASE WHEN categoria_produto IS NULL OR TRIM(categoria_produto) = '' THEN 1 ELSE 0 END) AS categoria_produto_nula,
    SUM(CASE WHEN canal IS NULL OR TRIM(canal) = '' THEN 1 ELSE 0 END) AS canal_nulo,
    SUM(CASE WHEN plataforma IS NULL OR TRIM(plataforma) = '' THEN 1 ELSE 0 END) AS plataforma_nula,
    SUM(CASE WHEN forma_pagamento IS NULL OR TRIM(forma_pagamento) = '' THEN 1 ELSE 0 END) AS forma_pagamento_nula,
    SUM(CASE WHEN status_pedido IS NULL OR TRIM(status_pedido) = '' THEN 1 ELSE 0 END) AS status_pedido_nulo
FROM stg_pedidos;


-- =========================================================
-- 10. VALIDACAO DE VALORES NUMERICOS
--
-- Logica:
-- Verifica se existem quantidades ou valores negativos.
-- Nem sempre negativo e erro, mas precisa ser conhecido.
-- =========================================================

SELECT
    SUM(CASE WHEN Quantidade IS NULL THEN 1 ELSE 0 END) AS quantidade_nula,
    SUM(CASE WHEN Quantidade <= 0 THEN 1 ELSE 0 END) AS quantidade_menor_ou_igual_zero,

    SUM(CASE WHEN ValorUnitario IS NULL THEN 1 ELSE 0 END) AS valor_unitario_nulo,
    SUM(CASE WHEN ValorUnitario < 0 THEN 1 ELSE 0 END) AS valor_unitario_negativo,

    SUM(CASE WHEN ValorBruto IS NULL THEN 1 ELSE 0 END) AS valor_bruto_nulo,
    SUM(CASE WHEN ValorBruto < 0 THEN 1 ELSE 0 END) AS valor_bruto_negativo,

    SUM(CASE WHEN Desconto IS NULL THEN 1 ELSE 0 END) AS desconto_nulo,
    SUM(CASE WHEN Desconto < 0 THEN 1 ELSE 0 END) AS desconto_negativo,

    SUM(CASE WHEN ValorLiquido IS NULL THEN 1 ELSE 0 END) AS valor_liquido_nulo,
    SUM(CASE WHEN ValorLiquido < 0 THEN 1 ELSE 0 END) AS valor_liquido_negativo,

    SUM(CASE WHEN TaxaEntrega IS NULL THEN 1 ELSE 0 END) AS taxa_entrega_nula,
    SUM(CASE WHEN TaxaEntrega < 0 THEN 1 ELSE 0 END) AS taxa_entrega_negativa
FROM stg_pedidos;


-- =========================================================
-- 11. VALIDACAO DE DUPLICIDADE DE ITEM
--
-- Logica:
-- Em uma tabela de itens de pedido, a combinacao
-- PedidoID + ItemID normalmente deveria ser unica.
--
-- Se retornar linhas, pode haver duplicidade.
-- =========================================================

SELECT
    PedidoID,
    ItemID,
    COUNT(*) AS qtd_ocorrencias
FROM stg_pedidos
GROUP BY
    PedidoID,
    ItemID
HAVING COUNT(*) > 1
ORDER BY qtd_ocorrencias DESC;


-- =========================================================
-- 12. AMOSTRA FINAL PARA INSPECAO VISUAL
--
-- Logica:
-- Mostra algumas linhas tratadas para conferir visualmente
-- se os campos ficaram legiveis e padronizados.
-- =========================================================

SELECT
    PedidoID,
    ItemID,
    DataHora,
    data_pedido,
    hora_pedido,
    ClienteID,
    plataforma,
    canal,
    bairro,
    produto_id,
    produto,
    categoria_produto,
    Quantidade,
    ValorUnitario,
    ValorBruto,
    Desconto,
    ValorLiquido,
    TaxaEntrega,
    forma_pagamento,
    status_pedido,
    cupom,
    campanha_id
FROM stg_pedidos
LIMIT 50;