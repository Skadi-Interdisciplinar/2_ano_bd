-- ====================================================================
-- MASSA DE DADOS PARA TESTE DE VOLUME
-- ====================================================================
BEGIN;


-- =============================================
-- 1. ESTADOS
-- =============================================
INSERT INTO tb_estado (estado) VALUES
('AC'), ('AL'), ('AP'), ('AM'), ('BA'), ('CE'), ('DF'), ('ES'), ('GO'), 
('MA'), ('MT'), ('MS'), ('MG'), ('PA'), ('PB'), ('PR'), ('PE'), ('PI'),
('RJ'), ('RN'), ('RS'), ('RO'), ('RR'), ('SC'), ('SP'), ('SE'), ('TO');


-- =============================================
-- 2. CENTROS DE DISTRIBUIÇÃO
-- =============================================
INSERT INTO tb_cd (nome, cnpj) VALUES
('CD São Paulo', '48372615000194'),
('CD Rio de Janeiro', '71940582000163'),
('CD Minas Gerais', '90218437000128'),
('CD Paraná', '35847126000179'),
('CD Santa Catarina', '62490381000147');


-- =============================================
-- 3. ENDEREÇOS
-- =============================================
INSERT INTO tb_endereco
    (cep, rua, numero, cidade, bairro, complemento, cod_estado, cod_cd)
SELECT
    (10000000 + gs)::VARCHAR(8),
    'Rua Industrial ' || gs,
    100 + gs,

    CASE ((gs - 1) % 5)
        WHEN 0 THEN 'São Paulo'
        WHEN 1 THEN 'Rio de Janeiro'
        WHEN 2 THEN 'Belo Horizonte'
        WHEN 3 THEN 'Curitiba'
        ELSE 'Florianópolis'
    END,

    'Centro Industrial',

    CASE
        WHEN gs % 3 = 0 THEN 'Galpão ' || gs
        ELSE NULL
    END,

    CASE ((gs - 1) % 5)
        WHEN 0 THEN (SELECT id FROM tb_estado WHERE estado = 'SP')
        WHEN 1 THEN (SELECT id FROM tb_estado WHERE estado = 'RJ')
        WHEN 2 THEN (SELECT id FROM tb_estado WHERE estado = 'MG')
        WHEN 3 THEN (SELECT id FROM tb_estado WHERE estado = 'PR')
        ELSE (SELECT id FROM tb_estado WHERE estado = 'SC')
    END,

    ((gs - 1) % 5) + 1

FROM generate_series(1, 100) AS gs;


-- =============================================
-- 4. USUÁRIOS
-- =============================================

-- A trigger de auditoria precisa de um usuário existente para registrar cod_usuario.
ALTER TABLE tb_usuario
DISABLE TRIGGER trg_auditoria_usuario;

INSERT INTO tb_usuario (
    nome, cpf, email, senha, nivel_acesso
)
VALUES 
('Sistema Worker', '00000000000', 'sistema@skadi.local', '$2b$12$3wu4y3is8.AuPIIvwioO1eCs8ErbMEWRcmCEgONkpZwBufwtHYC7K', 'sistema');

INSERT INTO tb_usuario (
    nome, cpf, email, senha, nivel_acesso, cod_cd
)
SELECT
    (ARRAY[
        'Ana', 'Bruno', 'Camila', 'Daniel', 'Eduarda',
        'Felipe', 'Gabriela', 'Henrique', 'Isabela', 'João',
        'Karina', 'Leonardo', 'Mariana', 'Nicolas', 'Olívia',
        'Paulo', 'Rafaela', 'Samuel', 'Tatiana', 'Vinícius'
    ])[((gs - 1) % 20) + 1]
    || ' ' ||
    (ARRAY[
        'Almeida', 'Barbosa', 'Carvalho', 'Dias', 'Esteves'
    ])[((gs - 1) / 20) + 1],
    (10000000000 + (gs * 7919))::TEXT,
    'colaborador' || LPAD(gs::TEXT, 3, '0') || '@skadi.com.br',
    '$2a$12$V/BiuqbeOeEWxbeUfBMgy..ESFzLoz0c4Z5zAy4ArSFuZksxXyNKC',
    CASE
        WHEN gs <= 10 THEN 'admin'
        WHEN gs <= 30 THEN 'gestor'
        ELSE 'operador'
    END,
    ((gs - 1) % 5) + 1
FROM generate_series(1, 100) AS gs;

ALTER TABLE tb_usuario
ENABLE TRIGGER trg_auditoria_usuario;

-- Define o usuário atual para as próximas auditorias.
SELECT set_config('app.usuario_atual', '1', false);


-- =============================================
-- 5. TERMÔMETROS
-- =============================================
INSERT INTO tb_termometro (modelo)
SELECT
	CASE
		WHEN gs % 3 = 0 THEN 'ThermoTrack T-300'
		WHEN gs % 3 = 1 THEN 'SensorTemp ST-200'
		ELSE 'ColdMonitor CM-100'
	END
	|| '-' || LPAD(gs::TEXT, 3, '0')
FROM generate_series(1, 50) AS gs;


-- =============================================
-- 6. CATEGORIAS
-- =============================================
INSERT INTO tb_categoria
    (nome, temperatura_ideal, vida_util_horas)
VALUES
('Carnes bovinas resfriadas', 4.00, 8.00),
('Carnes suínas resfriadas', 4.00, 7.00),
('Aves resfriadas', 4.00, 6.00),
('Carnes processadas resfriadas', 4.00, 5.00),
('Pescados frescos', 0.00, 4.00),
('Pescados congelados', -18.00, 4.00);


-- =============================================
-- 7. CÂMARAS FRIGORÍFICAS
-- =============================================
INSERT INTO tb_camara_frigorifica
    (modelo, localizacao, temperatura_min, temperatura_max, cod_cd, cod_termometro)
VALUES

-- Câmaras frigoríficas de Carnes e Aves — 4°C
('ColdStorage CS-500', 'Setor Carnes - Câmara 01', 3.00, 4.50, 1, 1),
('ColdStorage CS-500', 'Setor Carnes - Câmara 02', 2.00, 6.00, 1, 2),
('FrioMaster FM-400', 'Setor Carnes - Câmara 03', 2.00, 6.00, 2, 3),
('FrioMaster FM-400', 'Setor Carnes - Câmara 04', 2.00, 6.00, 2, 4),
('RefrigPro RP-300', 'Setor Carnes - Câmara 05', 2.00, 6.00, 3, 5),
('RefrigPro RP-300', 'Setor Carnes - Câmara 06', 2.00, 6.00, 3, 6),

-- Câmaras frigoríficas de Pescados — 0°C
('ColdStorage CS-500', 'Setor Pescados - Câmara 01', -2.00, 2.00, 4, 7),
('FrioMaster FM-400', 'Setor Pescados - Câmara 02', -2.00, 2.00, 4, 8),
('RefrigPro RP-300', 'Setor Pescados - Câmara 03', -2.00, 2.00, 5, 9),

-- Câmaras frigoríficas de Congelados — -18°C
('ColdStorage CS-500', 'Setor Congelados - Câmara 01', -22.00, -16.00, 1, 10),
('FrioMaster FM-400', 'Setor Congelados - Câmara 02', -22.00, -16.00, 2, 11),
('RefrigPro RP-300', 'Setor Congelados - Câmara 03', -22.00, -16.00, 3, 12);


-- =============================================
-- 8. LOTES
-- =============================================
INSERT INTO tb_lote
    (codigo_lote, cod_categoria, data_fabricacao, data_validade)
VALUES
('LOTE-2026-0001', 1, '2026-08-20', '2026-09-08'),
('LOTE-2026-0002', 2, '2026-08-21', '2026-09-09'),
('LOTE-2026-0003', 3, '2026-08-22', '2026-09-07'),
('LOTE-2026-0004', 4, '2026-08-23', '2026-09-06'),
('LOTE-2026-0005', 1, '2026-08-20', '2026-09-08'),
('LOTE-2026-0006', 2, '2026-08-21', '2026-09-09'),
('LOTE-2026-0007', 5, '2026-08-25', '2026-09-05'),
('LOTE-2026-0008', 5, '2026-08-26', '2026-09-06'),
('LOTE-2026-0009', 5, '2026-08-27', '2026-09-07'),
('LOTE-2026-0010', 6, '2026-08-01', '2027-08-01'),
('LOTE-2026-0011', 6, '2026-08-02', '2027-08-02'),
('LOTE-2026-0012', 6, '2026-08-03', '2027-08-03');

INSERT INTO tb_lote_camara_frigorifica (cod_lote, cod_camara_frigorifica)
VALUES
    (1, 1),
    (2, 2),
    (3, 1),
    (4, 1),
    (5, 3),
    (6, 4),
    (7, 7),
    (8, 8),
    (9, 9),
    (10, 10),
    (11, 11),
    (12, 12);


-- =============================================
-- 9. LEITURAS DE TEMPERATURA
-- =============================================

-- 9.1 Leituras normais (dentro da faixa, não geram alerta)
INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
-- Câmara frigorífica 1 - faixa: 3°C a 4,5°C
(1, 4.00, '2026-08-30 08:00:00'),
(1, 4.50, '2026-08-30 20:00:00'),
(1, 3.80, '2026-08-31 08:00:00'),
(1, 4.20, '2026-08-31 20:00:00'),
(1, 4.10, '2026-09-01 08:00:00'),
(1, 3.90, '2026-09-01 20:00:00'),

-- Câmara frigorífica 2 - faixa: 2°C a 6°C
(2, 3.50, '2026-08-30 08:00:00'),
(2, 4.00, '2026-08-30 20:00:00'),
(2, 4.30, '2026-08-31 08:00:00'),
(2, 3.70, '2026-08-31 20:00:00'),
(2, 4.20, '2026-09-01 08:00:00'),
(2, 3.80, '2026-09-01 20:00:00'),

-- Câmara frigorífica 3 - faixa: 2°C a 6°C
(3, 4.20, '2026-08-30 08:00:00'),
(3, 3.80, '2026-08-30 20:00:00'),
(3, 4.50, '2026-08-31 08:00:00'),
(3, 4.00, '2026-08-31 20:00:00'),
(3, 3.60, '2026-09-01 08:00:00'),
(3, 4.40, '2026-09-01 20:00:00'),

-- Câmara frigorífica 4 - faixa: 2°C a 6°C
(4, 3.90, '2026-08-30 08:00:00'),
(4, 4.10, '2026-08-30 20:00:00'),
(4, 4.40, '2026-08-31 08:00:00'),
(4, 3.60, '2026-08-31 20:00:00'),
(4, 4.00, '2026-09-01 08:00:00'),
(4, 4.30, '2026-09-01 20:00:00'),

-- Câmara frigorífica 5 - faixa: 2°C a 6°C
(5, 4.00, '2026-08-30 08:00:00'),
(5, 4.30, '2026-08-30 20:00:00'),
(5, 3.70, '2026-08-31 08:00:00'),
(5, 4.20, '2026-08-31 20:00:00'),
(5, 3.90, '2026-09-01 08:00:00'),
(5, 4.10, '2026-09-01 20:00:00'),

-- Câmara frigorífica 6 - faixa: 2°C a 6°C
(6, 3.80, '2026-08-30 08:00:00'),
(6, 4.10, '2026-08-30 20:00:00'),
(6, 4.50, '2026-08-31 08:00:00'),
(6, 3.90, '2026-08-31 20:00:00'),
(6, 4.20, '2026-09-01 08:00:00'),
(6, 3.70, '2026-09-01 20:00:00'),

-- Câmara frigorífica 7 - faixa: -2°C a 2°C
(7, 0.00, '2026-08-30 08:00:00'),
(7, -0.50, '2026-08-30 20:00:00'),
(7, 0.50, '2026-08-31 08:00:00'),
(7, -1.00, '2026-08-31 20:00:00'),
(7, 0.20, '2026-09-01 08:00:00'),
(7, -0.30, '2026-09-01 20:00:00'),

-- Câmara frigorífica 8 - faixa: -2°C a 2°C
(8, 0.50, '2026-08-30 08:00:00'),
(8, -0.20, '2026-08-30 20:00:00'),
(8, 0.80, '2026-08-31 08:00:00'),
(8, -0.70, '2026-08-31 20:00:00'),
(8, 0.30, '2026-09-01 08:00:00'),
(8, -0.40, '2026-09-01 20:00:00'),

-- Câmara frigorífica 9 - faixa: -2°C a 2°C
(9, -0.50, '2026-08-30 08:00:00'),
(9, 0.00, '2026-08-30 20:00:00'),
(9, 0.70, '2026-08-31 08:00:00'),
(9, -0.30, '2026-08-31 20:00:00'),
(9, 0.40, '2026-09-01 08:00:00'),
(9, -0.80, '2026-09-01 20:00:00'),

-- Câmara frigorífica 10 - faixa: -22°C a -16°C
(10, -18.00, '2026-08-30 08:00:00'),
(10, -19.00, '2026-08-30 20:00:00'),
(10, -17.50, '2026-08-31 08:00:00'),
(10, -18.50, '2026-08-31 20:00:00'),
(10, -20.00, '2026-09-01 08:00:00'),
(10, -17.00, '2026-09-01 20:00:00'),

-- Câmara frigorífica 11 - faixa: -22°C a -16°C
(11, -18.50, '2026-08-30 08:00:00'),
(11, -19.50, '2026-08-30 20:00:00'),
(11, -17.00, '2026-08-31 08:00:00'),
(11, -18.00, '2026-08-31 20:00:00'),
(11, -20.50, '2026-09-01 08:00:00'),
(11, -17.50, '2026-09-01 20:00:00'),

-- Câmara frigorífica 12 - faixa: -22°C a -16°C
(12, -19.00, '2026-08-30 08:00:00'),
(12, -18.00, '2026-08-30 20:00:00'),
(12, -17.50, '2026-08-31 08:00:00'),
(12, -20.00, '2026-08-31 20:00:00'),
(12, -18.50, '2026-09-01 08:00:00'),
(12, -17.00, '2026-09-01 20:00:00');

-- 9.2 Leituras fora da faixa (geram alerta via trigger, um exemplo por gravidade)
INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
-- Câmara frigorífica 1 | Ideal: 4°C | Diferença: 0,80°C | Gravidade Estável
(1, 4.80, '2026-09-02 08:00:00'),

-- Câmara frigorífica 2 | Ideal: 4°C | Diferença: 2,80°C | Gravidade Atenção
(2, 6.80, '2026-09-02 08:30:00'),

-- Câmara frigorífica 7 | Ideal: 0°C | Diferença: 5°C | Gravidade Crítica
(7, 5.00, '2026-09-02 09:00:00'),

-- Câmara frigorífica 10 | Ideal: -18°C | Diferença: 10°C | Gravidade Urgente
(10, -8.00, '2026-09-02 09:30:00');

-- 9.3 Histórico adicional (mais dias de leituras normais, dentro da faixa de cada câmara frigorífica)
INSERT INTO tb_leitura_temperatura (cod_termometro, temperatura, data_hora)
SELECT
    r.cod_termometro,
    round(
        (
            r.temperatura_min
            + (r.temperatura_max - r.temperatura_min)
            * (0.3 + 0.4 * random())
        )::numeric,
        2
    ),
    TIMESTAMP '2026-08-20 08:00:00'
        + ((gs / 3) || ' days')::interval
        + (((gs % 3) * 8) || ' hours')::interval
FROM tb_camara_frigorifica r,
     generate_series(0, 29) AS gs;


-- =============================================
-- 10. FLUXO DE ATENDIMENTO (exemplo sobre os alertas gerados na seção 9.2)
-- =============================================

-- Leitura normal após o alerta da câmara frigorífica 1.
-- Permite que a justificativa seguinte encerre o atendimento e o alerta.
INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
(1, 4.20, '2026-09-02 09:00:00');
 
-- Reconhece e resolve o alerta de gravidade "estável" (câmara frigorífica 1)
DO $$
DECLARE
    v_cod_alerta INTEGER;
BEGIN
    SELECT id
    INTO v_cod_alerta
    FROM tb_alerta
    WHERE cod_camara_frigorifica = 1
    ORDER BY id DESC
    LIMIT 1;

    CALL sp_reconhecer_alerta(v_cod_alerta, 62);
END $$;
 
INSERT INTO tb_justificativa (
    cod_atendimento, motivo, descricao
)
VALUES (
    (SELECT a.id
     FROM tb_atendimento a
     JOIN tb_alerta al ON al.id = a.cod_alerta
     WHERE al.cod_camara_frigorifica = 1
     ORDER BY a.id DESC LIMIT 1),
    'Porta aberta para reposição',
    'Alerta gerado durante reposição manual de estoque; temperatura normalizada após fechamento da câmara.'
);
 
-- Reconhece o alerta crítico do câmara frigorífica 10, sem resolver
DO $$
DECLARE
    v_cod_alerta INTEGER;
BEGIN
    SELECT id
    INTO v_cod_alerta
    FROM tb_alerta
    WHERE cod_camara_frigorifica = 10
    ORDER BY id DESC
    LIMIT 1;

    CALL sp_reconhecer_alerta(v_cod_alerta, 42);
END $$;


-- =============================================
-- 11. RELATÓRIOS
-- =============================================
INSERT INTO tb_relatorio (
    cod_usuario_gerador, hash_conteudo, periodo_inicio, periodo_fim, status
)
VALUES
(2, 'a1b2c3d4e5f67890123456789012345678901234567890123456789012345678', '2026-08-01', '2026-08-31', 'gerado'),
(3, 'b2c3d4e5f678901234567890123456789012345678901234567890123456789', '2026-08-01', '2026-08-31', 'assinado'),
(4, 'c3d4e5f6789012345678901234567890123456789012345678901234567890', '2026-07-01', '2026-07-31', 'arquivado');


-- =============================================
-- 12. ASSINATURAS
-- =============================================
INSERT INTO tb_assinatura (
    cod_relatorio, certificado_titular, numero_serie, 
    autoridade_certificadora, algoritmo_assinatura,
    assinatura, carimbo_tempo
)
VALUES
(2, 'Sistema ColdChain', 'CERT-2026-0001', 'ICP-Brasil', 'SHA256withRSA', 'assinatura_simulada_relatorio_2', '2026-09-02 10:00:00'),
(3, 'Sistema ColdChain', 'CERT-2026-0002', 'ICP-Brasil', 'SHA256withRSA', 'assinatura_simulada_relatorio_3', '2026-09-02 10:05:00');


-- =============================================
-- 13. LOG DE ACESSO A RELATÓRIOS
-- =============================================
INSERT INTO tb_log_acesso_relatorio (
    cod_relatorio, cod_usuario, acao
)
VALUES
    (1, 32, 'visualizou'),
    (1, 33, 'baixou'),
    (2, 33, 'visualizou'),
    (3, 52, 'baixou');


-- Simulando escalonamento para gerar um log em tb_log_escalonamento
UPDATE tb_alerta
SET nivel_atual = 'gestor'
WHERE id = (
    SELECT id
    FROM tb_alerta
    WHERE nivel_gravidade = 'urgente'
    ORDER BY id DESC
    LIMIT 1
);


-- =============================================
-- 14. LOG DE SENSORES
-- =============================================
INSERT INTO tb_log_sensor (
    cod_termometro, tipo_evento, detalhes
)
VALUES
(1, 'manutencao', 'Sensor calibrado'),
(2, 'falha', 'Leitura fora do comportamento esperado'),
(7, 'manutencao', 'Sensor verificado'),
(10, 'bateria', 'Bateria do sensor substituída');


-- =============================================
-- 15. LOG DE ACESSO
-- =============================================
INSERT INTO tb_log_acesso (
    cod_usuario, tentativa_sucesso, ip_origem, user_agent, motivo_falha
)
VALUES
	(2, TRUE, '192.168.1.10', 'Mozilla/5.0', NULL),
	(32, TRUE, '192.168.1.11', 'Mozilla/5.0', NULL),
	(33, TRUE, '192.168.1.12', 'Mozilla/5.0', NULL),
	(52, TRUE, '192.168.1.13', 'Mozilla/5.0', NULL),
	(42, FALSE, '192.168.1.14', 'Mozilla/5.0', 'Senha incorreta');


COMMIT;
