-- query 03 - validacao stg marketing
-- objetivo: validar se a stg_marketing esta pronta para alimentar dims e fato
-- origem de comparacao: raw_marketing
-- NOTE: nao grava nada, so valida

WITH contagem AS (

    SELECT
        (SELECT COUNT(*) FROM raw_marketing) AS total_raw,
        (SELECT COUNT(*) FROM stg_marketing) AS total_stg
),

validacao_stg AS (

    SELECT
        COUNT(*) AS total_linhas_stg,

        SUM(CASE WHEN CampanhaID IS NULL OR TRIM(CampanhaID) = '' THEN 1 ELSE 0 END) AS sem_campanha_id,
        SUM(CASE WHEN DataInicio IS NULL OR TRIM(DataInicio) = '' THEN 1 ELSE 0 END) AS sem_data_inicio,
        SUM(CASE WHEN DataFim IS NULL OR TRIM(DataFim) = '' THEN 1 ELSE 0 END) AS sem_data_fim,
        SUM(CASE WHEN NomeCampanha IS NULL OR TRIM(NomeCampanha) = '' THEN 1 ELSE 0 END) AS sem_nome_campanha,
        SUM(CASE WHEN Plataforma IS NULL OR TRIM(Plataforma) = '' THEN 1 ELSE 0 END) AS sem_plataforma,
        SUM(CASE WHEN Objetivo IS NULL OR TRIM(Objetivo) = '' THEN 1 ELSE 0 END) AS sem_objetivo,

        SUM(CASE WHEN Investimento IS NULL THEN 1 ELSE 0 END) AS sem_investimento,
        SUM(CASE WHEN Impressoes IS NULL THEN 1 ELSE 0 END) AS sem_impressoes,
        SUM(CASE WHEN Cliques IS NULL THEN 1 ELSE 0 END) AS sem_cliques,
        SUM(CASE WHEN LeadsCupom IS NULL THEN 1 ELSE 0 END) AS sem_leads_cupom,
        SUM(CASE WHEN LiftEstimado IS NULL THEN 1 ELSE 0 END) AS sem_lift_estimado,

        -- cupom pode estar vazio, entao fica como aviso
        SUM(CASE WHEN Cupom IS NULL OR TRIM(Cupom) = '' THEN 1 ELSE 0 END) AS sem_cupom,

        SUM(CASE WHEN DATE(DataInicio) IS NULL THEN 1 ELSE 0 END) AS data_inicio_invalida,
        SUM(CASE WHEN DATE(DataFim) IS NULL THEN 1 ELSE 0 END) AS data_fim_invalida,
        SUM(CASE WHEN DATE(DataFim) < DATE(DataInicio) THEN 1 ELSE 0 END) AS periodo_invalido,

        SUM(CASE WHEN Investimento < 0 THEN 1 ELSE 0 END) AS investimento_negativo,
        SUM(CASE WHEN Impressoes < 0 THEN 1 ELSE 0 END) AS impressoes_negativas,
        SUM(CASE WHEN Cliques < 0 THEN 1 ELSE 0 END) AS cliques_negativos,
        SUM(CASE WHEN LeadsCupom < 0 THEN 1 ELSE 0 END) AS leads_cupom_negativos,

        SUM(CASE WHEN Cliques > Impressoes THEN 1 ELSE 0 END) AS cliques_maior_impressoes,

        -- esperado depois da fase 02: nao sobrar Facebook ADS / Google ADS
        SUM(CASE WHEN Plataforma IN ('Facebook ADS', 'Google ADS') THEN 1 ELSE 0 END) AS plataforma_nao_padronizada

    FROM stg_marketing
),

duplicados AS (

    SELECT
        COUNT(*) AS campanhas_duplicadas
    FROM (
        SELECT CampanhaID
        FROM stg_marketing
        GROUP BY CampanhaID
        HAVING COUNT(*) > 1
    )
)

SELECT
    c.total_raw,
    c.total_stg,

    v.sem_campanha_id,
    v.sem_data_inicio,
    v.sem_data_fim,
    v.sem_nome_campanha,
    v.sem_plataforma,
    v.sem_objetivo,

    v.sem_investimento,
    v.sem_impressoes,
    v.sem_cliques,
    v.sem_leads_cupom,
    v.sem_lift_estimado,
    v.sem_cupom,

    v.data_inicio_invalida,
    v.data_fim_invalida,
    v.periodo_invalido,

    v.investimento_negativo,
    v.impressoes_negativas,
    v.cliques_negativos,
    v.leads_cupom_negativos,
    v.cliques_maior_impressoes,

    v.plataforma_nao_padronizada,
    d.campanhas_duplicadas,

    CASE
        WHEN c.total_stg = 0 THEN 'erro_stg_vazia'
        WHEN c.total_raw <> c.total_stg THEN 'erro_qtd_raw_stg_diferente'

        WHEN v.sem_campanha_id > 0 THEN 'erro_sem_campanha_id'
        WHEN v.sem_data_inicio > 0 THEN 'erro_sem_data_inicio'
        WHEN v.sem_data_fim > 0 THEN 'erro_sem_data_fim'
        WHEN v.sem_nome_campanha > 0 THEN 'erro_sem_nome_campanha'
        WHEN v.sem_plataforma > 0 THEN 'erro_sem_plataforma'
        WHEN v.sem_objetivo > 0 THEN 'erro_sem_objetivo'

        WHEN v.sem_investimento > 0 THEN 'erro_sem_investimento'
        WHEN v.sem_impressoes > 0 THEN 'erro_sem_impressoes'
        WHEN v.sem_cliques > 0 THEN 'erro_sem_cliques'
        WHEN v.sem_leads_cupom > 0 THEN 'erro_sem_leads_cupom'
        WHEN v.sem_lift_estimado > 0 THEN 'erro_sem_lift_estimado'

        WHEN v.data_inicio_invalida > 0 THEN 'erro_data_inicio_invalida'
        WHEN v.data_fim_invalida > 0 THEN 'erro_data_fim_invalida'
        WHEN v.periodo_invalido > 0 THEN 'erro_periodo_invalido'

        WHEN v.investimento_negativo > 0 THEN 'erro_investimento_negativo'
        WHEN v.impressoes_negativas > 0 THEN 'erro_impressoes_negativas'
        WHEN v.cliques_negativos > 0 THEN 'erro_cliques_negativos'
        WHEN v.leads_cupom_negativos > 0 THEN 'erro_leads_cupom_negativos'
        WHEN v.cliques_maior_impressoes > 0 THEN 'erro_cliques_maior_impressoes'

        WHEN d.campanhas_duplicadas > 0 THEN 'erro_campanha_duplicada'

        WHEN v.plataforma_nao_padronizada > 0 THEN 'aviso_plataforma_nao_padronizada'
        WHEN v.sem_cupom > 0 THEN 'ok_com_aviso_sem_cupom'

        ELSE 'ok_para_dim_e_fato'
    END AS status_validacao

FROM contagem c
CROSS JOIN validacao_stg v
CROSS JOIN duplicados d;