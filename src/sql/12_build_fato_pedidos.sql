-- =========================================================
-- QUERY 12: build_fato_pedidos
-- PADRAO: PRODUCAO / CARGA INCREMENTAL
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
-- LOGICA:
-- 1. Criar fato_pedidos se nao existir
-- 2. Montar uma tabela temporaria com os pedidos e IDs das dimensoes
-- 3. Atualizar registros que ja existem na fato
-- 4. Inserir registros novos
-- =========================================================


-- =========================================================
-- 1. CRIA A TABELA FATO, SE AINDA NAO EXISTIR
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


-- =========================================================
-- 2. MONTA TABELA TEMPORARIA COM PEDIDOS + DIMENSOES
--
-- Logica:
-- Aqui juntamos a stg_pedidos com todas as dimensoes.
-- Essa tabela temporaria existe apenas durante a execucao.
-- =========================================================

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


-- =========================================================
-- 3. ATUALIZA REGISTROS JA EXISTENTES
--
-- Logica:
-- Se o item de pedido ja existe na fato, atualizamos seus
-- valores e chaves dimensionais.
-- =========================================================

UPDATE fato_pedidos
SET
    pedido_id = (
        SELECT t.pedido_id
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    item_id = (
        SELECT t.item_id
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    id_data = (
        SELECT t.id_data
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    id_cliente = (
        SELECT t.id_cliente
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    id_produto = (
        SELECT t.id_produto
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    id_canal = (
        SELECT t.id_canal
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    id_plataforma = (
        SELECT t.id_plataforma
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    id_bairro = (
        SELECT t.id_bairro
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    id_status_pedido = (
        SELECT t.id_status_pedido
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    id_forma_pagamento = (
        SELECT t.id_forma_pagamento
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    id_cupom = (
        SELECT t.id_cupom
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    data_hora = (
        SELECT t.data_hora
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    data_pedido = (
        SELECT t.data_pedido
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    hora_pedido = (
        SELECT t.hora_pedido
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    quantidade = (
        SELECT t.quantidade
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    valor_unitario = (
        SELECT t.valor_unitario
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    valor_bruto = (
        SELECT t.valor_bruto
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    desconto = (
        SELECT t.desconto
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    valor_liquido = (
        SELECT t.valor_liquido
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    taxa_entrega = (
        SELECT t.taxa_entrega
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    campanha_id = (
        SELECT t.campanha_id
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    ),

    observacao = (
        SELECT t.observacao
        FROM temp_pedidos_dim t
        WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
    )

WHERE EXISTS (
    SELECT 1
    FROM temp_pedidos_dim t
    WHERE t.chave_pedido_item = fato_pedidos.chave_pedido_item
);


-- =========================================================
-- 4. INSERE REGISTROS NOVOS
--
-- Logica:
-- Se a chave_pedido_item ainda nao existe na fato, insere.
-- =========================================================

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
LEFT JOIN fato_pedidos f
    ON f.chave_pedido_item = t.chave_pedido_item
WHERE f.id_fato_pedido IS NULL;