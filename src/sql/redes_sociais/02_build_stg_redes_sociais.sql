-- =========================================================
-- QUERY 02: build_stg_redes_sociais
-- ORIGEM: raw_redessociais
-- DESTINO: stg_redes_sociais
--
-- Grao:
-- 1 linha = 1 post/publicacao ou 1 linha consolidada mensal.
--
-- Chave natural:
-- post_id, vindo de PostID.
--
-- Regras principais:
-- 1. Padronizar nomes e remover espacos.
-- 2. Converter DataHora para ISO quando vier em DD/MM/YYYY HH:MM.
-- 3. Tratar Pago como Sim, Nao ou Nao Informado.
-- 4. Criar metricas auxiliares de engajamento.
-- 5. Criar flags de auditoria para a validacao seguinte.
--
-- TODO: se a regra de "Consolidado / Resumo Mensal" mudar,
-- talvez essa linha deva virar outra fato mensal separada.
-- =========================================================

DROP TABLE IF EXISTS stg_redes_sociais;

CREATE TABLE stg_redes_sociais AS
WITH base AS (
    SELECT
        TRIM(PostID) AS post_id,
        TRIM(DataHora) AS data_hora_original,
        TRIM(Rede) AS rede_original,
        TRIM(TipoConteudo) AS tipo_conteudo_original,
        TRIM(Tema) AS tema_original,
        TRIM(Pago) AS pago_original,
        NULLIF(TRIM(CampanhaID), '') AS campanha_id,
        Alcance,
        Curtidas,
        Comentarios,
        Compartilhamentos,
        Cliques
    FROM raw_redessociais
),

datas_tratadas AS (
    SELECT
        *,
        CASE
            WHEN data_hora_original LIKE '____-__-__%' THEN datetime(data_hora_original)
            WHEN data_hora_original LIKE '__/__/____%' THEN datetime(
                SUBSTR(data_hora_original, 7, 4) || '-' ||
                SUBSTR(data_hora_original, 4, 2) || '-' ||
                SUBSTR(data_hora_original, 1, 2) ||
                SUBSTR(data_hora_original, 11)
            )
            ELSE NULL
        END AS data_hora
    FROM base
),

textos_sem_acento AS (
    SELECT
        post_id,
        data_hora_original,
        data_hora,
        campanha_id,
        Alcance,
        Curtidas,
        Comentarios,
        Compartilhamentos,
        Cliques,

        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(rede_original,
        'á','a'),'à','a'),'ã','a'),'â','a'),'é','e'),'ê','e'),'í','i'),'ó','o'),'õ','o'),'ô','o'),'ú','u'),'ç','c'),
        'Á','A'),'Ã','A'),'É','E'),'Ç','C') AS rede_sem_acento,

        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(tipo_conteudo_original,
        'á','a'),'à','a'),'ã','a'),'â','a'),'é','e'),'ê','e'),'í','i'),'ó','o'),'õ','o'),'ô','o'),'ú','u'),'ç','c'),
        'Á','A'),'Ã','A'),'É','E'),'Ç','C') AS tipo_sem_acento,

        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(tema_original,
        'á','a'),'à','a'),'ã','a'),'â','a'),'é','e'),'ê','e'),'í','i'),'ó','o'),'õ','o'),'ô','o'),'ú','u'),'ç','c'),
        'Á','A'),'Ã','A'),'É','E'),'Ç','C') AS tema_sem_acento,

        pago_original
    FROM datas_tratadas
)

SELECT
    post_id,
    data_hora_original,
    data_hora,
    date(data_hora) AS data_postagem,
    time(data_hora) AS hora_postagem,

    CASE
        WHEN rede_sem_acento IS NULL OR TRIM(rede_sem_acento) = '' THEN 'Nao Informado'
        WHEN LOWER(TRIM(rede_sem_acento)) = 'instagram' THEN 'Instagram'
        WHEN LOWER(TRIM(rede_sem_acento)) = 'tiktok' THEN 'TikTok'
        WHEN LOWER(TRIM(rede_sem_acento)) = 'facebook' THEN 'Facebook'
        WHEN LOWER(TRIM(rede_sem_acento)) = 'consolidado' THEN 'Consolidado'
        ELSE UPPER(SUBSTR(TRIM(rede_sem_acento), 1, 1)) ||
             LOWER(SUBSTR(TRIM(rede_sem_acento), 2))
    END AS rede_social,

    CASE
        WHEN tipo_sem_acento IS NULL OR TRIM(tipo_sem_acento) = '' THEN 'Nao Informado'
        WHEN LOWER(TRIM(tipo_sem_acento)) = 'reels' THEN 'Reels'
        WHEN LOWER(TRIM(tipo_sem_acento)) = 'story' THEN 'Story'
        WHEN LOWER(TRIM(tipo_sem_acento)) = 'post' THEN 'Post'
        WHEN LOWER(TRIM(tipo_sem_acento)) = 'carrossel' THEN 'Carrossel'
        WHEN LOWER(TRIM(tipo_sem_acento)) = 'live' THEN 'Live'
        WHEN LOWER(TRIM(tipo_sem_acento)) = 'resumo mensal' THEN 'Resumo Mensal'
        ELSE UPPER(SUBSTR(TRIM(tipo_sem_acento), 1, 1)) ||
             LOWER(SUBSTR(TRIM(tipo_sem_acento), 2))
    END AS tipo_conteudo,

    CASE
        WHEN tema_sem_acento IS NULL OR TRIM(tema_sem_acento) = '' THEN 'Nao Informado'
        WHEN LOWER(TRIM(tema_sem_acento)) = 'data comemorativa' THEN 'Data Comemorativa'
        WHEN LOWER(TRIM(tema_sem_acento)) = 'promocao' THEN 'Promocao'
        ELSE UPPER(SUBSTR(TRIM(tema_sem_acento), 1, 1)) ||
             LOWER(SUBSTR(TRIM(tema_sem_acento), 2))
    END AS tema_conteudo,

    CASE
        WHEN pago_original IS NULL OR TRIM(pago_original) = '' THEN 'Nao Informado'
        WHEN TRIM(pago_original) IN ('Sim', 'sim', 'SIM', 'S', 's') THEN 'Sim'
        WHEN TRIM(pago_original) IN ('Não', 'Nao', 'não', 'nao', 'NÃO', 'NAO', 'N', 'n') THEN 'Nao'
        ELSE TRIM(pago_original)
    END AS pago,

    CASE
        WHEN pago_original IS NULL OR TRIM(pago_original) = '' THEN NULL
        WHEN TRIM(pago_original) IN ('Sim', 'sim', 'SIM', 'S', 's') THEN 1
        WHEN TRIM(pago_original) IN ('Não', 'Nao', 'não', 'nao', 'NÃO', 'NAO', 'N', 'n') THEN 0
        ELSE NULL
    END AS flag_post_pago,

    campanha_id,

    CAST(Alcance AS INTEGER) AS alcance,
    CAST(Curtidas AS INTEGER) AS curtidas,
    CAST(Comentarios AS INTEGER) AS comentarios,
    CAST(Compartilhamentos AS INTEGER) AS compartilhamentos,
    CAST(Cliques AS INTEGER) AS cliques,

    CAST(Curtidas AS INTEGER) +
    CAST(Comentarios AS INTEGER) +
    CAST(Compartilhamentos AS INTEGER) AS engajamentos,

    CASE
        WHEN Alcance > 0 THEN ROUND(
            (Curtidas + Comentarios + Compartilhamentos) * 1.0 / Alcance,
            4
        )
        ELSE NULL
    END AS taxa_engajamento,

    CASE
        WHEN Alcance > 0 THEN ROUND(Cliques * 1.0 / Alcance, 4)
        ELSE NULL
    END AS taxa_clique,

    CASE
        WHEN post_id IS NULL OR TRIM(post_id) = '' THEN 1 ELSE 0
    END AS flag_post_id_invalido,

    CASE
        WHEN data_hora IS NULL THEN 1 ELSE 0
    END AS flag_data_invalida,

    CASE
        WHEN Alcance IS NULL OR Curtidas IS NULL OR Comentarios IS NULL
          OR Compartilhamentos IS NULL OR Cliques IS NULL THEN 1
        WHEN Alcance < 0 OR Curtidas < 0 OR Comentarios < 0
          OR Compartilhamentos < 0 OR Cliques < 0 THEN 1
        ELSE 0
    END AS flag_metricas_invalidas,

    CASE
        WHEN campanha_id IS NOT NULL AND pago_original IS NULL THEN 1
        ELSE 0
    END AS flag_campanha_com_pago_vazio

FROM textos_sem_acento;
