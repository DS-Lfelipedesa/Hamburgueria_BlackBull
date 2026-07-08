-- =========================================================
-- QUERY 05: build_dim_tipo_conteudo
-- ORIGEM: stg_redes_sociais
-- DESTINO: dim_tipo_conteudo
--
-- Grao:
-- 1 linha = 1 tipo de conteudo.
-- =========================================================

DROP TABLE IF EXISTS dim_tipo_conteudo;

CREATE TABLE dim_tipo_conteudo (
    id_tipo_conteudo INTEGER PRIMARY KEY,
    tipo_conteudo TEXT NOT NULL
);

INSERT INTO dim_tipo_conteudo (
    id_tipo_conteudo,
    tipo_conteudo
)
WITH tipos_unicos AS (
    SELECT DISTINCT
        CASE
            WHEN tipo_conteudo IS NULL OR TRIM(tipo_conteudo) = '' THEN 'Nao Informado'
            ELSE TRIM(tipo_conteudo)
        END AS tipo_conteudo
    FROM stg_redes_sociais
),

tipos_numerados AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY tipo_conteudo
        ) AS id_tipo_conteudo,
        tipo_conteudo
    FROM tipos_unicos
)

SELECT
    id_tipo_conteudo,
    tipo_conteudo
FROM tipos_numerados;

