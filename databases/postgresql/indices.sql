-- ====================================================================
-- ÍNDICES E CONSULTAS DE ANÁLISE DE DESEMPENHO
-- ====================================================================

-- Remove os índices desta análise para reproduzir o cenário inicial.
DROP INDEX IF EXISTS idx_leitura_termometro_data;
DROP INDEX IF EXISTS idx_alerta_escalonamento;
DROP INDEX IF EXISTS idx_lote_camara_ativos;
DROP INDEX IF EXISTS idx_solicitacao_suporte_usuario_abertura;
DROP INDEX IF EXISTS idx_solicitacao_suporte_responsavel_status;

ANALYZE tb_leitura_temperatura;
ANALYZE tb_alerta;
ANALYZE tb_lote_camara_frigorifica;
ANALYZE tb_solicitacao_suporte;

-- ================================================================
-- 1. CENÁRIO INICIAL: análise sem os índices
-- ================================================================

-- Consulta 1: última leitura de temperatura por termômetro
EXPLAIN (ANALYZE, BUFFERS)
SELECT lt.id, lt.temperatura, lt.data_hora
FROM tb_leitura_temperatura lt
WHERE lt.cod_termometro = 1
ORDER BY lt.data_hora DESC, lt.id DESC
LIMIT 1;

-- Consulta 2: alertas ativos aguardando operador/gestor
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.id, a.nivel_atual, a.data_hora
FROM tb_alerta a
WHERE a.status = 'ativo'
	AND a.nivel_atual IN ('operador', 'gestor')
ORDER BY a.data_hora;

-- Consulta 3: lotes atualmente ativos em uma câmara frigorífica
EXPLAIN (ANALYZE, BUFFERS)
SELECT lc.cod_lote, lc.cod_camara_frigorifica
FROM tb_lote_camara_frigorifica lc
WHERE lc.cod_camara_frigorifica = 1
	AND lc.data_saida IS NULL;

-- ================================================================
-- 2. ÍNDICES APLICADOS
-- ================================================================

CREATE INDEX idx_leitura_termometro_data
	ON tb_leitura_temperatura (cod_termometro, data_hora DESC, id DESC);

CREATE INDEX idx_alerta_escalonamento
	ON tb_alerta (status, nivel_atual, data_hora);

CREATE INDEX idx_lote_camara_ativos
	ON tb_lote_camara_frigorifica (cod_camara_frigorifica, cod_lote)
	WHERE data_saida IS NULL;

CREATE INDEX idx_solicitacao_suporte_usuario_abertura
	ON tb_solicitacao_suporte (cod_usuario_solicitante, data_hora_abertura DESC);

CREATE INDEX idx_solicitacao_suporte_responsavel_status
	ON tb_solicitacao_suporte (cod_usuario_responsavel, status);

ANALYZE tb_leitura_temperatura;
ANALYZE tb_alerta;
ANALYZE tb_lote_camara_frigorifica;
ANALYZE tb_solicitacao_suporte;

-- ================================================================
-- 3. CENÁRIO OTIMIZADO: análise após os índices
-- ================================================================

-- Consulta 1: última leitura de temperatura por termômetro
EXPLAIN (ANALYZE, BUFFERS)
SELECT lt.id, lt.temperatura, lt.data_hora
FROM tb_leitura_temperatura lt
WHERE lt.cod_termometro = 1
ORDER BY lt.data_hora DESC, lt.id DESC
LIMIT 1;

-- Consulta 2: alertas ativos aguardando operador/gestor
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.id, a.nivel_atual, a.data_hora
FROM tb_alerta a
WHERE a.status = 'ativo'
	AND a.nivel_atual IN ('operador', 'gestor')
ORDER BY a.data_hora;

-- Consulta 3: lotes atualmente ativos em uma câmara frigorífica
EXPLAIN (ANALYZE, BUFFERS)
SELECT lc.cod_lote, lc.cod_camara_frigorifica
FROM tb_lote_camara_frigorifica lc
WHERE lc.cod_camara_frigorifica = 1
	AND lc.data_saida IS NULL;
