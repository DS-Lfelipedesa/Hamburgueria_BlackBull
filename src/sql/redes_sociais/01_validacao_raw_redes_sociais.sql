-- =========================================================
-- QUERY 01: validacao_raw_redes_sociais
-- ORIGEM: raw_redessociais
--
-- Objetivo:
-- Dar uma olhada critica na raw antes de montar a stg.
-- Esta query NAO altera dados.
--
-- Grao esperado da raw:
-- 1 linha = 1 post/publicacao ou 1 resumo mensal consolidado.
--
-- Chave natural esperada:
-- PostID
--
-- NOTE(ai-pass): mantive varias consultas separadas porque no DBeaver
-- fica mais facil para um junior olhar um bloco por vez.
-- =========================================================


-- 1. Volume geral
SELECT
    COUNT(*) AS total_linhas_raw
FROM raw_redessociais;


-- 2. Campos nulos ou vazios
SELECT
    SUM(CASE WHEN PostID IS NULL OR TRIM(PostID) = '' THEN 1 ELSE 0 END) AS post_id_vazio,
    SUM(CASE WHEN DataHora IS NULL OR TRIM(DataHora) = '' THEN 1 ELSE 0 END) AS data_hora_vazia,
    SUM(CASE WHEN Rede IS NULL OR TRIM(Rede) = '' THEN 1 ELSE 0 END) AS rede_vazia,
    SUM(CASE WHEN TipoConteudo IS NULL OR TRIM(TipoConteudo) = '' THEN 1 ELSE 0 END) AS tipo_conteudo_vazio,
    SUM(CASE WHEN Tema IS NULL OR TRIM(Tema) = '' THEN 1 ELSE 0 END) AS tema_vazio,
    SUM(CASE WHEN Pago IS NULL OR TRIM(Pago) = '' THEN 1 ELSE 0 END) AS pago_vazio,
    SUM(CASE WHEN CampanhaID IS NULL OR TRIM(CampanhaID) = '' THEN 1 ELSE 0 END) AS campanha_id_vazia,
    SUM(CASE WHEN Alcance IS NULL THEN 1 ELSE 0 END) AS alcance_nulo,
    SUM(CASE WHEN Curtidas IS NULL THEN 1 ELSE 0 END) AS curtidas_nulo,
    SUM(CASE WHEN Comentarios IS NULL THEN 1 ELSE 0 END) AS comentarios_nulo,
    SUM(CASE WHEN Compartilhamentos IS NULL THEN 1 ELSE 0 END) AS compartilhamentos_nulo,
    SUM(CASE WHEN Cliques IS NULL THEN 1 ELSE 0 END) AS cliques_nulo
FROM raw_redessociais;


-- 3. Verifica duplicidade de PostID
SELECT
    PostID,
    COUNT(*) AS qtd_ocorrencias
FROM raw_redessociais
GROUP BY PostID
HAVING COUNT(*) > 1
ORDER BY qtd_ocorrencias DESC;


-- 4. Formatos de data encontrados
SELECT
    CASE
        WHEN DataHora LIKE '____-__-__%' THEN 'iso_like'
        WHEN DataHora LIKE '__/__/____%' THEN 'br_like'
        WHEN DataHora IS NULL OR TRIM(DataHora) = '' THEN 'vazio'
        ELSE 'outro'
    END AS formato_data,
    COUNT(*) AS qtd_linhas,
    MIN(DataHora) AS menor_data_texto,
    MAX(DataHora) AS maior_data_texto
FROM raw_redessociais
GROUP BY
    CASE
        WHEN DataHora LIKE '____-__-__%' THEN 'iso_like'
        WHEN DataHora LIKE '__/__/____%' THEN 'br_like'
        WHEN DataHora IS NULL OR TRIM(DataHora) = '' THEN 'vazio'
        ELSE 'outro'
    END
ORDER BY qtd_linhas DESC;


-- 5. Valores de Rede antes da padronizacao
SELECT
    Rede,
    COUNT(*) AS qtd_linhas
FROM raw_redessociais
GROUP BY Rede
ORDER BY qtd_linhas DESC;


-- 6. Valores de TipoConteudo antes da padronizacao
SELECT
    TipoConteudo,
    COUNT(*) AS qtd_linhas
FROM raw_redessociais
GROUP BY TipoConteudo
ORDER BY qtd_linhas DESC;


-- 7. Valores de Tema antes da padronizacao
SELECT
    Tema,
    COUNT(*) AS qtd_linhas
FROM raw_redessociais
GROUP BY Tema
ORDER BY qtd_linhas DESC;


-- 8. Valores de Pago antes da padronizacao
SELECT
    Pago,
    COUNT(*) AS qtd_linhas
FROM raw_redessociais
GROUP BY Pago
ORDER BY qtd_linhas DESC;


-- 9. Numericos negativos ou incoerentes
SELECT
    SUM(CASE WHEN Alcance < 0 THEN 1 ELSE 0 END) AS alcance_negativo,
    SUM(CASE WHEN Curtidas < 0 THEN 1 ELSE 0 END) AS curtidas_negativo,
    SUM(CASE WHEN Comentarios < 0 THEN 1 ELSE 0 END) AS comentarios_negativo,
    SUM(CASE WHEN Compartilhamentos < 0 THEN 1 ELSE 0 END) AS compartilhamentos_negativo,
    SUM(CASE WHEN Cliques < 0 THEN 1 ELSE 0 END) AS cliques_negativo,
    SUM(CASE WHEN Curtidas > Alcance THEN 1 ELSE 0 END) AS curtidas_maior_alcance,
    SUM(CASE WHEN Comentarios > Alcance THEN 1 ELSE 0 END) AS comentarios_maior_alcance,
    SUM(CASE WHEN Compartilhamentos > Alcance THEN 1 ELSE 0 END) AS compartilhamentos_maior_alcance,
    SUM(CASE WHEN Cliques > Alcance THEN 1 ELSE 0 END) AS cliques_maior_alcance
FROM raw_redessociais;


-- 10. Campanhas de redes sociais que nao aparecem no modelo de marketing
-- Se retornar linhas, pode haver campanha digitada errado ou marketing ainda nao carregado.
SELECT
    r.CampanhaID,
    COUNT(*) AS qtd_posts
FROM raw_redessociais r
LEFT JOIN dim_campanha_marketing dcm
    ON dcm.campanha_id_origem = TRIM(r.CampanhaID)
WHERE r.CampanhaID IS NOT NULL
  AND TRIM(r.CampanhaID) <> ''
  AND dcm.id_campanha_marketing IS NULL
GROUP BY r.CampanhaID
ORDER BY qtd_posts DESC;

