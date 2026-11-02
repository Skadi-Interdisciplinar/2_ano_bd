-- Índices das consultas operacionais

CREATE INDEX IF NOT EXISTS idx_leitura_termometro_data
	ON tb_leitura_temperatura (cod_termometro, data_hora DESC, id DESC);

CREATE INDEX IF NOT EXISTS idx_alerta_escalonamento
	ON tb_alerta (status, nivel_atual, data_hora);

CREATE INDEX IF NOT EXISTS idx_lote_camara_ativos
	ON tb_lote_camara_frigorifica (cod_camara_frigorifica, cod_lote)
	WHERE data_saida IS NULL;

CREATE INDEX IF NOT EXISTS idx_solicitacao_suporte_usuario_abertura
	ON tb_solicitacao_suporte (cod_usuario_solicitante, data_hora_abertura DESC);

CREATE INDEX IF NOT EXISTS idx_solicitacao_suporte_responsavel_status
	ON tb_solicitacao_suporte (cod_usuario_responsavel, status);

ANALYZE tb_leitura_temperatura;
ANALYZE tb_alerta;
ANALYZE tb_lote_camara_frigorifica;
ANALYZE tb_solicitacao_suporte;

-- ================================================================
-- Observação do cenário com os índices disponíveis
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
WHERE a.status = 'ATIVO'
	AND a.nivel_atual IN ('OPERADOR', 'GESTOR')
ORDER BY a.data_hora;

-- Consulta 3: lotes atualmente ativos em uma câmara frigorífica
EXPLAIN (ANALYZE, BUFFERS)
SELECT lc.cod_lote, lc.cod_camara_frigorifica
FROM tb_lote_camara_frigorifica lc
WHERE lc.cod_camara_frigorifica = 1
	AND lc.data_saida IS NULL;

-- Consulta 4: solicitações recentes de um usuário
EXPLAIN (ANALYZE, BUFFERS)
SELECT ss.id, ss.status, ss.data_hora_abertura
FROM tb_solicitacao_suporte ss
WHERE ss.cod_usuario_solicitante = 21
ORDER BY ss.data_hora_abertura DESC
LIMIT 20;

-- Consulta 5: solicitações atribuídas a um responsável por status
EXPLAIN (ANALYZE, BUFFERS)
SELECT ss.id, ss.status, ss.data_hora_abertura
FROM tb_solicitacao_suporte ss
WHERE ss.cod_usuario_responsavel = 1000002
	AND ss.status = 'EM_ATENDIMENTO';
