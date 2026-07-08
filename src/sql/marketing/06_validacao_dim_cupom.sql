-- validacao dim cupom apos carga de marketing
-- objetivo: ver se ainda tem cupom da stg_marketing fora da dim_cupom

SELECT
    COUNT(*) AS cupons_marketing_fora_dim
FROM (
    SELECT DISTINCT
        TRIM(Cupom) AS cupom
    FROM stg_marketing
    WHERE Cupom IS NOT NULL
      AND TRIM(Cupom) <> ''
) s
LEFT JOIN dim_cupom d
    ON d.cupom = s.cupom
WHERE d.id_cupom IS NULL;