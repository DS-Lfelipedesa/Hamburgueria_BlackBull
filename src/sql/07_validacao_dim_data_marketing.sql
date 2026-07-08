-- query 07 - validacao dim data marketing
-- objetivo: conferir se todas as datas da stg_marketing existem na dim_data
-- origem: stg_marketing
-- dimensao usada: dim_data
-- NOTE: nao carrega nada, so valida a cobertura das datas

WITH datas_marketing AS (

    SELECT
        DATE(DataInicio) AS data_marketing,
        'DataInicio' AS campo_origem
    FROM stg_marketing
    WHERE DataInicio IS NOT NULL

    UNION

    SELECT
        DATE(DataFim) AS data_marketing,
        'DataFim' AS campo_origem
    FROM stg_marketing
    WHERE DataFim IS NOT NULL
),

validacao AS (

    SELECT
        dm.data_marketing,
        dm.campo_origem,
        d.id_data
    FROM datas_marketing dm
    LEFT JOIN dim_data d
        ON d.data = dm.data_marketing
)

SELECT
    COUNT(*) AS total_datas_marketing,
    SUM(CASE WHEN id_data IS NULL THEN 1 ELSE 0 END) AS datas_fora_dim_data,

    CASE
        WHEN SUM(CASE WHEN id_data IS NULL THEN 1 ELSE 0 END) > 0 THEN 'erro_data_fora_dim_data'
        ELSE 'ok_dim_data_marketing'
    END AS status_validacao

FROM validacao;