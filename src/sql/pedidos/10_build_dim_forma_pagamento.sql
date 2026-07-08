-- =========================================================
-- QUERY 10: build_dim_forma_pagamento
-- ORIGEM: stg_pedidos + stg_financeiro
-- DESTINO: dim_forma_pagamento
--
-- OBJETIVO:
-- Criar uma dimensao compartilhada de formas de pagamento.
--
-- NOTE(ai-pass): esta dimensao era criada apenas por pedidos, mas a
-- fato_financeiro tambem usa id_forma_pagamento. Se a dimensao nasce
-- so de pedidos, o financeiro perde relacionamento depois da orquestracao.
-- =========================================================

DROP TABLE IF EXISTS dim_forma_pagamento;

CREATE TABLE dim_forma_pagamento (
    id_forma_pagamento INTEGER PRIMARY KEY,
    forma_pagamento TEXT NOT NULL UNIQUE
);

INSERT INTO dim_forma_pagamento (
    id_forma_pagamento,
    forma_pagamento
)
WITH formas_pagamento_unicas AS (
    SELECT DISTINCT
        CASE
            WHEN forma_pagamento IS NULL OR TRIM(forma_pagamento) = '' THEN 'Nao Informado'
            ELSE TRIM(forma_pagamento)
        END AS forma_pagamento
    FROM stg_pedidos

    UNION

    SELECT DISTINCT
        CASE
            WHEN forma_pagamento IS NULL OR TRIM(forma_pagamento) = '' THEN 'Nao Informado'
            ELSE TRIM(forma_pagamento)
        END AS forma_pagamento
    FROM stg_financeiro
),

formas_pagamento_numeradas AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY forma_pagamento
        ) AS id_forma_pagamento,

        forma_pagamento

    FROM formas_pagamento_unicas
)

SELECT
    id_forma_pagamento,
    forma_pagamento
FROM formas_pagamento_numeradas;
