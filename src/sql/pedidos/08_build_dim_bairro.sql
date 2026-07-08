-- =========================================================
-- QUERY 08: build_dim_bairro
-- ORIGEM: stg_pedidos
-- DESTINO: dim_bairro
--
-- OBJETIVO:
-- Criar uma dimensão de bairros a partir da stg_pedidos.
--
-- LOGICA:
-- 1. Buscar bairros únicos na stg_pedidos
-- 2. Ignorar registros onde bairro é NULL
-- 3. Tratar bairro vazio como 'Nao Informado'
-- 4. Criar uma chave técnica id_bairro
-- 5. Guardar o nome padronizado do bairro
--
-- OBSERVACAO:
-- Bairro NULL é esperado quando plataforma = Balcao.
-- Por isso, NULL não entra na dimensão.
-- =========================================================

DROP TABLE IF EXISTS dim_bairro;

CREATE TABLE dim_bairro (
    id_bairro INTEGER PRIMARY KEY,
    bairro TEXT NOT NULL
);

INSERT INTO dim_bairro (
    id_bairro,
    bairro
)
WITH bairros_unicos AS (
    SELECT DISTINCT
        -- Se bairro estiver em branco, vira Nao Informado.
        -- Se for NULL, nao entra na dimensao por causa do WHERE.
        CASE
            WHEN TRIM(bairro) = '' THEN 'Nao Informado'
            ELSE TRIM(bairro)
        END AS bairro

    FROM stg_pedidos

    -- Mantemos fora da dimensão os bairros NULL.
    -- Eles representam casos onde bairro nao se aplica,
    -- como pedidos de Balcao.
    WHERE bairro IS NOT NULL
),

bairros_numerados AS (
    SELECT
        -- Cria chave técnica sequencial para relacionamento na fato.
        ROW_NUMBER() OVER (
            ORDER BY bairro
        ) AS id_bairro,

        bairro

    FROM bairros_unicos
)

SELECT
    id_bairro,
    bairro
FROM bairros_numerados;