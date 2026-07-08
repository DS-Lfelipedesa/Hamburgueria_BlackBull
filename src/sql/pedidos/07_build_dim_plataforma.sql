-- =========================================================
-- QUERY 07: build_dim_plataforma
-- ORIGEM: stg_pedidos
-- DESTINO: dim_plataforma
--
-- OBJETIVO:
-- Criar uma dimensão de plataforma de venda.
--
-- LOGICA:
-- 1. Buscar plataformas únicas na stg_pedidos
-- 2. Tratar plataforma nula ou vazia como 'Nao Informado'
-- 3. Criar uma chave técnica id_plataforma
-- 4. Guardar o nome padronizado da plataforma
--
-- EXEMPLOS DE PLATAFORMA:
-- Balcao
-- Ifood
-- Whatsapp
-- App Proprio
-- Telefone
-- =========================================================

DROP TABLE IF EXISTS dim_plataforma;

CREATE TABLE dim_plataforma (
    id_plataforma INTEGER PRIMARY KEY,
    plataforma TEXT NOT NULL
);

INSERT INTO dim_plataforma (
    id_plataforma,
    plataforma
)
WITH plataformas_unicas AS (
    SELECT DISTINCT
        -- Garante que a dimensão não tenha plataforma nula ou em branco.
        CASE
            WHEN plataforma IS NULL OR TRIM(plataforma) = '' THEN 'Nao Informado'
            ELSE TRIM(plataforma)
        END AS plataforma

    FROM stg_pedidos
),

plataformas_numeradas AS (
    SELECT
        -- Cria uma chave técnica sequencial para relacionamento na fato.
        ROW_NUMBER() OVER (
            ORDER BY plataforma
        ) AS id_plataforma,

        plataforma

    FROM plataformas_unicas
)

SELECT
    id_plataforma,
    plataforma
FROM plataformas_numeradas;