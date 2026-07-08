-- =========================================================
-- QUERY 06: build_dim_tema_conteudo
-- ORIGEM: stg_redes_sociais
-- DESTINO: dim_tema_conteudo
--
-- Grao:
-- 1 linha = 1 tema/editorial de conteudo.
-- =========================================================

DROP TABLE IF EXISTS dim_tema_conteudo;

CREATE TABLE dim_tema_conteudo (
    id_tema_conteudo INTEGER PRIMARY KEY,
    tema_conteudo TEXT NOT NULL
);

INSERT INTO dim_tema_conteudo (
    id_tema_conteudo,
    tema_conteudo
)
WITH temas_unicos AS (
    SELECT DISTINCT
        CASE
            WHEN tema_conteudo IS NULL OR TRIM(tema_conteudo) = '' THEN 'Nao Informado'
            ELSE TRIM(tema_conteudo)
        END AS tema_conteudo
    FROM stg_redes_sociais
),

temas_numerados AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY tema_conteudo
        ) AS id_tema_conteudo,
        tema_conteudo
    FROM temas_unicos
)

SELECT
    id_tema_conteudo,
    tema_conteudo
FROM temas_numerados;

