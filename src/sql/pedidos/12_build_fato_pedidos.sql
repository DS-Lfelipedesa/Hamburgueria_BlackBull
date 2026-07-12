-- =========================================================
-- QUERY 12: build_fato_pedidos
-- PADRAO: CARGA COM UPSERT
-- COMPATIVEL COM SQLITE
--
-- ORIGEM:
-- stg_pedidos + dimensoes
--
-- DESTINO:
-- fato_pedidos
--
-- GRAO:
-- 1 linha = 1 item de pedido
--
-- CHAVE DE CONTROLE:
-- chave_pedido_item = PedidoID + ItemID
--
-- NOTE: a versao antiga fazia um UPDATE com uma subquery para
-- quase toda coluna. Funcionava, mas ficava muito lento em reexecucao.
-- Aqui mantive a logica simples, mas com UPSERT.
-- =========================================================


CREATE TABLE IF NOT EXISTS fato_pedidos (
    id_fato_pedido INTEGER PRIMARY KEY AUTOINCREMENT,

    chave_pedido_item TEXT NOT NULL UNIQUE,

    pedido_id INTEGER,
    item_id TEXT,

    id_data INTEGER,
    id_cliente INTEGER,
    id_produto INTEGER,
    id_canal INTEGER,
    id_plataforma INTEGER,
    id_bairro INTEGER,
    id_status_pedido INTEGER,
    id_forma_pagamento INTEGER,
    id_cupom INTEGER,

    data_hora TEXT,
    data_pedido TEXT,
    hora_pedido TEXT,

    quantidade INTEGER,
    valor_unitario REAL,
    valor_bruto REAL,
    desconto REAL,
    valor_liquido REAL,
    taxa_entrega REAL,

    campanha_id TEXT,
    observacao TEXT
);


DROP TABLE IF EXISTS temp_pedidos_dim;

CREATE TEMP TABLE temp_pedidos_dim AS
SELECT
    CAST(s.PedidoID AS TEXT) || '|' || COALESCE(TRIM(s.ItemID), 'SEM_ITEM') AS chave_pedido_item,

    s.PedidoID AS pedido_id,
    s.ItemID AS item_id,

    dd.id_data,
    dc.id_cliente,
    dp.id_produto,
    dca.id_canal,
    dpl.id_plataforma,
    db.id_bairro,
    dsp.id_status_pedido,
    dfp.id_forma_pagamento,
    dcu.id_cupom,

    s.DataHora AS data_hora,
    s.data_pedido,
    s.hora_pedido,

    s.Quantidade AS quantidade,
    s.ValorUnitario AS valor_unitario,
    s.ValorBruto AS valor_bruto,
    s.Desconto AS desconto,
    s.ValorLiquido AS valor_liquido,
    s.TaxaEntrega AS taxa_entrega,

    s.campanha_id,
    s.observacao

FROM stg_pedidos s

LEFT JOIN dim_data dd
    ON dd.data = s.data_pedido

LEFT JOIN dim_cliente dc
    ON dc.cliente_codigo_origem =
        CASE
            WHEN s.ClienteID IS NULL OR TRIM(s.ClienteID) = '' THEN 'Nao Informado'
            ELSE TRIM(s.ClienteID)
        END

LEFT JOIN dim_produto dp
    ON dp.produto_codigo_origem =
        CASE
            WHEN s.produto_id IS NULL OR TRIM(s.produto_id) = '' THEN 'Nao Informado'
            ELSE TRIM(s.produto_id)
        END
   AND dp.produto = s.produto
   AND dp.categoria_produto = s.categoria_produto

LEFT JOIN dim_canal dca
    ON dca.canal = s.canal

LEFT JOIN dim_plataforma dpl
    ON dpl.plataforma = s.plataforma

LEFT JOIN dim_bairro db
    ON db.bairro = s.bairro

LEFT JOIN dim_status_pedido dsp
    ON dsp.status_pedido = s.status_pedido

LEFT JOIN dim_forma_pagamento dfp
    ON dfp.forma_pagamento = s.forma_pagamento

LEFT JOIN dim_cupom dcu
    ON dcu.cupom = s.cupom;


-- Pequeno indice temporario para ajudar o upsert e futuras validacoes na sessao.
CREATE INDEX IF NOT EXISTS idx_temp_pedidos_dim_chave
ON temp_pedidos_dim (chave_pedido_item);


INSERT INTO fato_pedidos (
    chave_pedido_item,
    pedido_id,
    item_id,
    id_data,
    id_cliente,
    id_produto,
    id_canal,
    id_plataforma,
    id_bairro,
    id_status_pedido,
    id_forma_pagamento,
    id_cupom,
    data_hora,
    data_pedido,
    hora_pedido,
    quantidade,
    valor_unitario,
    valor_bruto,
    desconto,
    valor_liquido,
    taxa_entrega,
    campanha_id,
    observacao
)
SELECT
    t.chave_pedido_item,
    t.pedido_id,
    t.item_id,
    t.id_data,
    t.id_cliente,
    t.id_produto,
    t.id_canal,
    t.id_plataforma,
    t.id_bairro,
    t.id_status_pedido,
    t.id_forma_pagamento,
    t.id_cupom,
    t.data_hora,
    t.data_pedido,
    t.hora_pedido,
    t.quantidade,
    t.valor_unitario,
    t.valor_bruto,
    t.desconto,
    t.valor_liquido,
    t.taxa_entrega,
    t.campanha_id,
    t.observacao
FROM temp_pedidos_dim t
WHERE 1 = 1
ON CONFLICT(chave_pedido_item) DO UPDATE SET
    pedido_id = excluded.pedido_id,
    item_id = excluded.item_id,
    id_data = excluded.id_data,
    id_cliente = excluded.id_cliente,
    id_produto = excluded.id_produto,
    id_canal = excluded.id_canal,
    id_plataforma = excluded.id_plataforma,
    id_bairro = excluded.id_bairro,
    id_status_pedido = excluded.id_status_pedido,
    id_forma_pagamento = excluded.id_forma_pagamento,
    id_cupom = excluded.id_cupom,
    data_hora = excluded.data_hora,
    data_pedido = excluded.data_pedido,
    hora_pedido = excluded.hora_pedido,
    quantidade = excluded.quantidade,
    valor_unitario = excluded.valor_unitario,
    valor_bruto = excluded.valor_bruto,
    desconto = excluded.desconto,
    valor_liquido = excluded.valor_liquido,
    taxa_entrega = excluded.taxa_entrega,
    campanha_id = excluded.campanha_id,
    observacao = excluded.observacao;
