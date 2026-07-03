-- A fato e criada somente se ainda nao existir.
-- Cada linha representa um movimento financeiro valido vindo da stg_financeiro.
CREATE TABLE IF NOT EXISTS fato_financeiro (
    id_fato_financeiro INTEGER PRIMARY KEY AUTOINCREMENT,
    chave_movimento TEXT NOT NULL UNIQUE,

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

-- Insercao apenas de movimentos novos.
-- A chave_movimento evita duplicidade quando o script rodar novamente.
INSERT OR IGNORE INTO fato_financeiro (
    chave_movimento,
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
    -- Chave tecnica para identificar unicamente o movimento.
    COALESCE(s.data_hora, '') || '|' ||
    COALESCE(s.tipo, '') || '|' ||
    COALESCE(s.categoria, '') || '|' ||
    COALESCE(s.centro_custo, '') || '|' ||
    COALESCE(s.descricao, '') || '|' ||
    COALESCE(CAST(s.pedido_id AS TEXT), '') || '|' ||
    COALESCE(s.forma_pagamento, '') || '|' ||
    COALESCE(s.fornecedor_origem, '') || '|' ||
    COALESCE(CAST(s.valor_movimento AS TEXT), '') AS chave_movimento,

    -- Id da data no mesmo formato da dim_data.
    CAST(strftime('%Y%m%d', s.data_movimento) AS INTEGER) AS id_data,

    s.data_hora,
    s.data_movimento,
    s.hora_movimento,

    -- Conversao dos textos da stg para os IDs das dimensoes.
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
LEFT JOIN dim_tipo_movimento AS dt
    ON s.tipo = dt.tipo_movimento
LEFT JOIN dim_categoria_financeira AS dc
    ON s.categoria = dc.categoria_financeira
LEFT JOIN dim_centro_custo AS dcc
    ON s.centro_custo = dcc.centro_custo
LEFT JOIN dim_forma_pagamento AS dfp
    ON s.forma_pagamento = dfp.forma_pagamento
LEFT JOIN dim_fornecedor_origem AS dfo
    ON s.fornecedor_origem = dfo.fornecedor_origem
WHERE s.flag_data_invalida = 0
AND s.flag_tipo_invalido = 0
AND s.flag_valor_invalido = 0;
