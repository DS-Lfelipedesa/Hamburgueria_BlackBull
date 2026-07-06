-- =========================================================
-- QUERY 04: build_dim_produto
-- ORIGEM: stg_pedidos
-- DESTINO: dim_produto
--
-- OBJETIVO:
-- Criar uma dimensão de produtos a partir da stg_pedidos.
--
-- LOGICA:
-- 1. Buscar produtos únicos na stg_pedidos
-- 2. Padronizar ProdutoID vazio como 'Nao Informado'
-- 3. Criar uma chave técnica id_produto
-- 4. Guardar atributos descritivos do produto
--
-- OBSERVACAO:
-- A dimensão não guarda valores de venda, quantidade ou desconto.
-- Ela guarda apenas informações descritivas do produto.
-- =========================================================

DROP TABLE IF EXISTS dim_produto;

CREATE TABLE dim_produto (
    id_produto INTEGER PRIMARY KEY,
    produto_codigo_origem TEXT,
    produto TEXT NOT NULL,
    categoria_produto TEXT NOT NULL
);

INSERT INTO dim_produto (
    id_produto,
    produto_codigo_origem,
    produto,
    categoria_produto
)
WITH produtos_unicos AS (
    SELECT DISTINCT
        -- Trata ProdutoID nulo ou vazio para evitar código em branco na dimensão
        CASE
            WHEN produto_id IS NULL OR TRIM(produto_id) = '' THEN 'Nao Informado'
            ELSE TRIM(produto_id)
        END AS produto_codigo_origem,

        -- Nome do produto já vem tratado da stg_pedidos
        produto,

        -- Categoria também já vem tratada da stg_pedidos
        categoria_produto

    FROM stg_pedidos
),

produtos_numerados AS (
    SELECT
        -- Cria uma chave técnica sequencial para uso no modelo dimensional
        ROW_NUMBER() OVER (
            ORDER BY produto_codigo_origem, produto, categoria_produto
        ) AS id_produto,

        produto_codigo_origem,
        produto,
        categoria_produto

    FROM produtos_unicos
)

SELECT
    id_produto,
    produto_codigo_origem,
    produto,
    categoria_produto
FROM produtos_numerados;