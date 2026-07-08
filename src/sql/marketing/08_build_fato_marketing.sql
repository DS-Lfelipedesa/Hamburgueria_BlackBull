-- query 08 - build fato marketing
-- objetivo: criar/atualizar a fato de campanhas de marketing
-- origem: stg_marketing
-- dimensoes: dim_campanha_marketing, dim_plataforma_marketing, dim_cupom, dim_data
-- destino: fato_marketing
-- NOTE: grao da fato = 1 linha por CampanhaID

CREATE TABLE IF NOT EXISTS fato_marketing (
    id_fato_marketing INTEGER PRIMARY KEY AUTOINCREMENT,

    campanha_id_origem TEXT NOT NULL UNIQUE,

    id_campanha_marketing INTEGER,
    id_plataforma_marketing INTEGER,
    id_cupom INTEGER,
    id_data_inicio INTEGER,
    id_data_fim INTEGER,

    data_inicio TEXT,
    data_fim TEXT,

    investimento REAL,
    impressoes INTEGER,
    cliques INTEGER,
    leads_cupom INTEGER,
    lift_estimado REAL,

    dias_campanha INTEGER,
    ctr REAL,
    cpc REAL,
    custo_por_lead REAL,
    taxa_lead_clique REAL,

    flag_sem_cupom INTEGER,
    flag_periodo_invalido INTEGER,
    flag_cliques_maior_impressoes INTEGER
);

INSERT INTO fato_marketing (
    campanha_id_origem,
    id_campanha_marketing,
    id_plataforma_marketing,
    id_cupom,
    id_data_inicio,
    id_data_fim,
    data_inicio,
    data_fim,
    investimento,
    impressoes,
    cliques,
    leads_cupom,
    lift_estimado,
    dias_campanha,
    ctr,
    cpc,
    custo_por_lead,
    taxa_lead_clique,
    flag_sem_cupom,
    flag_periodo_invalido,
    flag_cliques_maior_impressoes
)
SELECT
    TRIM(s.CampanhaID) AS campanha_id_origem,

    dc.id_campanha_marketing,
    dp.id_plataforma_marketing,
    dcu.id_cupom,
    ddi.id_data AS id_data_inicio,
    ddf.id_data AS id_data_fim,

    DATE(s.DataInicio) AS data_inicio,
    DATE(s.DataFim) AS data_fim,

    s.Investimento AS investimento,
    s.Impressoes AS impressoes,
    s.Cliques AS cliques,
    s.LeadsCupom AS leads_cupom,
    s.LiftEstimado AS lift_estimado,

    CAST(JULIANDAY(DATE(s.DataFim)) - JULIANDAY(DATE(s.DataInicio)) + 1 AS INTEGER) AS dias_campanha,

    CASE
        WHEN s.Impressoes > 0 THEN ROUND((s.Cliques * 1.0) / s.Impressoes, 4)
        ELSE NULL
    END AS ctr,

    CASE
        WHEN s.Cliques > 0 THEN ROUND(s.Investimento / s.Cliques, 2)
        ELSE NULL
    END AS cpc,

    CASE
        WHEN s.LeadsCupom > 0 THEN ROUND(s.Investimento / s.LeadsCupom, 2)
        ELSE NULL
    END AS custo_por_lead,

    CASE
        WHEN s.Cliques > 0 THEN ROUND((s.LeadsCupom * 1.0) / s.Cliques, 4)
        ELSE NULL
    END AS taxa_lead_clique,

    CASE
        WHEN s.Cupom IS NULL OR TRIM(s.Cupom) = '' THEN 1
        ELSE 0
    END AS flag_sem_cupom,

    CASE
        WHEN DATE(s.DataFim) < DATE(s.DataInicio) THEN 1
        ELSE 0
    END AS flag_periodo_invalido,

    CASE
        WHEN s.Cliques > s.Impressoes THEN 1
        ELSE 0
    END AS flag_cliques_maior_impressoes

FROM stg_marketing s

LEFT JOIN dim_campanha_marketing dc
    ON dc.campanha_id_origem = TRIM(s.CampanhaID)

LEFT JOIN dim_plataforma_marketing dp
    ON dp.plataforma_marketing =
        CASE
            WHEN LOWER(TRIM(s.Plataforma)) = 'facebook ads' THEN 'Facebook Ads'
            WHEN LOWER(TRIM(s.Plataforma)) = 'google ads' THEN 'Google Ads'
            ELSE TRIM(s.Plataforma)
        END

LEFT JOIN dim_cupom dcu
    ON dcu.cupom = TRIM(s.Cupom)

LEFT JOIN dim_data ddi
    ON ddi.data = DATE(s.DataInicio)

LEFT JOIN dim_data ddf
    ON ddf.data = DATE(s.DataFim)

WHERE s.CampanhaID IS NOT NULL
  AND TRIM(s.CampanhaID) <> ''

ON CONFLICT(campanha_id_origem) DO UPDATE SET
    id_campanha_marketing = excluded.id_campanha_marketing,
    id_plataforma_marketing = excluded.id_plataforma_marketing,
    id_cupom = excluded.id_cupom,
    id_data_inicio = excluded.id_data_inicio,
    id_data_fim = excluded.id_data_fim,
    data_inicio = excluded.data_inicio,
    data_fim = excluded.data_fim,
    investimento = excluded.investimento,
    impressoes = excluded.impressoes,
    cliques = excluded.cliques,
    leads_cupom = excluded.leads_cupom,
    lift_estimado = excluded.lift_estimado,
    dias_campanha = excluded.dias_campanha,
    ctr = excluded.ctr,
    cpc = excluded.cpc,
    custo_por_lead = excluded.custo_por_lead,
    taxa_lead_clique = excluded.taxa_lead_clique,
    flag_sem_cupom = excluded.flag_sem_cupom,
    flag_periodo_invalido = excluded.flag_periodo_invalido,
    flag_cliques_maior_impressoes = excluded.flag_cliques_maior_impressoes;