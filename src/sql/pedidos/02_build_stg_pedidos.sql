-- =========================================================
-- QUERY 02: build_stg_pedidos
-- ORIGEM: raw_pedidos
-- DESTINO: stg_pedidos
--
-- OBJETIVO:
-- Criar a tabela stg_pedidos a partir da raw_pedidos,
-- aplicando limpeza, padronização textual e regras de negócio.
--
-- REGRAS:
-- 1. Remover espaços extras com TRIM()
-- 2. Remover acentos
-- 3. Padronizar textos com primeira letra maiúscula
-- 4. Corrigir variações conhecidas de preenchimento
-- 5. Se plataforma = Balcao:
--      - canal = Salao
--      - bairro = NULL
-- =========================================================

DROP TABLE IF EXISTS stg_pedidos;

CREATE TABLE stg_pedidos AS
WITH pedidos_base AS (
    SELECT
        PedidoID,
        ItemID,
        TRIM(DataHora) AS data_hora_original,
        CASE
            WHEN TRIM(DataHora) LIKE '____-__-__%' THEN datetime(TRIM(DataHora))
            WHEN TRIM(DataHora) LIKE '__/__/____%' THEN datetime(
                SUBSTR(TRIM(DataHora), 7, 4) || '-' ||
                SUBSTR(TRIM(DataHora), 4, 2) || '-' ||
                SUBSTR(TRIM(DataHora), 1, 2) ||
                SUBSTR(TRIM(DataHora), 11)
            )
            ELSE NULL
        END AS data_hora_tratada,
        ClienteID,

        TRIM(Canal) AS canal_original,
        TRIM(Plataforma) AS plataforma_original,
        TRIM(Bairro) AS bairro_original,
        TRIM(ProdutoID) AS produto_id_original,
        TRIM(Produto) AS produto_original,
        TRIM(CategoriaProduto) AS categoria_produto_original,
        TRIM(FormaPagamento) AS forma_pagamento_original,
        TRIM(StatusPedido) AS status_pedido_original,
        TRIM(Cupom) AS cupom_original,
        TRIM(CampanhaID) AS campanha_id_original,
        TRIM(Observacao) AS observacao_original,

        Quantidade,
        ValorUnitario,
        ValorBruto,
        Desconto,
        ValorLiquido,
        TaxaEntrega

    FROM raw_pedidos
),

pedidos_sem_acentos AS (
    SELECT
        PedidoID,
        ItemID,
        data_hora_original,
        data_hora_tratada,
        ClienteID,

        -- Remove acentos do canal
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(canal_original,
        'á','a'),'à','a'),'ã','a'),'â','a'),'é','e'),'ê','e'),'í','i'),'ó','o'),'õ','o'),'ô','o'),'ú','u'),'ç','c'),
        'Á','A'),'Ã','A'),'É','E'),'Ç','C') AS canal_sem_acento,

        -- Remove acentos da plataforma
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(plataforma_original,
        'á','a'),'à','a'),'ã','a'),'â','a'),'é','e'),'ê','e'),'í','i'),'ó','o'),'õ','o'),'ô','o'),'ú','u'),'ç','c'),
        'Á','A'),'Ã','A'),'É','E'),'Ç','C') AS plataforma_sem_acento,

        -- Remove acentos do bairro
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(bairro_original,
        'á','a'),'à','a'),'ã','a'),'â','a'),'é','e'),'ê','e'),'í','i'),'ó','o'),'õ','o'),'ô','o'),'ú','u'),'ç','c'),
        'Á','A'),'Ã','A'),'É','E'),'Ç','C') AS bairro_sem_acento,

        produto_id_original,

        -- Remove acentos do produto
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(produto_original,
        'á','a'),'à','a'),'ã','a'),'â','a'),'é','e'),'ê','e'),'í','i'),'ó','o'),'õ','o'),'ô','o'),'ú','u'),'ç','c'),
        'Á','A'),'Ã','A'),'É','E'),'Ç','C') AS produto_sem_acento,

        -- Remove acentos da categoria do produto
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(categoria_produto_original,
        'á','a'),'à','a'),'ã','a'),'â','a'),'é','e'),'ê','e'),'í','i'),'ó','o'),'õ','o'),'ô','o'),'ú','u'),'ç','c'),
        'Á','A'),'Ã','A'),'É','E'),'Ç','C') AS categoria_produto_sem_acento,

        -- Remove acentos da forma de pagamento
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(forma_pagamento_original,
        'á','a'),'à','a'),'ã','a'),'â','a'),'é','e'),'ê','e'),'í','i'),'ó','o'),'õ','o'),'ô','o'),'ú','u'),'ç','c'),
        'Á','A'),'Ã','A'),'É','E'),'Ç','C') AS forma_pagamento_sem_acento,

        -- Remove acentos do status
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(status_pedido_original,
        'á','a'),'à','a'),'ã','a'),'â','a'),'é','e'),'ê','e'),'í','i'),'ó','o'),'õ','o'),'ô','o'),'ú','u'),'ç','c'),
        'Á','A'),'Ã','A'),'É','E'),'Ç','C') AS status_pedido_sem_acento,

        cupom_original,
        campanha_id_original,
        observacao_original,

        Quantidade,
        ValorUnitario,
        ValorBruto,
        Desconto,
        ValorLiquido,
        TaxaEntrega

    FROM pedidos_base
),

pedidos_tratados AS (
    SELECT
        PedidoID,
        ItemID,
        -- NOTE: mantenho o nome DataHora para nao quebrar scripts
        -- seguintes, mas agora ele sai normalizado em ISO quando possivel.
        data_hora_tratada AS DataHora,

        DATE(data_hora_tratada) AS data_pedido,
        TIME(data_hora_tratada) AS hora_pedido,

        ClienteID,

        -- Plataforma padronizada
        CASE
            WHEN plataforma_sem_acento IS NULL OR plataforma_sem_acento = '' THEN 'Nao Informado'
            WHEN LOWER(plataforma_sem_acento) = 'balcao' THEN 'Balcao'
            WHEN LOWER(plataforma_sem_acento) = 'ifood' THEN 'Ifood'
            WHEN LOWER(plataforma_sem_acento) = 'whatsapp' THEN 'Whatsapp'
            WHEN LOWER(plataforma_sem_acento) = 'app proprio' THEN 'App Proprio'
            WHEN LOWER(plataforma_sem_acento) = 'telefone' THEN 'Telefone'
            ELSE UPPER(SUBSTR(plataforma_sem_acento, 1, 1)) ||
                 LOWER(SUBSTR(plataforma_sem_acento, 2))
        END AS plataforma,

        -- Canal padronizado
        -- Regra de negócio: se plataforma for Balcao, canal deve ser Salao
        CASE
            WHEN LOWER(plataforma_sem_acento) = 'balcao' THEN 'Salao'
            WHEN canal_sem_acento IS NULL OR canal_sem_acento = '' THEN 'Nao Informado'
            WHEN LOWER(canal_sem_acento) = 'salao' THEN 'Salao'
            WHEN LOWER(canal_sem_acento) IN ('delivery', 'delivry') THEN 'Delivery'
            WHEN LOWER(canal_sem_acento) = 'retirada' THEN 'Retirada'
            ELSE UPPER(SUBSTR(canal_sem_acento, 1, 1)) ||
                 LOWER(SUBSTR(canal_sem_acento, 2))
        END AS canal,

        -- Bairro padronizado
        -- Regra de negócio: se plataforma for Balcao, bairro deve ser NULL
        CASE
            WHEN LOWER(plataforma_sem_acento) = 'balcao' THEN NULL
            WHEN bairro_sem_acento IS NULL OR bairro_sem_acento = '' THEN 'Nao Informado'
            ELSE UPPER(SUBSTR(bairro_sem_acento, 1, 1)) ||
                 LOWER(SUBSTR(bairro_sem_acento, 2))
        END AS bairro,

        produto_id_original AS produto_id,

        CASE
            WHEN produto_sem_acento IS NULL OR produto_sem_acento = '' THEN 'Nao Informado'
            ELSE UPPER(SUBSTR(produto_sem_acento, 1, 1)) ||
                 LOWER(SUBSTR(produto_sem_acento, 2))
        END AS produto,

        CASE
            WHEN categoria_produto_sem_acento IS NULL OR categoria_produto_sem_acento = '' THEN 'Nao Informado'
            ELSE UPPER(SUBSTR(categoria_produto_sem_acento, 1, 1)) ||
                 LOWER(SUBSTR(categoria_produto_sem_acento, 2))
        END AS categoria_produto,

        Quantidade,
        ValorUnitario,
        ValorBruto,
        Desconto,
        ValorLiquido,
        TaxaEntrega,

        CASE
            WHEN forma_pagamento_sem_acento IS NULL OR forma_pagamento_sem_acento = '' THEN 'Nao Informado'
            WHEN LOWER(forma_pagamento_sem_acento) = 'credito' THEN 'Credito'
            WHEN LOWER(forma_pagamento_sem_acento) = 'debito' THEN 'Debito'
            WHEN LOWER(forma_pagamento_sem_acento) = 'pix' THEN 'Pix'
            WHEN LOWER(forma_pagamento_sem_acento) = 'voucher' THEN 'Voucher'
            WHEN LOWER(forma_pagamento_sem_acento) IN ('dinheiro', 'dinheir') THEN 'Dinheiro'
            WHEN LOWER(forma_pagamento_sem_acento) = 'cartao' THEN 'Cartao'
            ELSE UPPER(SUBSTR(forma_pagamento_sem_acento, 1, 1)) ||
                 LOWER(SUBSTR(forma_pagamento_sem_acento, 2))
        END AS forma_pagamento,

        CASE
            WHEN status_pedido_sem_acento IS NULL OR status_pedido_sem_acento = '' THEN 'Nao Informado'
            WHEN LOWER(status_pedido_sem_acento) = 'concluido' THEN 'Concluido'
            WHEN LOWER(status_pedido_sem_acento) = 'cancelado' THEN 'Cancelado'
            WHEN LOWER(status_pedido_sem_acento) IN ('reembolsado', 'estornado') THEN 'Reembolsado'
            ELSE UPPER(SUBSTR(status_pedido_sem_acento, 1, 1)) ||
                 LOWER(SUBSTR(status_pedido_sem_acento, 2))
        END AS status_pedido,

        CASE
            WHEN cupom_original IS NULL OR cupom_original = '' THEN 'Sem Cupom'
            ELSE UPPER(SUBSTR(cupom_original, 1, 1)) ||
                 LOWER(SUBSTR(cupom_original, 2))
        END AS cupom,

        campanha_id_original AS campanha_id,
        observacao_original AS observacao

    FROM pedidos_sem_acentos
)

SELECT *
FROM pedidos_tratados;
