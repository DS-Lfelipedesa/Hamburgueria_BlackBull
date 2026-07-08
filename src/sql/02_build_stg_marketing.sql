-- query 02 - carga stg marketing
-- objetivo: levar a raw_marketing pra stg_marketing com uma limpeza basica
-- depende da query 01 retornar ok_para_build ou ok_com_aviso_sem_cupom
-- NOTE: esta query apaga e recarrega a stg_marketing

BEGIN TRANSACTION;

DELETE FROM stg_marketing;

INSERT INTO stg_marketing (
    CampanhaID,
    DataInicio,
    DataFim,
    NomeCampanha,
    Plataforma,
    Objetivo,
    Investimento,
    Impressoes,
    Cliques,
    LeadsCupom,
    Cupom,
    LiftEstimado
)
SELECT
    TRIM(CampanhaID) AS CampanhaID,

    DATE(DataInicio) AS DataInicio,
    DATE(DataFim) AS DataFim,

    TRIM(NomeCampanha) AS NomeCampanha,

    -- padronizacao simples vista na raw:
    -- Facebook ADS / Facebook Ads, Google ADS / Google Ads
    CASE
        WHEN LOWER(TRIM(Plataforma)) = 'facebook ads' THEN 'Facebook Ads'
        WHEN LOWER(TRIM(Plataforma)) = 'google ads' THEN 'Google Ads'
        ELSE TRIM(Plataforma)
    END AS Plataforma,

    TRIM(Objetivo) AS Objetivo,

    Investimento,
    Impressoes,
    Cliques,
    LeadsCupom,

    -- cupom tem nulo na raw, entao mantem nulo mesmo
    -- TODO: confirmar se campanha sem cupom deve virar 'SEM_CUPOM' ou ficar NULL
    NULLIF(TRIM(Cupom), '') AS Cupom,

    LiftEstimado

FROM raw_marketing;

COMMIT;