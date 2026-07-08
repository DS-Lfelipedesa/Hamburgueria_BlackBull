-- query 01 - validacao raw marketing
-- objetivo: ver se a raw_marketing pode seguir pra build
-- tabela base: raw_marketing
-- NOTE: nao grava nada no banco, so valida

SELECT
    COUNT(*) AS total_linhas,

    -- campos principais
    SUM(CASE WHEN CampanhaID IS NULL OR TRIM(CampanhaID) = '' THEN 1 ELSE 0 END) AS sem_campanha_id,
    SUM(CASE WHEN DataInicio IS NULL OR TRIM(DataInicio) = '' THEN 1 ELSE 0 END) AS sem_data_inicio,
    SUM(CASE WHEN DataFim IS NULL OR TRIM(DataFim) = '' THEN 1 ELSE 0 END) AS sem_data_fim,
    SUM(CASE WHEN NomeCampanha IS NULL OR TRIM(NomeCampanha) = '' THEN 1 ELSE 0 END) AS sem_nome_campanha,
    SUM(CASE WHEN Plataforma IS NULL OR TRIM(Plataforma) = '' THEN 1 ELSE 0 END) AS sem_plataforma,
    SUM(CASE WHEN Objetivo IS NULL OR TRIM(Objetivo) = '' THEN 1 ELSE 0 END) AS sem_objetivo,

    -- metricas
    SUM(CASE WHEN Investimento IS NULL THEN 1 ELSE 0 END) AS sem_investimento,
    SUM(CASE WHEN Impressoes IS NULL THEN 1 ELSE 0 END) AS sem_impressoes,
    SUM(CASE WHEN Cliques IS NULL THEN 1 ELSE 0 END) AS sem_cliques,
    SUM(CASE WHEN LeadsCupom IS NULL THEN 1 ELSE 0 END) AS sem_leads_cupom,
    SUM(CASE WHEN LiftEstimado IS NULL THEN 1 ELSE 0 END) AS sem_lift_estimado,

    -- cupom pode ser nulo, entao deixei como aviso e nao erro
    SUM(CASE WHEN Cupom IS NULL OR TRIM(Cupom) = '' THEN 1 ELSE 0 END) AS sem_cupom,

    -- validacoes de datas e numeros
    SUM(CASE WHEN DATE(DataInicio) IS NULL THEN 1 ELSE 0 END) AS data_inicio_invalida,
    SUM(CASE WHEN DATE(DataFim) IS NULL THEN 1 ELSE 0 END) AS data_fim_invalida,
    SUM(CASE WHEN DATE(DataFim) < DATE(DataInicio) THEN 1 ELSE 0 END) AS data_fim_menor_inicio,

    SUM(CASE WHEN Investimento < 0 THEN 1 ELSE 0 END) AS investimento_negativo,
    SUM(CASE WHEN Impressoes < 0 THEN 1 ELSE 0 END) AS impressoes_negativas,
    SUM(CASE WHEN Cliques < 0 THEN 1 ELSE 0 END) AS cliques_negativos,
    SUM(CASE WHEN LeadsCupom < 0 THEN 1 ELSE 0 END) AS leads_cupom_negativos,

    SUM(CASE WHEN Cliques > Impressoes THEN 1 ELSE 0 END) AS cliques_maior_que_impressoes,

    -- status geral pra decidir se segue pra build
    CASE
        WHEN COUNT(*) = 0 THEN 'erro_raw_vazia'

        WHEN SUM(CASE WHEN CampanhaID IS NULL OR TRIM(CampanhaID) = '' THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_campanha_id'
        WHEN SUM(CASE WHEN DataInicio IS NULL OR TRIM(DataInicio) = '' THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_data_inicio'
        WHEN SUM(CASE WHEN DataFim IS NULL OR TRIM(DataFim) = '' THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_data_fim'
        WHEN SUM(CASE WHEN NomeCampanha IS NULL OR TRIM(NomeCampanha) = '' THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_nome_campanha'
        WHEN SUM(CASE WHEN Plataforma IS NULL OR TRIM(Plataforma) = '' THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_plataforma'
        WHEN SUM(CASE WHEN Objetivo IS NULL OR TRIM(Objetivo) = '' THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_objetivo'

        WHEN SUM(CASE WHEN Investimento IS NULL THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_investimento'
        WHEN SUM(CASE WHEN Impressoes IS NULL THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_impressoes'
        WHEN SUM(CASE WHEN Cliques IS NULL THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_cliques'
        WHEN SUM(CASE WHEN LeadsCupom IS NULL THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_leads_cupom'
        WHEN SUM(CASE WHEN LiftEstimado IS NULL THEN 1 ELSE 0 END) > 0 THEN 'erro_sem_lift_estimado'

        WHEN SUM(CASE WHEN DATE(DataInicio) IS NULL THEN 1 ELSE 0 END) > 0 THEN 'erro_data_inicio_invalida'
        WHEN SUM(CASE WHEN DATE(DataFim) IS NULL THEN 1 ELSE 0 END) > 0 THEN 'erro_data_fim_invalida'
        WHEN SUM(CASE WHEN DATE(DataFim) < DATE(DataInicio) THEN 1 ELSE 0 END) > 0 THEN 'erro_periodo_campanha_invalido'

        WHEN SUM(CASE WHEN Investimento < 0 THEN 1 ELSE 0 END) > 0 THEN 'erro_investimento_negativo'
        WHEN SUM(CASE WHEN Impressoes < 0 THEN 1 ELSE 0 END) > 0 THEN 'erro_impressoes_negativas'
        WHEN SUM(CASE WHEN Cliques < 0 THEN 1 ELSE 0 END) > 0 THEN 'erro_cliques_negativos'
        WHEN SUM(CASE WHEN LeadsCupom < 0 THEN 1 ELSE 0 END) > 0 THEN 'erro_leads_cupom_negativos'

        WHEN SUM(CASE WHEN Cliques > Impressoes THEN 1 ELSE 0 END) > 0 THEN 'erro_cliques_maior_que_impressoes'

        WHEN SUM(CASE WHEN Cupom IS NULL OR TRIM(Cupom) = '' THEN 1 ELSE 0 END) > 0 THEN 'ok_com_aviso_sem_cupom'

        ELSE 'ok_para_build'
    END AS status_validacao

FROM raw_marketing;