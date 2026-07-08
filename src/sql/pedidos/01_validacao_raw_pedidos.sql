-- =========================================================
-- QUERY 01: validacao_raw_pedidos
-- ORIGEM: raw_pedidos
--
-- OBJETIVO:
-- Validar a qualidade dos dados brutos antes de criar
-- a tabela stg_pedidos.
--
-- ESTA QUERY NAO ALTERA DADOS.
-- Ela apenas consulta a raw para encontrar:
-- 1. Quantidade total de linhas
-- 2. Campos nulos ou vazios
-- 3. Variações de preenchimento em textos importantes
-- 4. Possíveis problemas numéricos
-- 5. Regra de negócio envolvendo Plataforma = Balcao
-- =========================================================


-- =========================================================
-- 1. VOLUME GERAL DA RAW
--
-- Lógica:
-- Antes de tratar qualquer tabela, verificamos quantas linhas
-- existem na origem. Depois compararemos esse número com a stg.
-- =========================================================

SELECT
    COUNT(*) AS total_linhas_raw
FROM raw_pedidos;


-- =========================================================
-- 2. VALIDAÇÃO DE CAMPOS NULOS OU VAZIOS
--
-- Lógica:
-- Conta quantas linhas têm ausência de informação em campos
-- importantes para análise e relacionamento dimensional.
-- =========================================================

SELECT
    SUM(CASE WHEN PedidoID IS NULL THEN 1 ELSE 0 END) AS pedido_id_nulo,
    SUM(CASE WHEN ItemID IS NULL OR TRIM(ItemID) = '' THEN 1 ELSE 0 END) AS item_id_nulo,
    SUM(CASE WHEN DataHora IS NULL OR TRIM(DataHora) = '' THEN 1 ELSE 0 END) AS data_hora_nula,
    SUM(CASE WHEN ClienteID IS NULL OR TRIM(ClienteID) = '' THEN 1 ELSE 0 END) AS cliente_id_nulo,
    SUM(CASE WHEN Canal IS NULL OR TRIM(Canal) = '' THEN 1 ELSE 0 END) AS canal_nulo,
    SUM(CASE WHEN Plataforma IS NULL OR TRIM(Plataforma) = '' THEN 1 ELSE 0 END) AS plataforma_nula,
    SUM(CASE WHEN Bairro IS NULL OR TRIM(Bairro) = '' THEN 1 ELSE 0 END) AS bairro_nulo,
    SUM(CASE WHEN ProdutoID IS NULL OR TRIM(ProdutoID) = '' THEN 1 ELSE 0 END) AS produto_id_nulo,
    SUM(CASE WHEN Produto IS NULL OR TRIM(Produto) = '' THEN 1 ELSE 0 END) AS produto_nulo,
    SUM(CASE WHEN CategoriaProduto IS NULL OR TRIM(CategoriaProduto) = '' THEN 1 ELSE 0 END) AS categoria_produto_nula,
    SUM(CASE WHEN FormaPagamento IS NULL OR TRIM(FormaPagamento) = '' THEN 1 ELSE 0 END) AS forma_pagamento_nula,
    SUM(CASE WHEN StatusPedido IS NULL OR TRIM(StatusPedido) = '' THEN 1 ELSE 0 END) AS status_pedido_nulo
FROM raw_pedidos;


-- =========================================================
-- 3. VARIAÇÕES DE CANAL
--
-- Lógica:
-- Agrupa os valores preenchidos em Canal para identificar
-- diferenças como:
-- 'Salão', 'salao', 'Salão ', 'DELIVERY', 'delivry'.
-- =========================================================

SELECT
    Canal,
    COUNT(*) AS qtd_linhas
FROM raw_pedidos
GROUP BY Canal
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 4. VARIAÇÕES DE PLATAFORMA
--
-- Lógica:
-- Mostra como a coluna Plataforma está preenchida.
-- Essa coluna também será usada para regra de negócio:
-- Plataforma Balcao força Canal = Salao e Bairro = NULL.
-- =========================================================

SELECT
    Plataforma,
    COUNT(*) AS qtd_linhas
FROM raw_pedidos
GROUP BY Plataforma
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 5. VARIAÇÕES DE BAIRRO
--
-- Lógica:
-- Ajuda a entender se Bairro tem muitos nulos, espaços,
-- nomes duplicados por acento ou diferença de escrita.
-- =========================================================

SELECT
    Bairro,
    COUNT(*) AS qtd_linhas
FROM raw_pedidos
GROUP BY Bairro
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 6. VARIAÇÕES DE FORMA DE PAGAMENTO
--
-- Lógica:
-- Identifica preenchimentos equivalentes escritos de formas
-- diferentes, como 'Crédito', 'credito', 'cartao', etc.
-- =========================================================

SELECT
    FormaPagamento,
    COUNT(*) AS qtd_linhas
FROM raw_pedidos
GROUP BY FormaPagamento
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 7. VARIAÇÕES DE STATUS DO PEDIDO
--
-- Lógica:
-- Verifica status repetidos com escrita diferente.
-- Esses valores serão padronizados na staging.
-- =========================================================

SELECT
    StatusPedido,
    COUNT(*) AS qtd_linhas
FROM raw_pedidos
GROUP BY StatusPedido
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 8. VALIDAÇÃO DA REGRA PLATAFORMA = BALCAO
--
-- Lógica:
-- Verifica como Canal e Bairro estão preenchidos quando
-- Plataforma representa balcão.
--
-- Queremos confirmar quantos casos precisarão ser corrigidos:
-- - Canal deverá virar 'Salao'
-- - Bairro deverá virar NULL
-- =========================================================

SELECT
    Plataforma,
    Canal,
    Bairro,
    COUNT(*) AS qtd_linhas
FROM raw_pedidos
WHERE LOWER(TRIM(Plataforma)) IN ('balcão', 'balcao')
GROUP BY
    Plataforma,
    Canal,
    Bairro
ORDER BY qtd_linhas DESC;


-- =========================================================
-- 9. VALIDAÇÃO DE VALORES NUMÉRICOS
--
-- Lógica:
-- Procura quantidades e valores negativos ou nulos.
-- Dependendo do caso, podem indicar erro de origem,
-- cancelamento, reembolso ou necessidade de regra específica.
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
FROM raw_pedidos;


-- =========================================================
-- 10. POSSÍVEIS DUPLICIDADES DE ITENS
--
-- Lógica:
-- Em uma base de pedidos por item, normalmente a combinação
-- PedidoID + ItemID deveria identificar uma linha única.
--
-- Se houver duplicidade, precisamos investigar antes da fato.
-- =========================================================

SELECT
    PedidoID,
    ItemID,
    COUNT(*) AS qtd_ocorrencias
FROM raw_pedidos
GROUP BY
    PedidoID,
    ItemID
HAVING COUNT(*) > 1
ORDER BY qtd_ocorrencias DESC;