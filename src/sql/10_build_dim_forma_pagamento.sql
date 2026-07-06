-- =========================================================
-- QUERY 10: build_dim_forma_pagamento
-- ORIGEM: stg_pedidos
-- DESTINO: dim_forma_pagamento
--
-- OBJETIVO:
-- Criar uma dimensão de formas de pagamento dos pedidos.
--
-- LOGICA:
-- 1. Buscar formas de pagamento únicas na stg_pedidos
-- 2. Tratar forma de pagamento nula ou vazia como 'Nao Informado'
-- 3. Criar uma chave técnica id_forma_pagamento
-- 4. Guardar a forma de pagamento padronizada
--
-- EXEMPLOS:
-- Credito
-- Debito
-- Pix
-- Voucher
-- Dinheiro
-- Cartao
-- Nao Informado
-- =========================================================

DROP TABLE IF EXISTS dim_forma_pagamento;

CREATE TABLE dim_forma_pagamento (
    id_forma_pagamento INTEGER PRIMARY KEY,
    forma_pagamento TEXT NOT NULL
);

INSERT INTO dim_forma_pagamento (
    id_forma_pagamento,
    forma_pagamento
)
WITH formas_pagamento_unicas AS (
    SELECT DISTINCT
        -- Garante que a dimensão não tenha pagamento nulo ou em branco.
        CASE
            WHEN forma_pagamento IS NULL OR TRIM(forma_pagamento) = '' THEN 'Nao Informado'
            ELSE TRIM(forma_pagamento)
        END AS forma_pagamento

    FROM stg_pedidos
),

formas_pagamento_numeradas AS (
    SELECT
        -- Cria uma chave técnica sequencial para relacionamento na fato.
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