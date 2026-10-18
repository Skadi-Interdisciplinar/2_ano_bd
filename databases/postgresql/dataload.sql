-- ====================================================================
-- MASSA DE DADOS PARA TESTE DE VOLUME
-- A carga possui mais de 500 registros distribuídos entre as tabelas.
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

ALTER TABLE tb_usuario
DISABLE TRIGGER trg_auditoria_usuario;

INSERT INTO tb_usuario (
    nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor
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
    'colaborador' || LPAD(gs::TEXT, 3, '0'),
    (10000000000 + (gs * 7919))::TEXT,
    'colaborador' || LPAD(gs::TEXT, 3, '0') || '@skadi.com.br',
    '$2a$12$V/BiuqbeOeEWxbeUfBMgy..ESFzLoz0c4Z5zAy4ArSFuZksxXyNKC',
    CASE
        WHEN gs <= 10 THEN 'ADMIN'
        WHEN gs <= 30 THEN 'GESTOR'
        ELSE 'OPERADOR'
    END,
    ((gs - 1) % 5) + 1,
    CASE
        WHEN gs > 30 THEN 11 + ((gs - 1) % 5)
        ELSE NULL
    END
FROM generate_series(1, 100) AS gs
ORDER BY gs;

ALTER TABLE tb_usuario
ENABLE TRIGGER trg_auditoria_usuario;

-- Define o usuário atual para as próximas auditorias.
SELECT set_config('app.usuario_atual', '1', false);

-- Usuário administrador da plataforma, sem vínculo com CD ou gestor.
INSERT INTO tb_usuario (
    nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor
)
VALUES (
    'Super ADM Skadi',
    'mariproque',
    NULL,
    'marianaproque400@gmail.com',
    '$2a$12$V/BiuqbeOeEWxbeUfBMgy..ESFzLoz0c4Z5zAy4ArSFuZksxXyNKC',
    'SUPER_ADMIN',
    NULL,
    NULL
);


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
    (nome, temperatura_min, temperatura_max, vida_util_horas)
VALUES
('Alcatra bovina resfriada', 3.00, 4.50, INTERVAL '240:00' HOUR TO MINUTE),
('Contrafilé bovino resfriado', 2.00, 6.00, INTERVAL '216:00' HOUR TO MINUTE),
('Lombo suíno resfriado', 3.00, 4.50, INTERVAL '168:00' HOUR TO MINUTE),
('Peito de frango resfriado', 3.00, 4.50, INTERVAL '120:00' HOUR TO MINUTE),
('Filé de tilápia fresco', -2.00, 2.00, INTERVAL '72:00' HOUR TO MINUTE),
('Filé de salmão congelado', -22.00, -16.00, INTERVAL '720:00' HOUR TO MINUTE);


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

-- Leituras fora da faixa: cada uma gera um alerta via trigger.
INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
-- Câmara frigorífica 1 | Limite máximo: 4,5°C | Diferença: 0,30°C | Gravidade Baixa
(1, 4.80, '2026-09-02 08:00:00'),

-- Câmara frigorífica 2 | Limite máximo: 6°C | Diferença: 0,80°C | Gravidade Baixa
(2, 6.80, '2026-09-02 08:30:00'),

-- Câmara frigorífica 7 | Limite máximo: 2°C | Diferença: 3°C | Gravidade Atenção
(7, 5.00, '2026-09-02 09:00:00'),

-- Câmara frigorífica 10 | Limite máximo: -16°C | Diferença: 8°C | Gravidade Crítica
(10, -8.00, '2026-09-02 09:30:00');

-- =============================================
-- 10. RECONHECIMENTO DE ALERTA (exemplo)
-- =============================================
-- Reconhece o alerta da câmara frigorífica 1; a resolução automática
-- ocorre quando uma leitura posterior registrar temperatura dentro da faixa.
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

    CALL sp_reconhecer_alerta(v_cod_alerta, 61);
END $$;

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

    CALL sp_reconhecer_alerta(v_cod_alerta, 41);
END $$;


-- =============================================
-- 11. RELATÓRIOS
-- =============================================
INSERT INTO tb_relatorio (
    cod_usuario_gerador, hash_conteudo, periodo_inicio, periodo_fim, status, conteudo
)
VALUES
(2, 'e59d3e70d8e55ce6fc36361645a3708294c6c4e5971a1ea0cf7844a4c7d6d862', '2026-08-01', '2026-08-31', 'GERADO', 'Relatorio operacional do periodo de agosto de 2026 - usuario 2.'),
(3, '998be91f97fd94a6e41e184ece055dd2a3d30fa1a36beda81784fde6ce0d259c', '2026-08-01', '2026-08-31', 'ASSINADO', 'Relatorio operacional do periodo de agosto de 2026 - usuario 3.'),
(4, '13c895e9b2a36953fe26ce97179eb2297eecfffa5a5205d0f2912cd6d41c0a9a', '2026-07-01', '2026-07-31', 'ARQUIVADO', 'Relatorio operacional do periodo de julho de 2026 - usuario 4.');


-- =============================================
-- 12. ASSINATURAS
-- =============================================
-- Chaves e assinaturas são placeholders de carga; não servem para validação criptográfica.
INSERT INTO tb_assinatura (
    cod_relatorio, certificado_titular, numero_serie,
    autoridade_certificadora, algoritmo_assinatura, certificado_publico,
    assinatura, carimbo_tempo
)
VALUES
(2, 'Sistema ColdChain', 'CERT-2026-0001', 'ICP-Brasil', 'SHA256withRSA', 'CHAVE_PUBLICA_DE_TESTE_NAO_UTILIZAR', 'assinatura_simulada_relatorio_2', '2026-09-02 10:00:00'),
(3, 'Sistema ColdChain', 'CERT-2026-0002', 'ICP-Brasil', 'SHA256withRSA', 'CHAVE_PUBLICA_DE_TESTE_NAO_UTILIZAR', 'assinatura_simulada_relatorio_3', '2026-09-02 10:05:00');


-- Simulando escalonamento para gerar um log em tb_log_escalonamento
UPDATE tb_alerta
SET nivel_atual = 'GESTOR'
WHERE id = (
    SELECT id
    FROM tb_alerta
    WHERE nivel_gravidade = 'URGENTE'
    ORDER BY id DESC
    LIMIT 1
);


-- =============================================
-- 13. LOG DE ACESSO
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


-- Acessos distribuídos ao longo dos últimos dias para exercitar a view de DAU.
INSERT INTO tb_log_acesso (
    cod_usuario, tentativa_sucesso, ip_origem, user_agent,
    motivo_falha, data_hora
)
SELECT
    ((gs - 1) % 100) + 1,
    gs % 8 <> 0,
    ('10.10.0.' || gs)::INET,
    CASE gs % 3
        WHEN 0 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0'
        WHEN 1 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Firefox/130.0'
        ELSE 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) Safari/604.1'
    END,
    CASE
        WHEN gs % 8 <> 0 THEN NULL
        WHEN gs % 2 = 0 THEN 'SENHA_INCORRETA'
        ELSE 'USUARIO_INEXISTENTE'
    END,
    CURRENT_TIMESTAMP - (gs * INTERVAL '4 hours')
FROM generate_series(1, 100) AS gs;

COMMIT;
