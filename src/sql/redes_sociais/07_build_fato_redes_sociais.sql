-- =========================================================
-- QUERY 07: build_fato_redes_sociais
-- ORIGEM: stg_redes_sociais + dimensoes
-- DESTINO: fato_redes_sociais
--
-- Grao:
-- 1 linha = 1 post/publicacao ou 1 resumo mensal consolidado.
--
-- Chave natural:
-- post_id
--
-- Chaves tecnicas:
-- id_data, id_rede_social, id_tipo_conteudo, id_tema_conteudo,
-- id_campanha_marketing.
--
-- FIXME(ai-pass): quando o projeto tiver orquestrador, avaliar se esta fato
-- deve ser incremental. Agora ela e reconstruida para evitar sujeira antiga.
-- =========================================================

DROP TABLE IF EXISTS fato_redes_sociais;

CREATE TABLE fato_redes_sociais (
    id_fato_rede_social INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id TEXT NOT NULL UNIQUE,

    id_data INTEGER,
    id_rede_social INTEGER,
    id_tipo_conteudo INTEGER,
    id_tema_conteudo INTEGER,
    id_campanha_marketing INTEGER,

    data_hora TEXT,
    data_postagem TEXT,
    hora_postagem TEXT,

    pago TEXT,
    flag_post_pago INTEGER,
    campanha_id TEXT,

    alcance INTEGER,
    curtidas INTEGER,
    comentarios INTEGER,
    compartilhamentos INTEGER,
    cliques INTEGER,
    engajamentos INTEGER,
    taxa_engajamento REAL,
    taxa_clique REAL,

    flag_post_id_invalido INTEGER,
    flag_data_invalida INTEGER,
    flag_metricas_invalidas INTEGER,
    flag_campanha_com_pago_vazio INTEGER
);

INSERT INTO fato_redes_sociais (
    post_id,
    id_data,
    id_rede_social,
    id_tipo_conteudo,
    id_tema_conteudo,
    id_campanha_marketing,
    data_hora,
    data_postagem,
    hora_postagem,
    pago,
    flag_post_pago,
    campanha_id,
    alcance,
    curtidas,
    comentarios,
    compartilhamentos,
    cliques,
    engajamentos,
    taxa_engajamento,
    taxa_clique,
    flag_post_id_invalido,
    flag_data_invalida,
    flag_metricas_invalidas,
    flag_campanha_com_pago_vazio
)
SELECT
    s.post_id,
    dd.id_data,
    drs.id_rede_social,
    dtc.id_tipo_conteudo,
    dtema.id_tema_conteudo,
    dcm.id_campanha_marketing,

    s.data_hora,
    s.data_postagem,
    s.hora_postagem,
    s.pago,
    s.flag_post_pago,
    s.campanha_id,

    s.alcance,
    s.curtidas,
    s.comentarios,
    s.compartilhamentos,
    s.cliques,
    s.engajamentos,
    s.taxa_engajamento,
    s.taxa_clique,

    s.flag_post_id_invalido,
    s.flag_data_invalida,
    s.flag_metricas_invalidas,
    s.flag_campanha_com_pago_vazio

FROM stg_redes_sociais s

LEFT JOIN dim_data dd
    ON dd.data = s.data_postagem

LEFT JOIN dim_rede_social drs
    ON drs.rede_social = s.rede_social

LEFT JOIN dim_tipo_conteudo dtc
    ON dtc.tipo_conteudo = s.tipo_conteudo

LEFT JOIN dim_tema_conteudo dtema
    ON dtema.tema_conteudo = s.tema_conteudo

LEFT JOIN dim_campanha_marketing dcm
    ON dcm.campanha_id_origem = s.campanha_id

WHERE s.flag_post_id_invalido = 0
  AND s.flag_data_invalida = 0
  AND s.flag_metricas_invalidas = 0;

