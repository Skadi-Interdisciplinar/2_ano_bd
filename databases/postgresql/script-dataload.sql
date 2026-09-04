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
('CD São Paulo', '12345678000101'),
('CD Rio de Janeiro', '23456789000102'),
('CD Minas Gerais', '34567890000103'),
('CD Paraná', '45678901000104'),
('CD Santa Catarina', '56789012000105');


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
    nome, cpf, email, senha, nivel_acesso, cod_cd
)
SELECT
    'Funcionário ' || gs,
    LPAD(gs::TEXT, 11, '0'),
    'funcionario' || gs || '@coldchain.com.br',
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
-- 6. PRODUTOS
-- =============================================
INSERT INTO tb_produto
    (nome, temperatura_ideal, tempo_sobrevivencia, validade)
VALUES

-- Carnes bovinas — 4°C
('Carne bovina - Acém', 4.00, 8.00, '2027-03-15'),
('Carne bovina - Alcatra', 4.00, 8.00, '2027-03-20'),
('Carne bovina - Contrafilé', 4.00, 8.00, '2027-04-10'),
('Carne bovina - Costela', 4.00, 7.00, '2027-04-15'),
('Carne bovina - Patinho', 4.00, 8.00, '2027-05-05'),

-- Carnes suínas — 4°C
('Carne suína - Lombo', 4.00, 7.00, '2027-03-25'),
('Carne suína - Pernil', 4.00, 7.00, '2027-04-05'),
('Carne suína - Costela', 4.00, 6.00, '2027-04-20'),
('Carne suína - Paleta', 4.00, 7.00, '2027-05-10'),

-- Aves — 4°C
('Frango inteiro', 4.00, 6.00, '2027-02-15'),
('Peito de frango', 4.00, 6.00, '2027-02-20'),
('Coxa de frango', 4.00, 6.00, '2027-03-01'),
('Asa de frango', 4.00, 5.00, '2027-03-10'),
('Frango desossado', 4.00, 6.00, '2027-03-20'),

-- Carnes processadas — 4°C
('Linguiça fresca', 4.00, 5.00, '2027-02-28'),
('Hambúrguer bovino resfriado', 4.00, 5.00, '2027-03-15'),
('Carne moída bovina', 4.00, 4.00, '2027-03-05'),

-- Pescados — 0°C
('Tilápia fresca', 0.00, 4.00, '2027-02-10'),
('Salmão fresco', 0.00, 4.00, '2027-02-15'),
('Filé de peixe', 0.00, 4.00, '2027-03-01'),
('Camarão fresco', 0.00, 3.00, '2027-03-10'),
('Atum fresco', 0.00, 4.00, '2027-03-20'),

-- Produtos congelados — -18°C
('Carne bovina congelada', -18.00, 4.00, '2028-01-15'),
('Carne suína congelada', -18.00, 4.00, '2028-02-10'),
('Frango congelado', -18.00, 4.00, '2028-02-20'),
('Peixe congelado', -18.00, 3.00, '2028-03-05'),
('Costela bovina congelada', -18.00, 4.00, '2028-03-15');


-- =============================================
-- 7. REFRIGERADORES
-- =============================================
INSERT INTO tb_refrigerador
    (modelo, localizacao, temperatura_min, temperatura_max, cod_cd, cod_termometro)
VALUES

-- Refrigeradores de Carnes e Aves — 4°C
('ColdStorage CS-500', 'Setor Carnes - Câmara 01', 3.00, 4.50, 1, 1),
('ColdStorage CS-500', 'Setor Carnes - Câmara 02', 2.00, 6.00, 1, 2),
('FrioMaster FM-400', 'Setor Carnes - Câmara 03', 2.00, 6.00, 2, 3),
('FrioMaster FM-400', 'Setor Carnes - Câmara 04', 2.00, 6.00, 2, 4),
('RefrigPro RP-300', 'Setor Carnes - Câmara 05', 2.00, 6.00, 3, 5),
('RefrigPro RP-300', 'Setor Carnes - Câmara 06', 2.00, 6.00, 3, 6),

-- Refrigeradores de Pescados — 0°C
('ColdStorage CS-500', 'Setor Pescados - Câmara 01', -2.00, 2.00, 4, 7),
('FrioMaster FM-400', 'Setor Pescados - Câmara 02', -2.00, 2.00, 4, 8),
('RefrigPro RP-300', 'Setor Pescados - Câmara 03', -2.00, 2.00, 5, 9),

-- Refrigeradores de Congelados — -18°C
('ColdStorage CS-500', 'Setor Congelados - Câmara 01', -22.00, -16.00, 1, 10),
('FrioMaster FM-400', 'Setor Congelados - Câmara 02', -22.00, -16.00, 2, 11),
('RefrigPro RP-300', 'Setor Congelados - Câmara 03', -22.00, -16.00, 3, 12);


-- =============================================
-- 8. PRODUTO x REFRIGERADOR
-- =============================================
INSERT INTO tb_produto_refrigerador
    (cod_produto, cod_refrigerador)
VALUES

-- =========================
-- CARNES E AVES — 4°C
-- =========================

-- Refrigerador 1
(1, 1),
(2, 1),
(3, 1),
(4, 1),
(5, 1),

-- Refrigerador 2
(6, 2),
(7, 2),
(8, 2),
(9, 2),
(10, 2),

-- Refrigerador 3
(11, 3),
(12, 3),
(13, 3),
(14, 3),

-- Refrigerador 4
(15, 4),
(16, 4),
(17, 4),

-- Refrigerador 5
(1, 5),
(6, 5),
(11, 5),
(15, 5),

-- Refrigerador 6
(2, 6),
(7, 6),
(12, 6),
(16, 6),

-- =========================
-- PESCADOS — 0°C
-- =========================

-- Refrigerador 7
(18, 7),
(19, 7),

-- Refrigerador 8
(20, 8),
(21, 8),

-- Refrigerador 9
(22, 9),

-- =========================
-- CONGELADOS — -18°C
-- =========================

-- Refrigerador 10
(23, 10),
(24, 10),

-- Refrigerador 11
(25, 11),
(26, 11),

-- Refrigerador 12
(27, 12);


-- =============================================
-- 9. LEITURAS DE TEMPERATURA
-- =============================================

-- 9.1 Leituras normais (dentro da faixa, não geram alerta)
INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
-- Refrigerador 1 - faixa: 3°C a 4,5°C
(1, 4.00, '2026-08-30 08:00:00'),
(1, 4.50, '2026-08-30 20:00:00'),
(1, 3.80, '2026-08-31 08:00:00'),
(1, 4.20, '2026-08-31 20:00:00'),
(1, 4.10, '2026-09-01 08:00:00'),
(1, 3.90, '2026-09-01 20:00:00'),

-- Refrigerador 2 - faixa: 2°C a 6°C
(2, 3.50, '2026-08-30 08:00:00'),
(2, 4.00, '2026-08-30 20:00:00'),
(2, 4.30, '2026-08-31 08:00:00'),
(2, 3.70, '2026-08-31 20:00:00'),
(2, 4.20, '2026-09-01 08:00:00'),
(2, 3.80, '2026-09-01 20:00:00'),

-- Refrigerador 3 - faixa: 2°C a 6°C
(3, 4.20, '2026-08-30 08:00:00'),
(3, 3.80, '2026-08-30 20:00:00'),
(3, 4.50, '2026-08-31 08:00:00'),
(3, 4.00, '2026-08-31 20:00:00'),
(3, 3.60, '2026-09-01 08:00:00'),
(3, 4.40, '2026-09-01 20:00:00'),

-- Refrigerador 4 - faixa: 2°C a 6°C
(4, 3.90, '2026-08-30 08:00:00'),
(4, 4.10, '2026-08-30 20:00:00'),
(4, 4.40, '2026-08-31 08:00:00'),
(4, 3.60, '2026-08-31 20:00:00'),
(4, 4.00, '2026-09-01 08:00:00'),
(4, 4.30, '2026-09-01 20:00:00'),

-- Refrigerador 5 - faixa: 2°C a 6°C
(5, 4.00, '2026-08-30 08:00:00'),
(5, 4.30, '2026-08-30 20:00:00'),
(5, 3.70, '2026-08-31 08:00:00'),
(5, 4.20, '2026-08-31 20:00:00'),
(5, 3.90, '2026-09-01 08:00:00'),
(5, 4.10, '2026-09-01 20:00:00'),

-- Refrigerador 6 - faixa: 2°C a 6°C
(6, 3.80, '2026-08-30 08:00:00'),
(6, 4.10, '2026-08-30 20:00:00'),
(6, 4.50, '2026-08-31 08:00:00'),
(6, 3.90, '2026-08-31 20:00:00'),
(6, 4.20, '2026-09-01 08:00:00'),
(6, 3.70, '2026-09-01 20:00:00'),

-- Refrigerador 7 - faixa: -2°C a 2°C
(7, 0.00, '2026-08-30 08:00:00'),
(7, -0.50, '2026-08-30 20:00:00'),
(7, 0.50, '2026-08-31 08:00:00'),
(7, -1.00, '2026-08-31 20:00:00'),
(7, 0.20, '2026-09-01 08:00:00'),
(7, -0.30, '2026-09-01 20:00:00'),

-- Refrigerador 8 - faixa: -2°C a 2°C
(8, 0.50, '2026-08-30 08:00:00'),
(8, -0.20, '2026-08-30 20:00:00'),
(8, 0.80, '2026-08-31 08:00:00'),
(8, -0.70, '2026-08-31 20:00:00'),
(8, 0.30, '2026-09-01 08:00:00'),
(8, -0.40, '2026-09-01 20:00:00'),

-- Refrigerador 9 - faixa: -2°C a 2°C
(9, -0.50, '2026-08-30 08:00:00'),
(9, 0.00, '2026-08-30 20:00:00'),
(9, 0.70, '2026-08-31 08:00:00'),
(9, -0.30, '2026-08-31 20:00:00'),
(9, 0.40, '2026-09-01 08:00:00'),
(9, -0.80, '2026-09-01 20:00:00'),

-- Refrigerador 10 - faixa: -22°C a -16°C
(10, -18.00, '2026-08-30 08:00:00'),
(10, -19.00, '2026-08-30 20:00:00'),
(10, -17.50, '2026-08-31 08:00:00'),
(10, -18.50, '2026-08-31 20:00:00'),
(10, -20.00, '2026-09-01 08:00:00'),
(10, -17.00, '2026-09-01 20:00:00'),

-- Refrigerador 11 - faixa: -22°C a -16°C
(11, -18.50, '2026-08-30 08:00:00'),
(11, -19.50, '2026-08-30 20:00:00'),
(11, -17.00, '2026-08-31 08:00:00'),
(11, -18.00, '2026-08-31 20:00:00'),
(11, -20.50, '2026-09-01 08:00:00'),
(11, -17.50, '2026-09-01 20:00:00'),

-- Refrigerador 12 - faixa: -22°C a -16°C
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
-- Refrigerador 1 | Ideal: 4°C | Diferença: 0,80°C | Gravidade Baixa
(1, 4.80, '2026-09-02 08:00:00'),

-- Refrigerador 2 | Ideal: 4°C | Diferença: 2,80°C | Gravidade Média
(2, 6.80, '2026-09-02 08:30:00'),

-- Refrigerador 7 | Ideal: 0°C | Diferença: 5°C | Gravidade Alta
(7, 5.00, '2026-09-02 09:00:00'),

-- Refrigerador 10 | Ideal: -18°C | Diferença: 10°C | Gravidade Crítica
(10, -8.00, '2026-09-02 09:30:00');

-- 9.3 Histórico adicional (mais dias de leituras normais, dentro da faixa de cada refrigerador)
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
FROM tb_refrigerador r,
     generate_series(0, 29) AS gs;


-- =============================================
-- 10. FLUXO DE ATENDIMENTO (exemplo sobre os alertas gerados na seção 9.2)
-- =============================================
 
-- Reconhece e resolve o alerta de gravidade "baixa" (refrigerador 1)
DO $$
DECLARE
    v_cod_alerta INTEGER;
BEGIN
    SELECT id
    INTO v_cod_alerta
    FROM tb_alerta
    WHERE cod_refrigerador = 1
    ORDER BY id DESC
    LIMIT 1;

    CALL sp_registrar_atendimento(v_cod_alerta, 61);
END $$;
 
INSERT INTO tb_justificativa (
    cod_atendimento, motivo, descricao
)
VALUES (
    (SELECT a.id
     FROM tb_atendimento a
     JOIN tb_alerta al ON al.id = a.cod_alerta
     WHERE al.cod_refrigerador = 1
     ORDER BY a.id DESC LIMIT 1),
    'Porta aberta para reposição',
    'Alerta gerado durante reposição manual de estoque; temperatura normalizada após fechamento da câmara.'
);
 
-- Reconhece o alerta crítico do refrigerador 10, sem resolver
DO $$
DECLARE
    v_cod_alerta INTEGER;
BEGIN
    SELECT id
    INTO v_cod_alerta
    FROM tb_alerta
    WHERE cod_refrigerador = 10
    ORDER BY id DESC
    LIMIT 1;

    CALL sp_registrar_atendimento(v_cod_alerta, 41);
END $$;


-- =============================================
-- 11. RELATÓRIOS
-- =============================================
INSERT INTO tb_relatorio (
    cod_usuario_gerador, hash_conteudo, periodo_inicio, periodo_fim, status
)
VALUES
(1, 'a1b2c3d4e5f67890123456789012345678901234567890123456789012345678', '2026-08-01', '2026-08-31', 'gerado'),
(2, 'b2c3d4e5f678901234567890123456789012345678901234567890123456789', '2026-08-01', '2026-08-31', 'assinado'),
(3, 'c3d4e5f6789012345678901234567890123456789012345678901234567890', '2026-07-01', '2026-07-31', 'arquivado');


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
    (1, 31, 'visualizou'),
    (1, 32, 'baixou'),
    (2, 32, 'visualizou'),
    (3, 51, 'baixou');


-- Simulando escalonamento para gerar um log em tb_log_escalonamento
UPDATE tb_alerta
SET nivel_atual = 'gestor'
WHERE id = (
    SELECT id
    FROM tb_alerta
    WHERE nivel_gravidade = 'critica'
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
	(1, TRUE, '192.168.1.10', 'Mozilla/5.0', NULL),
	(31, TRUE, '192.168.1.11', 'Mozilla/5.0', NULL),
	(32, TRUE, '192.168.1.12', 'Mozilla/5.0', NULL),
	(51, TRUE, '192.168.1.13', 'Mozilla/5.0', NULL),
	(41, FALSE, '192.168.1.14', 'Mozilla/5.0', 'Senha incorreta');


COMMIT;