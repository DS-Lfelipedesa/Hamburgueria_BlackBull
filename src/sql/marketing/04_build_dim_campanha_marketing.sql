-- query 04 - build dim campanha marketing
-- objetivo: criar/atualizar a dimensao de campanhas de marketing
-- origem: stg_marketing
-- destino: dim_campanha_marketing
--
-- Grao:
-- 1 linha = 1 campanha de marketing.
--
-- NOTE: este arquivo estava com conteudo de plataforma marketing.
-- Refeito para reconstruir a dimensao correta.

CREATE TABLE IF NOT EXISTS dim_campanha_marketing (
    id_campanha_marketing INTEGER PRIMARY KEY AUTOINCREMENT,
    campanha_id_origem TEXT NOT NULL UNIQUE,
    nome_campanha TEXT,
    objetivo TEXT
);

INSERT INTO dim_campanha_marketing (
    campanha_id_origem,
    nome_campanha,
    objetivo
)
SELECT DISTINCT
    TRIM(CampanhaID) AS campanha_id_origem,
    TRIM(NomeCampanha) AS nome_campanha,
    TRIM(Objetivo) AS objetivo
FROM stg_marketing
WHERE CampanhaID IS NOT NULL
  AND TRIM(CampanhaID) <> ''
ON CONFLICT(campanha_id_origem) DO UPDATE SET
    nome_campanha = excluded.nome_campanha,
    objetivo = excluded.objetivo;
