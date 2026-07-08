-- query 02 - carga stg marketing
-- objetivo: levar a raw_marketing pra stg_marketing com limpeza basica
-- NOTE: agora recria a tabela, assim o projeto consegue rodar do zero.
-- NOTE(ai-pass): datas DD/MM/YYYY HH:MM sao normalizadas aqui.

DROP TABLE IF EXISTS stg_marketing;

CREATE TABLE stg_marketing AS
WITH base AS (
    SELECT
        TRIM(CampanhaID) AS CampanhaID,
        TRIM(DataInicio) AS data_inicio_original,
        TRIM(DataFim) AS data_fim_original,
        TRIM(NomeCampanha) AS NomeCampanha,
        TRIM(Plataforma) AS Plataforma,
        TRIM(Objetivo) AS Objetivo,
        Investimento,
        Impressoes,
        Cliques,
        LeadsCupom,
        NULLIF(TRIM(Cupom), '') AS Cupom,
        LiftEstimado
    FROM raw_marketing
),

datas AS (
    SELECT
        *,
        CASE
            WHEN data_inicio_original LIKE '____-__-__%' THEN date(data_inicio_original)
            WHEN data_inicio_original LIKE '__/__/____%' THEN date(
                SUBSTR(data_inicio_original, 7, 4) || '-' ||
                SUBSTR(data_inicio_original, 4, 2) || '-' ||
                SUBSTR(data_inicio_original, 1, 2)
            )
            ELSE NULL
        END AS DataInicio,

        CASE
            WHEN data_fim_original LIKE '____-__-__%' THEN date(data_fim_original)
            WHEN data_fim_original LIKE '__/__/____%' THEN date(
                SUBSTR(data_fim_original, 7, 4) || '-' ||
                SUBSTR(data_fim_original, 4, 2) || '-' ||
                SUBSTR(data_fim_original, 1, 2)
            )
            ELSE NULL
        END AS DataFim
    FROM base
)

SELECT
    CampanhaID,
    DataInicio,
    DataFim,
    NomeCampanha,

    CASE
        WHEN LOWER(TRIM(Plataforma)) = 'facebook ads' THEN 'Facebook Ads'
        WHEN LOWER(TRIM(Plataforma)) = 'google ads' THEN 'Google Ads'
        ELSE TRIM(Plataforma)
    END AS Plataforma,

    Objetivo,
    Investimento,
    Impressoes,
    Cliques,
    LeadsCupom,

    -- TODO: confirmar se campanha sem cupom deve virar 'Sem Cupom'
    -- ou continuar NULL. Por enquanto mantem NULL para diferenciar aviso.
    Cupom,

    LiftEstimado,
    data_inicio_original,
    data_fim_original

FROM datas;

