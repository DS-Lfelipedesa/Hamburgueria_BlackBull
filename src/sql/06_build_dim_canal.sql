-- =========================================================
-- QUERY 06: build_dim_canal
-- ORIGEM: stg_pedidos
-- DESTINO: dim_canal
--
-- OBJETIVO:
-- Criar uma dimensão de canal de venda.
--
-- LOGICA:
-- 1. Buscar canais únicos na stg_pedidos
-- 2. Tratar canal nulo ou vazio como 'Nao Informado'
-- 3. Criar uma chave técnica id_canal
-- 4. Guardar o nome padronizado do canal
--
-- EXEMPLOS DE CANAL:
-- Salao
-- Delivery
-- Retirada
-- Nao Informado
-- =========================================================

DROP TABLE IF EXISTS dim_canal;

CREATE TABLE dim_canal (
    id_canal INTEGER PRIMARY KEY,
    canal TEXT NOT NULL
);

INSERT INTO dim_canal (
    id_canal,
    canal
)
WITH canais_unicos AS (
    SELECT DISTINCT
        -- Garante que a dimensão não tenha canal nulo ou em branco.
        CASE
            WHEN canal IS NULL OR TRIM(canal) = '' THEN 'Nao Informado'
            ELSE TRIM(canal)
        END AS canal

    FROM stg_pedidos
),

canais_numerados AS (
    SELECT
        -- Cria uma chave técnica sequencial para relacionamento na fato.
        ROW_NUMBER() OVER (
            ORDER BY canal
        ) AS id_canal,

        canal

    FROM canais_unicos
)

SELECT
    id_canal,
    canal
FROM canais_numerados;