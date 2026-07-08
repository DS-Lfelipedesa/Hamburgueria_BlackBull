-- =========================================================
-- QUERY 03: validacao_stg_redes_sociais
-- ORIGEM: stg_redes_sociais
--
-- Objetivo:
-- Validar a staging antes de criar dimensoes e fato.
-- Esta query NAO altera dados.
-- =========================================================


-- 1. Volume raw x stg
SELECT
    'raw_redessociais' AS tabela,
    COUNT(*) AS total_linhas
FROM raw_redessociais

UNION ALL

SELECT
    'stg_redes_sociais' AS tabela,
    COUNT(*) AS total_linhas
FROM stg_redes_sociais;


-- 2. Flags principais da stg
SELECT
    COUNT(*) AS total_linhas_stg,
    SUM(flag_post_id_invalido) AS post_id_invalido,
    SUM(flag_data_invalida) AS datas_invalidas,
    SUM(flag_metricas_invalidas) AS metricas_invalidas,
    SUM(flag_campanha_com_pago_vazio) AS campanha_com_pago_vazio
FROM stg_redes_sociais;


-- 3. Duplicidade de chave natural
SELECT
    post_id,
    COUNT(*) AS qtd_ocorrencias
FROM stg_redes_sociais
GROUP BY post_id
HAVING COUNT(*) > 1
ORDER BY qtd_ocorrencias DESC;


-- 4. Distribuicao por rede
SELECT
    rede_social,
    COUNT(*) AS qtd_posts,
    SUM(alcance) AS total_alcance,
    SUM(engajamentos) AS total_engajamentos,
    SUM(cliques) AS total_cliques
FROM stg_redes_sociais
GROUP BY rede_social
ORDER BY qtd_posts DESC;


-- 5. Distribuicao por tipo de conteudo
SELECT
    tipo_conteudo,
    COUNT(*) AS qtd_posts,
    SUM(alcance) AS total_alcance,
    ROUND(AVG(taxa_engajamento), 4) AS media_taxa_engajamento
FROM stg_redes_sociais
GROUP BY tipo_conteudo
ORDER BY qtd_posts DESC;


-- 6. Distribuicao por tema
SELECT
    tema_conteudo,
    COUNT(*) AS qtd_posts,
    SUM(alcance) AS total_alcance,
    ROUND(AVG(taxa_engajamento), 4) AS media_taxa_engajamento
FROM stg_redes_sociais
GROUP BY tema_conteudo
ORDER BY qtd_posts DESC;


-- 7. Distribuicao por pago
SELECT
    pago,
    flag_post_pago,
    COUNT(*) AS qtd_posts
FROM stg_redes_sociais
GROUP BY
    pago,
    flag_post_pago
ORDER BY qtd_posts DESC;


-- 8. Campanha preenchida sem correspondencia na dimensao de marketing
-- Se dim_campanha_marketing ainda nao existir, esta consulta vai falhar.
-- Isso e aceitavel por enquanto, porque a ordem do orquestrador ainda sera criada.
SELECT
    s.campanha_id,
    COUNT(*) AS qtd_posts
FROM stg_redes_sociais s
LEFT JOIN dim_campanha_marketing dcm
    ON dcm.campanha_id_origem = s.campanha_id
WHERE s.campanha_id IS NOT NULL
  AND dcm.id_campanha_marketing IS NULL
GROUP BY s.campanha_id
ORDER BY qtd_posts DESC;


-- 9. Status resumido para bater o olho
WITH resumo AS (
    SELECT
        (SELECT COUNT(*) FROM raw_redessociais) AS total_raw,
        COUNT(*) AS total_stg,
        SUM(flag_post_id_invalido) AS post_id_invalido,
        SUM(flag_data_invalida) AS datas_invalidas,
        SUM(flag_metricas_invalidas) AS metricas_invalidas,
        (
            SELECT COUNT(*)
            FROM (
                SELECT post_id
                FROM stg_redes_sociais
                GROUP BY post_id
                HAVING COUNT(*) > 1
            )
        ) AS post_id_duplicado
    FROM stg_redes_sociais
)
SELECT
    *,
    CASE
        WHEN total_stg = 0 THEN 'erro_stg_vazia'
        WHEN total_raw <> total_stg THEN 'erro_qtd_raw_stg_diferente'
        WHEN post_id_invalido > 0 THEN 'erro_post_id_invalido'
        WHEN post_id_duplicado > 0 THEN 'erro_post_id_duplicado'
        WHEN datas_invalidas > 0 THEN 'erro_data_invalida'
        WHEN metricas_invalidas > 0 THEN 'erro_metricas_invalidas'
        ELSE 'ok_para_dim_e_fato'
    END AS status_validacao
FROM resumo;

