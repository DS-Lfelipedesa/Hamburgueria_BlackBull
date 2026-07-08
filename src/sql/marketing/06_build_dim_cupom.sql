-- query 06 - build dim cupom
-- objetivo: adicionar os cupons de marketing na dimensao dim_cupom
-- origem: stg_marketing
-- destino: dim_cupom
-- NOTE: dim_cupom ja existe no banco, entao nao cria tabela nova

INSERT INTO dim_cupom (
    cupom
)
SELECT DISTINCT
    TRIM(Cupom) AS cupom
FROM stg_marketing
WHERE Cupom IS NOT NULL
  AND TRIM(Cupom) <> ''
ON CONFLICT(cupom) DO NOTHING;