-- query 09 - validacao modelo marketing
-- objetivo: validar se a fato_marketing ficou consistente com stg e dims
-- origem: stg_marketing
-- fato: fato_marketing
-- NOTE: nao grava nada, so valida o modelo final

WITH contagem AS (

    SELECT
        (SELECT COUNT(*) FROM stg_marketing) AS total_stg,
        (SELECT COUNT(*) FROM fato_marketing) AS total_fato
),

duplicados AS (

    SELECT
        COUNT(*) AS campanhas_duplicadas
    FROM (
        SELECT
            campanha_id_origem
        FROM fato_marketing
        GROUP BY campanha_id_origem
        HAVING COUNT(*) > 1
    )
),

checks_fato AS (

    SELECT
        SUM(CASE WHEN campanha_id_origem IS NULL OR TRIM(campanha_id_origem) = '' THEN 1 ELSE 0 END) AS sem_campanha_id_origem,

        SUM(CASE WHEN id_campanha_marketing IS NULL THEN 1 ELSE 0 END) AS sem_dim_campanha,
        SUM(CASE WHEN id_plataforma_marketing IS NULL THEN 1 ELSE 0 END) AS sem_dim_plataforma,
        SUM(CASE WHEN id_data_inicio IS NULL THEN 1 ELSE 0 END) AS sem_dim_data_inicio,
        SUM(CASE WHEN id_data_fim IS NULL THEN 1 ELSE 0 END) AS sem_dim_data_fim,

        -- cupom pode ser nulo quando a campanha veio sem cupom
        SUM(CASE WHEN id_cupom IS NULL AND flag_sem_cupom = 0 THEN 1 ELSE 0 END) AS sem_dim_cupom_indevido,

        SUM(CASE WHEN investimento IS NULL THEN 1 ELSE 0 END) AS sem_investimento,
        SUM(CASE WHEN impressoes IS NULL THEN 1 ELSE 0 END) AS sem_impressoes,
        SUM(CASE WHEN cliques IS NULL THEN 1 ELSE 0 END) AS sem_cliques,
        SUM(CASE WHEN leads_cupom IS NULL THEN 1 ELSE 0 END) AS sem_leads_cupom,

        SUM(CASE WHEN investimento < 0 THEN 1 ELSE 0 END) AS investimento_negativo,
        SUM(CASE WHEN impressoes < 0 THEN 1 ELSE 0 END) AS impressoes_negativas,
        SUM(CASE WHEN cliques < 0 THEN 1 ELSE 0 END) AS cliques_negativos,
        SUM(CASE WHEN leads_cupom < 0 THEN 1 ELSE 0 END) AS leads_cupom_negativos,

        SUM(CASE WHEN flag_periodo_invalido = 1 THEN 1 ELSE 0 END) AS qtd_periodo_invalido,
        SUM(CASE WHEN flag_cliques_maior_impressoes = 1 THEN 1 ELSE 0 END) AS qtd_cliques_maior_impressoes,
        SUM(CASE WHEN flag_sem_cupom = 1 THEN 1 ELSE 0 END) AS qtd_sem_cupom

    FROM fato_marketing
),

stg_fora_fato AS (

    SELECT
        COUNT(*) AS campanhas_stg_fora_fato
    FROM stg_marketing s
    LEFT JOIN fato_marketing f
        ON f.campanha_id_origem = TRIM(s.CampanhaID)
    WHERE f.id_fato_marketing IS NULL
)

SELECT
    c.total_stg,
    c.total_fato,

    d.campanhas_duplicadas,
    sf.campanhas_stg_fora_fato,

    cf.sem_campanha_id_origem,
    cf.sem_dim_campanha,
    cf.sem_dim_plataforma,
    cf.sem_dim_data_inicio,
    cf.sem_dim_data_fim,
    cf.sem_dim_cupom_indevido,

    cf.sem_investimento,
    cf.sem_impressoes,
    cf.sem_cliques,
    cf.sem_leads_cupom,

    cf.investimento_negativo,
    cf.impressoes_negativas,
    cf.cliques_negativos,
    cf.leads_cupom_negativos,

    cf.qtd_periodo_invalido,
    cf.qtd_cliques_maior_impressoes,
    cf.qtd_sem_cupom,

    CASE
        WHEN c.total_fato = 0 THEN 'erro_fato_vazia'
        WHEN c.total_stg <> c.total_fato THEN 'erro_qtd_stg_fato_diferente'
        WHEN d.campanhas_duplicadas > 0 THEN 'erro_campanha_duplicada_fato'
        WHEN sf.campanhas_stg_fora_fato > 0 THEN 'erro_stg_fora_fato'

        WHEN cf.sem_campanha_id_origem > 0 THEN 'erro_sem_campanha_id_origem'
        WHEN cf.sem_dim_campanha > 0 THEN 'erro_sem_dim_campanha'
        WHEN cf.sem_dim_plataforma > 0 THEN 'erro_sem_dim_plataforma'
        WHEN cf.sem_dim_data_inicio > 0 THEN 'erro_sem_dim_data_inicio'
        WHEN cf.sem_dim_data_fim > 0 THEN 'erro_sem_dim_data_fim'
        WHEN cf.sem_dim_cupom_indevido > 0 THEN 'erro_sem_dim_cupom'

        WHEN cf.sem_investimento > 0 THEN 'erro_sem_investimento'
        WHEN cf.sem_impressoes > 0 THEN 'erro_sem_impressoes'
        WHEN cf.sem_cliques > 0 THEN 'erro_sem_cliques'
        WHEN cf.sem_leads_cupom > 0 THEN 'erro_sem_leads_cupom'

        WHEN cf.investimento_negativo > 0 THEN 'erro_investimento_negativo'
        WHEN cf.impressoes_negativas > 0 THEN 'erro_impressoes_negativas'
        WHEN cf.cliques_negativos > 0 THEN 'erro_cliques_negativos'
        WHEN cf.leads_cupom_negativos > 0 THEN 'erro_leads_cupom_negativos'

        WHEN cf.qtd_periodo_invalido > 0 THEN 'erro_periodo_invalido'
        WHEN cf.qtd_cliques_maior_impressoes > 0 THEN 'erro_cliques_maior_impressoes'

        WHEN cf.qtd_sem_cupom > 0 THEN 'ok_com_aviso_sem_cupom'

        ELSE 'ok_modelo_marketing'
    END AS status_validacao

FROM contagem c
CROSS JOIN duplicados d
CROSS JOIN checks_fato cf
CROSS JOIN stg_fora_fato sf;