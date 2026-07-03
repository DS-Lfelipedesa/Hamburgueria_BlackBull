-- Comeco pela dimensao de datas, porque ela sera usada para relacionar
-- os movimentos financeiros com analises de ano, mes, trimestre e dia.

-- Como a data ja possui uma chave natural confiavel, nao preciso usar AUTOINCREMENT.
-- Vou transformar a data no formato YYYYMMDD para criar um id estavel.
CREATE TABLE IF NOT EXISTS dim_data (
    id_data INTEGER PRIMARY KEY,
    data TEXT NOT NULL UNIQUE,
    ano INTEGER NOT NULL,
    mes_numero INTEGER NOT NULL,
    mes_nome TEXT NOT NULL,
    trimestre INTEGER NOT NULL,
    semestre INTEGER NOT NULL,
    dia_mes INTEGER NOT NULL,
    dia_semana_numero INTEGER NOT NULL,
    dia_semana_nome TEXT NOT NULL,
    ano_mes TEXT NOT NULL
);

-- Agora alimento a dim_data somente com datas que aparecem na stg_financeiro.
-- Uso DISTINCT porque uma mesma data aparece em varios movimentos.
-- Uso INSERT OR IGNORE porque, se a data ja existe, nao quero duplicar.
INSERT OR IGNORE INTO dim_data (
    id_data,
    data,
    ano,
    mes_numero,
    mes_nome,
    trimestre,
    semestre,
    dia_mes,
    dia_semana_numero,
    dia_semana_nome,
    ano_mes
)
SELECT DISTINCT
    -- Crio a chave da data removendo os separadores.
    -- Exemplo: 2022-03-01 vira 20220301.
    CAST(strftime('%Y%m%d', data_movimento) AS INTEGER) AS id_data,

    -- Mantenho tambem a data original para facilitar leitura e relacionamento.
    data_movimento AS data,

    -- Quebro a data em atributos que serao usados nos dashboards.
    CAST(strftime('%Y', data_movimento) AS INTEGER) AS ano,
    CAST(strftime('%m', data_movimento) AS INTEGER) AS mes_numero,

    -- Como o SQLite retorna apenas o numero do mes, traduzo manualmente para nome.
    CASE strftime('%m', data_movimento)
        WHEN '01' THEN 'Janeiro'
        WHEN '02' THEN 'Fevereiro'
        WHEN '03' THEN 'Marco'
        WHEN '04' THEN 'Abril'
        WHEN '05' THEN 'Maio'
        WHEN '06' THEN 'Junho'
        WHEN '07' THEN 'Julho'
        WHEN '08' THEN 'Agosto'
        WHEN '09' THEN 'Setembro'
        WHEN '10' THEN 'Outubro'
        WHEN '11' THEN 'Novembro'
        WHEN '12' THEN 'Dezembro'
    END AS mes_nome,

    -- O trimestre depende do numero do mes.
    CASE
        WHEN CAST(strftime('%m', data_movimento) AS INTEGER) BETWEEN 1 AND 3 THEN 1
        WHEN CAST(strftime('%m', data_movimento) AS INTEGER) BETWEEN 4 AND 6 THEN 2
        WHEN CAST(strftime('%m', data_movimento) AS INTEGER) BETWEEN 7 AND 9 THEN 3
        WHEN CAST(strftime('%m', data_movimento) AS INTEGER) BETWEEN 10 AND 12 THEN 4
    END AS trimestre,

    -- O semestre tambem deriva do mes.
    CASE
        WHEN CAST(strftime('%m', data_movimento) AS INTEGER) BETWEEN 1 AND 6 THEN 1
        WHEN CAST(strftime('%m', data_movimento) AS INTEGER) BETWEEN 7 AND 12 THEN 2
    END AS semestre,

    CAST(strftime('%d', data_movimento) AS INTEGER) AS dia_mes,

    -- No SQLite, %w retorna o dia da semana de 0 a 6.
    -- 0 representa domingo.
    CAST(strftime('%w', data_movimento) AS INTEGER) AS dia_semana_numero,

    -- Traduzo o numero do dia da semana para texto.
    CASE strftime('%w', data_movimento)
        WHEN '0' THEN 'Domingo'
        WHEN '1' THEN 'Segunda-feira'
        WHEN '2' THEN 'Terca-feira'
        WHEN '3' THEN 'Quarta-feira'
        WHEN '4' THEN 'Quinta-feira'
        WHEN '5' THEN 'Sexta-feira'
        WHEN '6' THEN 'Sabado'
    END AS dia_semana_nome,

    -- Crio ano_mes para facilitar agrupamentos mensais no Power BI.
    strftime('%Y-%m', data_movimento) AS ano_mes

FROM stg_financeiro

-- So quero datas validas na dimensao.
-- Datas invalidas continuam rastreadas na stg, mas nao entram na dim_data.
WHERE data_movimento IS NOT NULL
AND flag_data_invalida = 0;


-- Agora crio a dimensao de tipo de movimento.
-- Ela separa entradas e saidas financeiras, como Receita e Despesa.

-- Uso AUTOINCREMENT porque aqui nao existe uma chave numerica natural.
-- Uso UNIQUE para garantir que cada tipo apareca uma unica vez.
CREATE TABLE IF NOT EXISTS dim_tipo_movimento (
    id_tipo_movimento INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo_movimento TEXT NOT NULL UNIQUE
);

-- Busco na stg todos os tipos distintos.
-- Se o tipo ja existir na dimensao, o INSERT OR IGNORE preserva o registro antigo.
INSERT OR IGNORE INTO dim_tipo_movimento (
    tipo_movimento
)
SELECT DISTINCT
    tipo
FROM stg_financeiro

-- Evito inserir nulos ou textos vazios na dimensao.
WHERE tipo IS NOT NULL
AND TRIM(tipo) <> '';


-- Agora crio a dimensao de categoria financeira.
-- Ela sera usada para analisar grupos como Salao, Delivery, Insumos, Taxas etc.

CREATE TABLE IF NOT EXISTS dim_categoria_financeira (
    id_categoria_financeira INTEGER PRIMARY KEY AUTOINCREMENT,
    categoria_financeira TEXT NOT NULL UNIQUE
);

-- Carrego somente categorias distintas vindas da stg.
-- A stg ja e responsavel por tratar e padronizar esses textos antes daqui.
INSERT OR IGNORE INTO dim_categoria_financeira (
    categoria_financeira
)
SELECT DISTINCT
    categoria
FROM stg_financeiro
WHERE categoria IS NOT NULL
AND TRIM(categoria) <> '';


-- Agora crio a dimensao de centro de custo.
-- Ela detalha melhor onde o movimento financeiro se encaixa dentro da operacao.

CREATE TABLE IF NOT EXISTS dim_centro_custo (
    id_centro_custo INTEGER PRIMARY KEY AUTOINCREMENT,
    centro_custo TEXT NOT NULL UNIQUE
);

-- Insiro apenas centros de custo ainda nao cadastrados.
-- Assim, quando a stg for recriada com novos dados, somente novidades entram aqui.
INSERT OR IGNORE INTO dim_centro_custo (
    centro_custo
)
SELECT DISTINCT
    centro_custo
FROM stg_financeiro
WHERE centro_custo IS NOT NULL
AND TRIM(centro_custo) <> '';


-- Agora crio a dimensao de forma de pagamento.
-- Ela permite analisar recebimentos por PIX, Credito, Debito, Dinheiro etc.

CREATE TABLE IF NOT EXISTS dim_forma_pagamento (
    id_forma_pagamento INTEGER PRIMARY KEY AUTOINCREMENT,
    forma_pagamento TEXT NOT NULL UNIQUE
);

-- Busco as formas de pagamento distintas da stg.
-- Como existe UNIQUE, nao deixo a mesma forma ser cadastrada duas vezes.
INSERT OR IGNORE INTO dim_forma_pagamento (
    forma_pagamento
)
SELECT DISTINCT
    forma_pagamento
FROM stg_financeiro
WHERE forma_pagamento IS NOT NULL
AND TRIM(forma_pagamento) <> '';


-- Por ultimo, crio a dimensao de fornecedor ou origem.
-- Esse campo representa tanto canais de receita quanto fornecedores de despesa.

CREATE TABLE IF NOT EXISTS dim_fornecedor_origem (
    id_fornecedor_origem INTEGER PRIMARY KEY AUTOINCREMENT,
    fornecedor_origem TEXT NOT NULL UNIQUE
);

-- Insiro cada fornecedor/origem uma unica vez.
-- Novos canais ou fornecedores que surgirem na stg entram nas proximas execucoes.
INSERT OR IGNORE INTO dim_fornecedor_origem (
    fornecedor_origem
)
SELECT DISTINCT
    fornecedor_origem
FROM stg_financeiro
WHERE fornecedor_origem IS NOT NULL
AND TRIM(fornecedor_origem) <> '';

