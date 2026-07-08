-- =========================================================
-- QUERY 04: build_dim_rede_social
-- ORIGEM: stg_redes_sociais
-- DESTINO: dim_rede_social
--
-- Grao:
-- 1 linha = 1 rede social/plataforma social.
--
-- NOTE: uso DROP nesta primeira versao porque o projeto ainda sera
-- reconstruido localmente. Quando virar incremental, rever isso.
-- =========================================================

DROP TABLE IF EXISTS dim_rede_social;

CREATE TABLE dim_rede_social (
    id_rede_social INTEGER PRIMARY KEY,
    rede_social TEXT NOT NULL
);

INSERT INTO dim_rede_social (
    id_rede_social,
    rede_social
)
WITH redes_unicas AS (
    SELECT DISTINCT
        CASE
            WHEN rede_social IS NULL OR TRIM(rede_social) = '' THEN 'Nao Informado'
            ELSE TRIM(rede_social)
        END AS rede_social
    FROM stg_redes_sociais
),

redes_numeradas AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY rede_social
        ) AS id_rede_social,
        rede_social
    FROM redes_unicas
)

SELECT
    id_rede_social,
    rede_social
FROM redes_numeradas;

