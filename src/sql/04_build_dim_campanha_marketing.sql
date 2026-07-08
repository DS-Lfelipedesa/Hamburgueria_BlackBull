-- query 05 - build dim plataforma marketing
-- objetivo: criar/atualizar a dimensao de plataformas de marketing
-- origem: stg_marketing
-- destino: dim_plataforma_marketing
-- NOTE: nao usar dim_plataforma porque ela parece ser de pedidos/vendas

CREATE TABLE IF NOT EXISTS dim_plataforma_marketing (
    id_plataforma_marketing INTEGER PRIMARY KEY AUTOINCREMENT,
    plataforma_marketing TEXT NOT NULL UNIQUE
);

INSERT INTO dim_plataforma_marketing (
    plataforma_marketing
)
SELECT DISTINCT
    CASE
        WHEN LOWER(TRIM(Plataforma)) = 'facebook ads' THEN 'Facebook Ads'
        WHEN LOWER(TRIM(Plataforma)) = 'google ads' THEN 'Google Ads'
        ELSE TRIM(Plataforma)
    END AS plataforma_marketing
FROM stg_marketing
WHERE Plataforma IS NOT NULL
  AND TRIM(Plataforma) <> ''
ON CONFLICT(plataforma_marketing) DO NOTHING;