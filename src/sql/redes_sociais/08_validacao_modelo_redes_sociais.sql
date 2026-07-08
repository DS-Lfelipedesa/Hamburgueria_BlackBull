-- =========================================================
-- QUERY 08: validacao_modelo_redes_sociais
-- ORIGEM: stg_redes_sociais, fato_redes_sociais e dimensoes
--
-- Objetivo:
-- Verificar se a fato de redes sociais ficou consistente para Power BI.
-- Esta query NAO altera dados.
-- =========================================================


-- 1. Comparar volume e totais stg valida x fato
SELECT
    'stg_redes_sociais_valida' AS origem,
    COUNT(*) AS qtd_linhas,
    SUM(alcance) AS total_alcance,
    SUM(curtidas) AS total_curtidas,
    SUM(comentarios) AS total_comentarios,
    SUM(compartilhamentos) AS total_compartilhamentos,
    SUM(cliques) AS total_cliques,
    SUM(engajamentos) AS total_engajamentos
FROM stg_redes_sociais
WHERE flag_post_id_invalido = 0
  AND flag_data_invalida = 0
  AND flag_metricas_invalidas = 0

UNION ALL

SELECT
    'fato_redes_sociais' AS origem,
    COUNT(*) AS qtd_linhas,
    SUM(alcance) AS total_alcance,
    SUM(curtidas) AS total_curtidas,
    SUM(comentarios) AS total_comentarios,
    SUM(compartilhamentos) AS total_compartilhamentos,
    SUM(cliques) AS total_cliques,
    SUM(engajamentos) AS total_engajamentos
FROM fato_redes_sociais;


-- 2. Duplicidade na fato
SELECT
    post_id,
    COUNT(*) AS qtd_ocorrencias
FROM fato_redes_sociais
GROUP BY post_id
HAVING COUNT(*) > 1;


-- 3. Chaves dimensionais ausentes
SELECT
    SUM(CASE WHEN id_data IS NULL THEN 1 ELSE 0 END) AS sem_dim_data,
    SUM(CASE WHEN id_rede_social IS NULL THEN 1 ELSE 0 END) AS sem_dim_rede_social,
    SUM(CASE WHEN id_tipo_conteudo IS NULL THEN 1 ELSE 0 END) AS sem_dim_tipo_conteudo,
    SUM(CASE WHEN id_tema_conteudo IS NULL THEN 1 ELSE 0 END) AS sem_dim_tema_conteudo,
    SUM(CASE WHEN campanha_id IS NOT NULL AND id_campanha_marketing IS NULL THEN 1 ELSE 0 END) AS campanha_sem_dim_marketing
FROM fato_redes_sociais;


-- 4. Linhas detalhadas com problemas de dimensao
SELECT
    post_id,
    data_postagem,
    campanha_id,
    id_data,
    id_rede_social,
    id_tipo_conteudo,
    id_tema_conteudo,
    id_campanha_marketing
FROM fato_redes_sociais
WHERE id_data IS NULL
   OR id_rede_social IS NULL
   OR id_tipo_conteudo IS NULL
   OR id_tema_conteudo IS NULL
   OR (campanha_id IS NOT NULL AND id_campanha_marketing IS NULL)
LIMIT 100;


-- 5. Resultado por rede social
SELECT
    drs.rede_social,
    COUNT(*) AS qtd_posts,
    SUM(f.alcance) AS total_alcance,
    SUM(f.engajamentos) AS total_engajamentos,
    SUM(f.cliques) AS total_cliques,
    ROUND(AVG(f.taxa_engajamento), 4) AS media_taxa_engajamento,
    ROUND(AVG(f.taxa_clique), 4) AS media_taxa_clique
FROM fato_redes_sociais f
LEFT JOIN dim_rede_social drs
    ON drs.id_rede_social = f.id_rede_social
GROUP BY drs.rede_social
ORDER BY total_alcance DESC;


-- 6. Resultado por tipo de conteudo
SELECT
    dtc.tipo_conteudo,
    COUNT(*) AS qtd_posts,
    SUM(f.alcance) AS total_alcance,
    SUM(f.engajamentos) AS total_engajamentos,
    ROUND(AVG(f.taxa_engajamento), 4) AS media_taxa_engajamento
FROM fato_redes_sociais f
LEFT JOIN dim_tipo_conteudo dtc
    ON dtc.id_tipo_conteudo = f.id_tipo_conteudo
GROUP BY dtc.tipo_conteudo
ORDER BY total_alcance DESC;


-- 7. Resultado por tema
SELECT
    dtema.tema_conteudo,
    COUNT(*) AS qtd_posts,
    SUM(f.alcance) AS total_alcance,
    SUM(f.engajamentos) AS total_engajamentos,
    ROUND(AVG(f.taxa_engajamento), 4) AS media_taxa_engajamento
FROM fato_redes_sociais f
LEFT JOIN dim_tema_conteudo dtema
    ON dtema.id_tema_conteudo = f.id_tema_conteudo
GROUP BY dtema.tema_conteudo
ORDER BY total_alcance DESC;


-- 8. Posts pagos x organicos
SELECT
    pago,
    flag_post_pago,
    COUNT(*) AS qtd_posts,
    SUM(alcance) AS total_alcance,
    SUM(cliques) AS total_cliques,
    SUM(engajamentos) AS total_engajamentos
FROM fato_redes_sociais
GROUP BY
    pago,
    flag_post_pago
ORDER BY qtd_posts DESC;


-- 9. Status final resumido
WITH checks AS (
    SELECT
        (SELECT COUNT(*)
         FROM stg_redes_sociais
         WHERE flag_post_id_invalido = 0
           AND flag_data_invalida = 0
           AND flag_metricas_invalidas = 0) AS qtd_stg_valida,

        (SELECT COUNT(*)
         FROM fato_redes_sociais) AS qtd_fato,

        (SELECT COUNT(*)
         FROM (
             SELECT post_id
             FROM fato_redes_sociais
             GROUP BY post_id
             HAVING COUNT(*) > 1
         )) AS qtd_post_id_duplicado,

        (SELECT COUNT(*)
         FROM fato_redes_sociais
         WHERE id_data IS NULL
            OR id_rede_social IS NULL
            OR id_tipo_conteudo IS NULL
            OR id_tema_conteudo IS NULL
            OR (campanha_id IS NOT NULL AND id_campanha_marketing IS NULL)) AS qtd_dimensao_ausente
)
SELECT
    *,
    CASE
        WHEN qtd_fato = 0 THEN 'erro_fato_vazia'
        WHEN qtd_stg_valida <> qtd_fato THEN 'erro_qtd_stg_fato_diferente'
        WHEN qtd_post_id_duplicado > 0 THEN 'erro_post_id_duplicado'
        WHEN qtd_dimensao_ausente > 0 THEN 'erro_dimensao_ausente'
        ELSE 'ok_modelo_redes_sociais'
    END AS status_validacao
FROM checks;

