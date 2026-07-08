-- =========================================================
-- QUERY 11: build_dim_cupom
-- PADRAO: PRODUCAO / CARGA INCREMENTAL
-- ORIGEM: stg_pedidos
-- DESTINO: dim_cupom
--
-- OBJETIVO:
-- Criar ou atualizar a dimensão de cupons sem perder
-- os IDs já existentes.
--
-- LOGICA:
-- 1. Criar a tabela se ela ainda não existir
-- 2. Buscar cupons únicos da stg_pedidos
-- 3. Tratar nulos/vazios como 'Sem Cupom'
-- 4. Inserir somente cupons que ainda não existem na dimensão
--
-- IMPORTANTE:
-- Não usamos DROP TABLE em dimensão de produção,
-- porque isso recriaria os IDs e quebraria histórico.
-- =========================================================

CREATE TABLE IF NOT EXISTS dim_cupom (
    id_cupom INTEGER PRIMARY KEY AUTOINCREMENT,
    cupom TEXT NOT NULL UNIQUE
);

INSERT INTO dim_cupom (
    cupom
)
WITH cupons_unicos AS (
    SELECT DISTINCT
        CASE
            WHEN cupom IS NULL OR TRIM(cupom) = '' THEN 'Sem Cupom'
            ELSE TRIM(cupom)
        END AS cupom
    FROM stg_pedidos
)

SELECT
    cu.cupom
FROM cupons_unicos cu
LEFT JOIN dim_cupom dc
    ON dc.cupom = cu.cupom
WHERE dc.id_cupom IS NULL;