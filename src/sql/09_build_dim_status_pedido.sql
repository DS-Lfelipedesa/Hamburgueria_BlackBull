-- =========================================================
-- QUERY 09: build_dim_status_pedido
-- ORIGEM: stg_pedidos
-- DESTINO: dim_status_pedido
--
-- OBJETIVO:
-- Criar uma dimensão de status do pedido.
--
-- LOGICA:
-- 1. Buscar status únicos na stg_pedidos
-- 2. Tratar status nulo ou vazio como 'Nao Informado'
-- 3. Criar uma chave técnica id_status_pedido
-- 4. Guardar o status padronizado do pedido
--
-- EXEMPLOS DE STATUS:
-- Concluido
-- Cancelado
-- Reembolsado
-- Nao Informado
-- =========================================================

DROP TABLE IF EXISTS dim_status_pedido;

CREATE TABLE dim_status_pedido (
    id_status_pedido INTEGER PRIMARY KEY,
    status_pedido TEXT NOT NULL
);

INSERT INTO dim_status_pedido (
    id_status_pedido,
    status_pedido
)
WITH status_unicos AS (
    SELECT DISTINCT
        -- Garante que a dimensão não tenha status nulo ou em branco.
        CASE
            WHEN status_pedido IS NULL OR TRIM(status_pedido) = '' THEN 'Nao Informado'
            ELSE TRIM(status_pedido)
        END AS status_pedido

    FROM stg_pedidos
),

status_numerados AS (
    SELECT
        -- Cria uma chave técnica sequencial para relacionamento na fato.
        ROW_NUMBER() OVER (
            ORDER BY status_pedido
        ) AS id_status_pedido,

        status_pedido

    FROM status_unicos
)

SELECT
    id_status_pedido,
    status_pedido
FROM status_numerados;