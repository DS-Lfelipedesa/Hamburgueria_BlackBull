-- =========================================================
-- QUERY 05: build_dim_cliente
-- ORIGEM: stg_pedidos
-- DESTINO: dim_cliente
--
-- OBJETIVO:
-- Criar uma dimensão de clientes a partir da stg_pedidos.
--
-- LOGICA:
-- 1. Buscar clientes únicos na stg_pedidos
-- 2. Tratar ClienteID nulo ou vazio como 'Nao Informado'
-- 3. Criar uma chave técnica id_cliente
-- 4. Guardar o código original do cliente
--
-- OBSERVACAO:
-- A base atual possui apenas ClienteID.
-- Caso futuramente existam nome, telefone, email ou bairro do cliente,
-- esses atributos podem ser adicionados nesta dimensão.
-- =========================================================

DROP TABLE IF EXISTS dim_cliente;

CREATE TABLE dim_cliente (
    id_cliente INTEGER PRIMARY KEY,
    cliente_codigo_origem TEXT NOT NULL
);

INSERT INTO dim_cliente (
    id_cliente,
    cliente_codigo_origem
)
WITH clientes_unicos AS (
    SELECT DISTINCT
        -- Padroniza clientes sem identificação.
        -- Isso evita valores nulos dentro da dimensão.
        CASE
            WHEN ClienteID IS NULL OR TRIM(ClienteID) = '' THEN 'Nao Informado'
            ELSE TRIM(ClienteID)
        END AS cliente_codigo_origem

    FROM stg_pedidos
),

clientes_numerados AS (
    SELECT
        -- Cria uma chave técnica sequencial.
        -- Essa chave será usada depois na fato_pedidos.
        ROW_NUMBER() OVER (
            ORDER BY cliente_codigo_origem
        ) AS id_cliente,

        cliente_codigo_origem

    FROM clientes_unicos
)

SELECT
    id_cliente,
    cliente_codigo_origem
FROM clientes_numerados;