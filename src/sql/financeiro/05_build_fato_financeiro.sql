-- =========================================================
-- QUERY 05: build_fato_financeiro
-- ORIGEM: stg_financeiro + dimensoes financeiras
-- DESTINO: fato_financeiro
--
-- Grao:
-- 1 linha = 1 movimento financeiro valido.
--
-- Mudanca importante:
-- A versao antiga usava INSERT OR IGNORE com uma chave textual montada
-- pelos atributos do movimento. Isso escondia duplicidades reais.
-- Agora a chave usa id_raw_financeiro, que vem do rowid da raw.
--
-- FIXME: quando o pipeline tiver carga incremental real, revisar
-- se id_raw_financeiro continua suficiente ou se entra hash do arquivo+linha.
-- =========================================================

DROP TABLE IF EXISTS fato_financeiro;

CREATE TABLE fato_financeiro (
    id_fato_financeiro INTEGER PRIMARY KEY AUTOINCREMENT,
    chave_movimento TEXT NOT NULL UNIQUE,
    id_raw_financeiro INTEGER,

    id_data INTEGER,
    data_hora TEXT,
    data_movimento TEXT,
    hora_movimento TEXT,

    id_tipo_movimento INTEGER,
    id_categoria_financeira INTEGER,
    id_centro_custo INTEGER,
    id_forma_pagamento INTEGER,
    id_fornecedor_origem INTEGER,

    pedido_id INTEGER,
    descricao TEXT,
    observacao TEXT,

    valor_original REAL,
    valor_abs REAL,
    valor_movimento REAL,

    flag_data_invalida INTEGER,
    flag_tipo_invalido INTEGER,
    flag_valor_invalido INTEGER,
    flag_pedido_id_recuperado INTEGER
);

INSERT INTO fato_financeiro (
    chave_movimento,
    id_raw_financeiro,
    id_data,
    data_hora,
    data_movimento,
    hora_movimento,
    id_tipo_movimento,
    id_categoria_financeira,
    id_centro_custo,
    id_forma_pagamento,
    id_fornecedor_origem,
    pedido_id,
    descricao,
    observacao,
    valor_original,
    valor_abs,
    valor_movimento,
    flag_data_invalida,
    flag_tipo_invalido,
    flag_valor_invalido,
    flag_pedido_id_recuperado
)
SELECT
    'FIN|' || CAST(s.id_raw_financeiro AS TEXT) AS chave_movimento,
    s.id_raw_financeiro,
    CAST(strftime('%Y%m%d', s.data_movimento) AS INTEGER) AS id_data,

    s.data_hora,
    s.data_movimento,
    s.hora_movimento,

    dt.id_tipo_movimento,
    dc.id_categoria_financeira,
    dcc.id_centro_custo,
    dfp.id_forma_pagamento,
    dfo.id_fornecedor_origem,

    s.pedido_id,
    s.descricao,
    s.observacao,
    s.valor_original,
    s.valor_abs,
    s.valor_movimento,

    s.flag_data_invalida,
    s.flag_tipo_invalido,
    s.flag_valor_invalido,
    s.flag_pedido_id_recuperado

FROM stg_financeiro AS s
LEFT JOIN (
    SELECT tipo_movimento, MIN(id_tipo_movimento) AS id_tipo_movimento
    FROM dim_tipo_movimento
    GROUP BY tipo_movimento
) AS dt
    ON s.tipo = dt.tipo_movimento
LEFT JOIN (
    SELECT categoria_financeira, MIN(id_categoria_financeira) AS id_categoria_financeira
    FROM dim_categoria_financeira
    GROUP BY categoria_financeira
) AS dc
    ON s.categoria = dc.categoria_financeira
LEFT JOIN (
    SELECT centro_custo, MIN(id_centro_custo) AS id_centro_custo
    FROM dim_centro_custo
    GROUP BY centro_custo
) AS dcc
    ON s.centro_custo = dcc.centro_custo
LEFT JOIN (
    -- NOTE: dim_forma_pagamento hoje e compartilhada e pode ter
    -- duplicatas por causa dos scripts antigos. Agrupo para nao duplicar fato.
    SELECT forma_pagamento, MIN(id_forma_pagamento) AS id_forma_pagamento
    FROM dim_forma_pagamento
    GROUP BY forma_pagamento
) AS dfp
    ON s.forma_pagamento = dfp.forma_pagamento
LEFT JOIN (
    SELECT fornecedor_origem, MIN(id_fornecedor_origem) AS id_fornecedor_origem
    FROM dim_fornecedor_origem
    GROUP BY fornecedor_origem
) AS dfo
    ON s.fornecedor_origem = dfo.fornecedor_origem
WHERE s.flag_data_invalida = 0
  AND s.flag_tipo_invalido = 0
  AND s.flag_valor_invalido = 0;
