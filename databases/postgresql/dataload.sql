-- =============================
-- MASSA DE DADOS
-- =============================
BEGIN;

-- =============================
-- 1. ESTADOS
-- =============================
INSERT INTO tb_estado (estado) VALUES
    ('AC'), ('AL'), ('AP'), ('AM'), ('BA'), ('CE'), ('DF'), ('ES'), ('GO'),
    ('MA'), ('MT'), ('MS'), ('MG'), ('PA'), ('PB'), ('PR'), ('PE'), ('PI'),
    ('RJ'), ('RN'), ('RS'), ('RO'), ('RR'), ('SC'), ('SP'), ('SE'), ('TO');

-- =============================
-- 2. CENTROS DE DISTRIBUIÇÃO
-- =============================
INSERT INTO tb_cd (nome, cnpj) VALUES
    ('CD JBS', '90000001000129'),
    ('CD Friboi', '90000002000173'),
    ('CD Seara', '90000003000118'),
    ('CD Swift', '90000004000162'),
    ('CD Marfrig', '90000005000107'),
    ('CD Minerva Foods', '90000006000151'),
    ('CD BRF', '90000007000104'),
    ('CD Aurora Coop', '90000008000140'),
    ('CD Frimesa', '90000009000195'),
    ('CD Copacol', '90000010000110'),
    ('CD Lar Cooperativa', '90000011000164'),
    ('CD Coopavel', '90000012000109'),
    ('CD Pamplona Alimentos', '90000013000153'),
    ('CD Masterboi', '90000014000106'),
    ('CD Frigol', '90000015000142'),
    ('CD Frisa', '90000016000197'),
    ('CD Pif Paf Alimentos', '90000017000131'),
    ('CD Alegra', '90000018000186'),
    ('CD Zanchetta', '90000019000120'),
    ('CD Bello Alimentos', '90000020000155');

-- =============================
-- 3. ENDEREÇOS
-- =============================
INSERT INTO tb_endereco
    (cep, rua, numero, cidade, bairro, complemento, cod_estado, cod_cd)
SELECT
    (10000000 + gs)::VARCHAR(8),
    'Rua Industrial ' || gs,
    100 + gs,
    localidade.cidade,
    'Centro Industrial',
    CASE WHEN gs % 3 = 0 THEN 'Galpão ' || gs ELSE NULL END,
    estado.id,
    localidade.cod_cd
FROM generate_series(1, 100) AS gs
JOIN (VALUES
    (1, 'São Paulo', 'SP'), (2, 'Rio de Janeiro', 'RJ'),
    (3, 'Belo Horizonte', 'MG'), (4, 'Curitiba', 'PR'),
    (5, 'Florianópolis', 'SC')
) AS localidade(cod_cd, cidade, uf)
    ON localidade.cod_cd = ((gs - 1) % 5) + 1
JOIN tb_estado estado ON estado.estado = localidade.uf;

INSERT INTO tb_endereco
    (cep, rua, numero, cidade, bairro, complemento, cod_estado, cod_cd)
SELECT
    (11000000 + gs)::VARCHAR(8),
    'Avenida de Distribuição ' || gs,
    100 + gs,
    localidade.cidade,
    'Centro Logístico',
    'Galpão ' || gs,
    estado.id,
    localidade.cod_cd
FROM generate_series(1, 75) AS gs
JOIN (VALUES
    (6, 'Porto Alegre', 'RS'), (7, 'Salvador', 'BA'),
    (8, 'Recife', 'PE'), (9, 'Fortaleza', 'CE'),
    (10, 'Manaus', 'AM'), (11, 'Belém', 'PA'),
    (12, 'Goiânia', 'GO'), (13, 'Brasília', 'DF'),
    (14, 'Vitória', 'ES'), (15, 'Natal', 'RN'),
    (16, 'João Pessoa', 'PB'), (17, 'Maceió', 'AL'),
    (18, 'Teresina', 'PI'), (19, 'Campo Grande', 'MS'),
    (20, 'Cuiabá', 'MT')
) AS localidade(cod_cd, cidade, uf)
    ON localidade.cod_cd = 6 + ((gs - 1) / 5)
JOIN tb_estado estado ON estado.estado = localidade.uf;

-- =============================
-- 4. USUÁRIOS
-- =============================
-- O worker deve permanecer com ID 1.
SELECT set_config('app.usuario_atual', '1', false);

INSERT INTO tb_usuario
    (nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor)
VALUES
    ('Worker Skadi', 'skadi_worker', NULL, 'skadi.enterprise@gmail.com',
     '$2a$12$HZ7dYoDeadUb.jpyhXV63uEH2PN525cWcV0dNEt5I3J1uuFQ02Sge',
     'SUPER_ADMIN', NULL, NULL);

INSERT INTO tb_usuario
    (nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor)
VALUES
    ('Beatriz Hinsching', 'beatriz.hinsching', NULL, 'beatriz.carvalho@institutojef.org.br',
     '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL),
    ('Diego Valadares', 'diego.valadares', NULL, 'diego.valadares@institutojef.org.br',
     '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL),
    ('Enzo Nascimento', 'enzo.nascimento', NULL, 'enzo.nascimento@institutojef.org.br',
     '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL),
    ('Giovanna Santos', 'giovanna.santos', NULL, 'giovanna.santos@institutojef.org.br',
     '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL),
    ('Gustavo Munhoz', 'gustavo.munhoz', NULL, 'gustavo.munhoz@institutojef.org.br',
     '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL),
    ('Mariana Proque', 'mariana.proque', NULL, 'mariana.proque@institutojef.org.br',
     '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL);

ALTER TABLE tb_usuario DISABLE TRIGGER trg_auditoria_usuario;
INSERT INTO tb_usuario
    (nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor)
SELECT
    'Administrador do CD ' || LPAD(cd.id::TEXT, 2, '0'),
    'admin' || LPAD(cd.id::TEXT, 3, '0'),
    LPAD((20000000000 + cd.id)::TEXT, 11, '0'),
    'admin.cd' || LPAD(cd.id::TEXT, 2, '0') || '@skadi.example',
    '$2a$12$HZ7dYoDeadUb.jpyhXV63uEH2PN525cWcV0dNEt5I3J1uuFQ02Sge',
    'ADMIN', NULL, NULL
FROM tb_cd cd
ORDER BY cd.id;

INSERT INTO tb_admin_cd (cod_admin, cod_cd)
SELECT admin.id, cd.id
FROM tb_cd cd
JOIN tb_usuario admin
    ON admin.username = 'admin' || LPAD(cd.id::TEXT, 3, '0')
UNION
SELECT admin.id, outro_cd.id
FROM tb_cd cd
JOIN tb_usuario admin
    ON admin.username = 'admin' || LPAD(cd.id::TEXT, 3, '0')
JOIN tb_cd outro_cd
    ON outro_cd.id = CASE WHEN cd.id = (SELECT MAX(id) FROM tb_cd) THEN 1 ELSE cd.id + 1 END;

INSERT INTO tb_usuario
    (nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor)
SELECT
    'Gestor ' || LPAD(((cd.id - 1) * 2 + sufixo.ordem)::TEXT, 3, '0'),
    'gestor' || LPAD(((cd.id - 1) * 2 + sufixo.ordem)::TEXT, 3, '0'),
    LPAD((30000000000 + (cd.id * 10) + sufixo.ordem)::TEXT, 11, '0'),
    'gestor' || LPAD(((cd.id - 1) * 2 + sufixo.ordem)::TEXT, 3, '0') || '@skadi.example',
    '$2a$12$HZ7dYoDeadUb.jpyhXV63uEH2PN525cWcV0dNEt5I3J1uuFQ02Sge',
    'GESTOR', cd.id, NULL
FROM tb_cd cd
CROSS JOIN (VALUES (1), (2)) AS sufixo(ordem)
ORDER BY cd.id, sufixo.ordem;

INSERT INTO tb_usuario
    (nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor)
SELECT
    'Operador ' || LPAD(((cd.id - 1) * 10 + numero_operador)::TEXT, 3, '0'),
    'operador' || LPAD(((cd.id - 1) * 10 + numero_operador)::TEXT, 3, '0'),
    LPAD((40000000000 + (cd.id * 100) + numero_operador)::TEXT, 11, '0'),
    'operador' || LPAD(((cd.id - 1) * 10 + numero_operador)::TEXT, 3, '0') || '@skadi.example',
    '$2a$12$HZ7dYoDeadUb.jpyhXV63uEH2PN525cWcV0dNEt5I3J1uuFQ02Sge',
    'OPERADOR', cd.id,
    gestor.id
FROM tb_cd cd
CROSS JOIN generate_series(1, 10) AS serie(numero_operador)
JOIN tb_usuario gestor
    ON gestor.username = 'gestor' || LPAD(
        ((cd.id - 1) * 2 + CASE WHEN numero_operador % 2 = 1 THEN 1 ELSE 2 END)::TEXT,
        3,
        '0'
    )
ORDER BY cd.id, numero_operador;

ALTER TABLE tb_usuario ENABLE TRIGGER trg_auditoria_usuario;

-- =============================
-- 5. SOLICITAÇÕES DE SUPORTE
-- =============================
INSERT INTO tb_solicitacao_suporte
    (cod_usuario_solicitante, categoria, descricao, status, data_hora_abertura)
SELECT
    operador.id,
    (ARRAY['DUVIDA', 'SUGESTAO', 'RECLAMACAO', 'OUTRO'])[((gs - 1) % 4) + 1],
    CASE ((gs - 1) % 4)
        WHEN 0 THEN 'Dúvida sobre o procedimento de conferência da câmara.'
        WHEN 1 THEN 'Sugestão para facilitar a consulta do histórico de leituras.'
        WHEN 2 THEN 'Relato de dificuldade ao acessar uma funcionalidade do sistema.'
        ELSE 'Solicitação de orientação sobre o uso da plataforma.'
    END,
    'REGISTRADO',
    CURRENT_TIMESTAMP - ((gs % 20) * INTERVAL '1 day')
FROM generate_series(1, 60) AS gs
CROSS JOIN LATERAL (
    SELECT id
    FROM tb_usuario
    WHERE nivel_acesso = 'OPERADOR'
    ORDER BY id
    OFFSET ((gs - 1) % 200)
    LIMIT 1
) operador;

-- =============================
-- 6. TERMÔMETROS
-- =============================
INSERT INTO tb_termometro (modelo)
SELECT
    CASE gs % 3
        WHEN 0 THEN 'ThermoTrack T-300'
        WHEN 1 THEN 'SensorTemp ST-200'
        ELSE 'ColdMonitor CM-100'
    END || '-' || LPAD(gs::TEXT, 3, '0')
FROM generate_series(1, 50) AS gs;

-- =============================
-- 7. CATEGORIAS
-- =============================
INSERT INTO tb_categoria
    (nome, temperatura_min, temperatura_max, vida_util_horas)
VALUES
    ('Alcatra bovina resfriada', 3.00, 4.50, INTERVAL '240:00' HOUR TO MINUTE),
    ('Contrafilé bovino resfriado', 2.00, 6.00, INTERVAL '216:00' HOUR TO MINUTE),
    ('Lombo suíno resfriado', 3.00, 4.50, INTERVAL '168:00' HOUR TO MINUTE),
    ('Peito de frango resfriado', 3.00, 4.50, INTERVAL '120:00' HOUR TO MINUTE),
    ('Filé de tilápia fresco', -2.00, 2.00, INTERVAL '72:00' HOUR TO MINUTE),
    ('Filé de salmão congelado', -22.00, -16.00, INTERVAL '720:00' HOUR TO MINUTE);

-- =============================
-- 8. CÂMARAS FRIGORÍFICAS
-- =============================
INSERT INTO tb_camara_frigorifica
    (modelo, localizacao, temperatura_min, temperatura_max, cod_cd, cod_termometro)
VALUES
    ('ColdStorage CS-500', 'Setor Carnes - Câmara 01', 3.00, 4.50, 1, 1),
    ('ColdStorage CS-500', 'Setor Carnes - Câmara 02', 2.00, 6.00, 1, 2),
    ('FrioMaster FM-400', 'Setor Carnes - Câmara 03', 2.00, 6.00, 2, 3),
    ('FrioMaster FM-400', 'Setor Carnes - Câmara 04', 2.00, 6.00, 2, 4),
    ('RefrigPro RP-300', 'Setor Carnes - Câmara 05', 2.00, 6.00, 3, 5),
    ('RefrigPro RP-300', 'Setor Carnes - Câmara 06', 2.00, 6.00, 3, 6),
    ('ColdStorage CS-500', 'Setor Pescados - Câmara 01', -2.00, 2.00, 4, 7),
    ('FrioMaster FM-400', 'Setor Pescados - Câmara 02', -2.00, 2.00, 4, 8),
    ('RefrigPro RP-300', 'Setor Pescados - Câmara 03', -2.00, 2.00, 5, 9),
    ('ColdStorage CS-500', 'Setor Congelados - Câmara 01', -22.00, -16.00, 1, 10),
    ('FrioMaster FM-400', 'Setor Congelados - Câmara 02', -22.00, -16.00, 2, 11),
    ('RefrigPro RP-300', 'Setor Congelados - Câmara 03', -22.00, -16.00, 3, 12);

INSERT INTO tb_camara_frigorifica
    (modelo, localizacao, temperatura_min, temperatura_max, cod_cd, cod_termometro)
SELECT
    CASE gs % 3 WHEN 0 THEN 'ColdStorage CS-500'
                WHEN 1 THEN 'FrioMaster FM-400'
                ELSE 'RefrigPro RP-300' END,
    CASE WHEN gs <= 20 THEN 'Setor Carnes - Câmara '
         WHEN gs <= 35 THEN 'Setor Pescados - Câmara '
         ELSE 'Setor Congelados - Câmara ' END || LPAD(gs::TEXT, 2, '0'),
    CASE WHEN gs <= 20 THEN 2.00 WHEN gs <= 35 THEN -2.00 ELSE -22.00 END,
    CASE WHEN gs <= 20 THEN 6.00 WHEN gs <= 35 THEN 2.00 ELSE -16.00 END,
    6 + ((gs - 13) % 15),
    gs
FROM generate_series(13, 50) gs
ORDER BY gs;

-- =============================
-- 9. LOTES E VÍNCULOS COM CÂMARAS
-- =============================
INSERT INTO tb_lote (codigo_lote, cod_categoria, data_fabricacao, data_validade)
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
VALUES (1, 1), (2, 2), (3, 1), (4, 1), (5, 3), (6, 4),
       (7, 7), (8, 8), (9, 9), (10, 10), (11, 11), (12, 12);

WITH lotes AS (
    SELECT
        gs,
        ((gs - 1) % 6) + 1 AS cod_categoria,
        ((gs - 1) / 6) + 1 AS sequencia_categoria,
        CURRENT_DATE - ((gs % 5) + 1) AS data_fabricacao
    FROM generate_series(1, 120) AS gs
), inseridos AS (
    INSERT INTO tb_lote
        (codigo_lote, cod_categoria, data_fabricacao, data_validade, status)
    SELECT
        'LOTE-2026-' || LPAD((1000 + lotes.gs)::TEXT, 5, '0'),
        lotes.cod_categoria,
        lotes.data_fabricacao,
        lotes.data_fabricacao + CASE lotes.cod_categoria
            WHEN 1 THEN 30 WHEN 2 THEN 30 WHEN 3 THEN 21
            WHEN 4 THEN 14 WHEN 5 THEN 7 ELSE 365
        END,
        'ATIVO'
    FROM lotes
    RETURNING id, codigo_lote, cod_categoria
)
INSERT INTO tb_lote_camara_frigorifica
    (cod_lote, cod_camara_frigorifica, data_entrada)
SELECT
    inseridos.id,
    (
        SELECT cam.id
        FROM tb_camara_frigorifica cam
        JOIN tb_categoria categoria ON categoria.id = inseridos.cod_categoria
        WHERE cam.temperatura_min <= categoria.temperatura_min
          AND cam.temperatura_max >= categoria.temperatura_max
        ORDER BY cam.id
        OFFSET ((lotes.sequencia_categoria - 1) % (
            SELECT COUNT(*)
            FROM tb_camara_frigorifica cam_disponivel
            JOIN tb_categoria categoria_disponivel
                ON categoria_disponivel.id = inseridos.cod_categoria
            WHERE cam_disponivel.temperatura_min <= categoria_disponivel.temperatura_min
              AND cam_disponivel.temperatura_max >= categoria_disponivel.temperatura_max
        ))
        LIMIT 1
    ),
    CURRENT_TIMESTAMP - ((lotes.gs % 5) * INTERVAL '1 day')
FROM inseridos
JOIN lotes
    ON inseridos.codigo_lote = 'LOTE-2026-' || LPAD((1000 + lotes.gs)::TEXT, 5, '0');

-- =============================
-- 10. LEITURAS DE TEMPERATURA
-- =============================
-- Inserir leituras normais antes das anormais preserva o fluxo das triggers.
INSERT INTO tb_leitura_temperatura (cod_termometro, temperatura, data_hora)
SELECT
    cam.cod_termometro,
    (cam.temperatura_min + cam.temperatura_max) / 2,
    TIMESTAMP '2026-08-30 08:00:00' + (cam.id * INTERVAL '1 minute')
FROM tb_camara_frigorifica cam
UNION ALL
SELECT
    cam.cod_termometro,
    (cam.temperatura_min + cam.temperatura_max) / 2,
    TIMESTAMP '2026-08-31 08:00:00' + (cam.id * INTERVAL '1 minute')
FROM tb_camara_frigorifica cam
ORDER BY 3, 1;

INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
    (1, 4.80, '2026-09-02 08:00:00'),
    (2, 6.80, '2026-09-02 08:30:00'),
    (7, 5.00, '2026-09-02 09:00:00'),
    (10, -8.00, '2026-09-02 09:30:00');

INSERT INTO tb_leitura_temperatura (cod_termometro, temperatura, data_hora)
SELECT
    cam.cod_termometro,
    cam.temperatura_max + CASE cam.id % 4
        WHEN 0 THEN 0.50
        WHEN 1 THEN 2.00
        WHEN 2 THEN 4.00
        ELSE 7.00
    END,
    TIMESTAMP '2026-09-03 08:00:00' + (cam.id * INTERVAL '5 minutes')
FROM tb_camara_frigorifica cam
WHERE cam.cod_termometro NOT IN (1, 2, 7, 10)
ORDER BY cam.id;

-- Reconhece alertas com operadores do CD correspondente.
DO $$
DECLARE
    v_cod_camara INTEGER;
    v_cod_alerta INTEGER;
    v_cod_usuario INTEGER;
BEGIN
    FOR v_cod_camara IN
        SELECT unnest(ARRAY[1, 10, 20, 35, 50, 2, 3, 4, 5, 6])
    LOOP
        v_cod_alerta := NULL;
        v_cod_usuario := NULL;

        SELECT alerta.id, operador.id
        INTO v_cod_alerta, v_cod_usuario
        FROM tb_alerta alerta
        JOIN tb_camara_frigorifica cam
            ON cam.id = alerta.cod_camara_frigorifica
        JOIN tb_usuario operador
            ON operador.cod_cd = cam.cod_cd
           AND operador.nivel_acesso = 'OPERADOR'
        WHERE cam.id = v_cod_camara
          AND alerta.status = 'ATIVO'
        ORDER BY alerta.id DESC, operador.id
        LIMIT 1;

        IF v_cod_alerta IS NOT NULL THEN
            CALL sp_reconhecer_alerta(v_cod_alerta, v_cod_usuario);
        END IF;
    END LOOP;
END $$;

-- Normaliza a temperatura de alertas reconhecidos para permitir seu encerramento justificado.
INSERT INTO tb_leitura_temperatura (cod_termometro, temperatura, data_hora)
SELECT
    cam.cod_termometro,
    (cam.temperatura_min + cam.temperatura_max) / 2,
    TIMESTAMP '2026-09-04 08:00:00' + (cam.id * INTERVAL '5 minutes')
FROM tb_camara_frigorifica cam
WHERE cam.id = ANY(ARRAY[2, 3, 4, 5, 6])
ORDER BY cam.id;

-- Registra justificativas após a normalização; a trigger encerra atendimento e alerta.
INSERT INTO tb_justificativa (cod_atendimento, motivo, descricao)
SELECT
    atendimento.id,
    CASE cam.id
        WHEN 2 THEN 'Porta aberta durante reposição'
        WHEN 3 THEN 'Oscilação após movimentação de produtos'
        WHEN 4 THEN 'Ajuste no equipamento de refrigeração'
        WHEN 5 THEN 'Vedação da porta corrigida'
        ELSE 'Ciclo de refrigeração restabelecido'
    END,
    CASE cam.id
        WHEN 2 THEN 'A porta foi fechada após a reposição e as leituras seguintes voltaram à faixa permitida.'
        WHEN 3 THEN 'Após reorganização dos produtos, a temperatura estabilizou dentro dos limites da câmara.'
        WHEN 4 THEN 'A equipe ajustou o equipamento e confirmou a normalização da temperatura.'
        WHEN 5 THEN 'A vedação foi corrigida e a leitura seguinte confirmou a temperatura adequada.'
        ELSE 'O ciclo de refrigeração foi restabelecido e a leitura seguinte ficou dentro dos limites.'
    END
FROM tb_atendimento atendimento
JOIN tb_alerta alerta ON alerta.id = atendimento.cod_alerta
JOIN tb_camara_frigorifica cam ON cam.id = alerta.cod_camara_frigorifica
WHERE cam.id = ANY(ARRAY[2, 3, 4, 5, 6])
  AND atendimento.status = 'EM_ANDAMENTO'
  AND alerta.status = 'RECONHECIDO'
ORDER BY cam.id;

-- =============================
-- 11. RELATÓRIOS
-- =============================
INSERT INTO tb_relatorio
    (cod_usuario_gerador, hash_conteudo, conteudo, periodo_inicio, periodo_fim, status)
SELECT
    admin.id,
    hashes.hash_conteudo,
    'Relatório operacional do ' || cd.nome || ' referente a outubro de 2026.',
    DATE '2026-10-01',
    DATE '2026-10-17',
    CASE cd.id % 3
        WHEN 0 THEN 'ARQUIVADO'
        WHEN 2 THEN 'ASSINADO'
        ELSE 'GERADO'
    END
FROM tb_cd cd
JOIN tb_admin_cd admin_cd
    ON admin_cd.cod_cd = cd.id
JOIN tb_usuario admin
    ON admin.id = admin_cd.cod_admin
   AND admin.username = 'admin' || LPAD(cd.id::TEXT, 3, '0')
JOIN (VALUES
        (1, '6043ddebb2d117e47604510a29612a73c3af24122fbc0d8ae458e6f89f27361c'),
        (2, 'ff86f155e89ec4037ff46380d51d7d00d7e2e5593e3f8a27982fd34f56f2eba0'),
        (3, '3221f88c62beb7b85d6dcf8f2abef378098caa23512db6017786c0aa11fbecdb'),
        (4, 'f8c1c0e982fb033c1c54c96ce2e4e79673fe1ea31ffb9870043ca3b142f66ac9'),
        (5, '9f87c28611e18e32367e49228b41cced638360752ee64b54a168a13cfb3ead15'),
        (6, '96e949f3483f8b751f4c3b11d2a93b2e485271cc2543811af3b3b3d27240eb23'),
        (7, '32c35259fa84469bfeec3568f2abee04ae8f71850d177419b074159485107819'),
        (8, 'a3c54b77a3b60cb99f5aa5261146b1a3f3c1b310a3dc156e31bedf1893aa7f9e'),
        (9, 'b09d7a6eb3e19d84bdff4c660e3486834fb96a5dd8596290fa8115105e0ff420'),
        (10, 'ff228cf657f20b32fd4d0616103e942f91df4b687149a39fa2beeef618b66eab'),
        (11, 'a0c1e3560a8d4875a2f2ac7a8a79e47b7b66f47188e7d1bdde657770f95b842c'),
        (12, '235314c50bda97a299916dc1de99c8e9eb6e9bcac1e6752a2f240c69b02c39db'),
        (13, 'd4075034be3d4783e123d466f1c1854b0ab5209739a40cd9bba61698efe5b0c5'),
        (14, '42f57979c902326ca4e4d4e379bfa6e636076f497ef4bb136a7243a0978dfc17'),
        (15, 'dfbbc45cf685a40c0e8ea595c7a77c076eccc18793f3cf74297bb029118f19e1'),
        (16, '2ffbe0133ba3f33098a3a74f75a6133bc3434dba6401baff326d70b2a9f17bf4'),
        (17, 'c72c0b74aab2c923f3af086e4ce1a3b2725c5547a0af8946561ac1c06f736b18'),
        (18, 'd62d6077240aa90d978500fa98e44bd9084b1b6bbf85bc43f7da3d8dcc9df0b2'),
        (19, 'afbe6d2748e10dda033a588306c5d934f5c69f5a3873c92db11e97c5dfe3f558'),
        (20, 'b28cf07393b7339127d810829e97ef7f4abe917511550e3683dd0e7d7c62d245')
) AS hashes(cod_cd, hash_conteudo)
    ON hashes.cod_cd = cd.id
ORDER BY cd.id;

-- Assinaturas RSA de demonstração
INSERT INTO tb_relatorio (
    cod_usuario_gerador, hash_conteudo, periodo_inicio, periodo_fim, status, conteudo
)
VALUES
((SELECT id FROM tb_usuario WHERE username = 'admin001'),
 'e59d3e70d8e55ce6fc36361645a3708294c6c4e5971a1ea0cf7844a4c7d6d862',
 '2026-08-01', '2026-08-31', 'GERADO',
 'Relatorio operacional do periodo de agosto de 2026 - usuario 2.'),
((SELECT id FROM tb_usuario WHERE username = 'admin002'),
 '998be91f97fd94a6e41e184ece055dd2a3d30fa1a36beda81784fde6ce0d259c',
 '2026-08-01', '2026-08-31', 'ASSINADO',
 'Relatorio operacional do periodo de agosto de 2026 - usuario 3.'),
((SELECT id FROM tb_usuario WHERE username = 'admin003'),
 '13c895e9b2a36953fe26ce97179eb2297eecfffa5a5205d0f2912cd6d41c0a9a',
 '2026-07-01', '2026-07-31', 'ARQUIVADO',
 'Relatorio operacional do periodo de julho de 2026 - usuario 4.');

INSERT INTO tb_assinatura (
    cod_relatorio, certificado_titular, numero_serie,
    autoridade_certificadora, algoritmo_assinatura, certificado_publico,
    assinatura, data_assinatura, carimbo_tempo
)
SELECT
    relatorio.id,
    'Usuário demonstrativo Skadi',
    'DEMO-RSA-001',
    'Autoridade de teste Skadi',
    'SHA256withRSA',
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA620HSrpoBemXjuZabISvK/cugAMjt7b+MBHwpRs5v0GCtoKbqE1y30iczSYC9ujx2c8T5Lg7gpphqG9Ts65IeiQgO4hwgqiWQLskkjOG6dChW/L+SQ1aPMFMz1dl2Kmq9dnEs9SdMEWX6txBxqDmsbGLf8xgdaSQHCPdw1dVfneCvwd6N86WKsWEh7XHNA9Ul8qkkVl8DgbSV5H9Q8L77SxdKc+x/dGdpWX6e9tb2uaVpxdtyUHVl6y9zHzfMxwWng0ysB1rA5hYcKyrmCUbhpjAdzGsEab+S5mrYaT5RlFHWsUWZoTyXKokQ3nF12mcPcVKmeV/WbD8ki/RSimG2QIDAQAB',
    assinaturas.assinatura,
    CURRENT_DATE,
    'CARIMBO_DE_TEMPO_DE_TESTE'
FROM (VALUES
        (2, 'e0f3GnPFiXo6JyhWp0EbADNYXk4Kk9BAOhh4N38fhiqiUcc1z5PJ6IGYLApuct3kEG3p1R+Uj98GuHF8StL0eAssUhYPv+8k6xde5/Oh8x0KC4SoWe4Hne9u39OOHbOe8JQRw3kllvXFVh0DishoO1evsBI6qfQ0M6uhdx1GM8aXoTFigqqZdzPnWR+gBpz+xgQ2nbDe95qWK8btotFkWG+jy9lPFgYJdQOy3ejct8Jf2rq9YyGiuTdF6+bhRtEEe8wNbhV+Hb9Z1+iuMMDrbgIcoToKwZE0E5BU7+c5+b532gji4CXRgyjr4qPCmKCvafl7d4seYA+Lp3heHjfeGg=='),
        (3, 'czPHFwkrNy0rAxMEsJWRoaSDmJAf3ZpXGsVpPmDXVUCZCXPu1EIea3Kk5ScOua2PXuUSrTTAb9iS6OHpX6Kgp1Edn3t9Dceiwf2VG0gLtLOomcO3keUauZ97o86b2enRyAgukxwuO+/0FZ3ZiIVy8fc9/JZcnt2Ew05RvVImp612TNLoeDyStJbw9l9KkrR6X4N0CeA9MqUe9oCTvACyufPAzFlLUlnxk02yaQ/kJQyHJwmtKGuQVcW6ewXTst3J8spZnn+Cncs1AsFRL4+b2Tf8of4HtJd+7QRqZYbVK4mmkxvgNCTgKTeJGjL70Bb0agWWqKab1G0tnDP2QFDZNQ=='),
        (5, 'kJ5Qv5ewU/FqeTeh0C9cRnSTARy3/URSmmbOziFUwIIQNDM/+WGw+EQCDZF0E1aXttCLTnhNEd31zms6IEzr0cryKy9DfLdhsYfk3qIT+oQ7hTF0ymju/jiIVy8iS7DAd3wENPo5Nl647uFnuRs8xWQeJgatEL0akI18cC/ReaGpiIk1CCwVG/T2gD9inz/RVtFaUaVJgRHAuTETgbpggBzji5Sq85WmFdx9XMJSbZrNs0uJgcZnsFZlNoMNW/mdFPnfqVwQJZoMCziNleWBQx0alaIDXWjdJRG7qJS0Xl0PrqqeQ2lU4W9W23wAvf7F/8F4Oh+6NfMwewXCWBZmmw=='),
        (6, 'rdSV7J7cXfL1KAFLu+1L98fCXR40ey+GIiAsiRa2gbWR9UR38AoaddCpr7coLG1K5cWOM0/MG4MP1n+B9ZdSZ5NmmZcCwCeX9AAL5Ft/cocLTvcr9IK5GYrGlyCqkfgLJKrEqP6fH0M79TF4TkkgmqxnW4c6tkitHZN9wBf12lAYbv24uJLFWLhnmvPhMwnpCxWHfYFMao4nwd1x85Tjg74BQu1QWSVII6az7evr4Noc7rGWKwy1Ea/w9tZuQ3QHXIeVsASqdsc+DI2JkAn/UBJ3+73pexk1+6M9dwZUNaolPiGozWSogAn1ugpE7B+Cg9AxzLXFulFu4ScDxkne4w=='),
        (8, 'YJ9REE83Kglv0d4041n2pCcfFCGiSeGR8rDPlKf0dY7hu6NCsr9H+2FLXaq62j1sUiGRiHxh/J9TQIK50TuWv5bmuL2yFVa5p+jhiPnr06eIXsRaeviIeeZokfLI+RuvHohOkSrNNBr/kszUtqHmch9OZIiyseQ4W5VATNDVdyYb32GhB9gQ2gaF77ufcTXxreVUVhQX7j0cOxUy6yk/8RXWyiPXfKbKWp0tJ2PySyyyAvJjAteLXLPVCMgmb3MA7mkLC0b4YS1DwvVKZtzkp0WafsslhsfWB0Ov9NAWRVTRz9tCQTCIzaCk6322LbICTXGRvrxH+Ny546ebe1Ogmw=='),
        (9, 'dT9kSMm38fF7Qnl6X6nO3tqYtL7H11aGHQObXWEry/N3YAjXo4dccK1o+JI0iE8j593MPHAQL7vFXFaCIafnCnlL9JAcieWwIi5nkoYIVbeXbI/KRKs4XOtSP1NYWZiP3ZJ8HN+C2EqBfTYbPfmVaRzFLESlyYUSje7VtzcDlXoLzGGjuDaZcvp2KZKqBUmwhJ2m4vdnTOEH9ax2Kl7OOEQMGDh4gWLk8corOZYe3OONEMJPZvyhve9qDParPAMa6eyWHY0DNlIye8uRYH9UGtv2PN/YspDsJfLp/iEfHRwIQ4UvD9c3XU0qSJV4UpVKoYRDKSf8P/8xjjoJcmbPqg=='),
        (11, 'MvOe+tnrXt5Zj7xTDr/8QBOZkRM6DBiSawHIAkBBSl/ZGOXjAbLu0QBMHd6yPhTL0JqNvAHjxabPqH/r/Vj8a10phs1/MRvkL7CbgOJierosD6b/cEZClxrvalmTcKzS2vHcMQdPNMCAIBxtQWEDT3mPt9a0zrnQH8bOSSANq2oXTTtS6COTaWGAP7GVpi8UWgitexYSzIrYIIFSy8qgOAhsf8FgcEhiJGfE7wAIejl4RSKJn6qoYVyRdK9M+L2gDnQXQohbKzwdTwFlfCsf36HU1KDO6bUB7uRDsPL61hk2vhCBQWLJTE5ahD7ioxvpd5Oxy3GGc6tH4Rodj9XwMg=='),
        (12, '41Ee3Wv1OzyN4XUfZ0PmcKBNvxoMFJFGi21UK2qgqzOobRccghXbiocrHyMjhOcTBW2mHl5wEqxaukb0aOeo9r1f0bvBb1getpXbgN3Ex2yy0Vhsu8UG/ux7RZxliIh/JknWf+o3NJRuSLJCOtdtMosnZbU5DVcCtFZaZnj7MvAMEYpk9q+yCiy+rNSADgNulVemR4Pqxo2PeYjlx4ZUSoKMugbXt+dCMqi/Z0tB+orC46eevpTewEQwUFkEncUvUEsCVAwrEBS1Gu8IV+RpwcSeGX8EFsRXDz/IBOnjEkjeId1sfHhaXVrdn7aSD9IISaVb+Wwz5KlCPx2NjAY3ng=='),
        (14, '179aGV1g2XXL2iKLrRDRsTruj7xPH8ej/5CIV9k/+IP0p/2N4/JzPSJGf4WWPVjpsYvpuAcoJRvzU23Fumbp30xvwRlvvgkwNMsb3US005MFyLZ5F5LXHHXVyGtre1GnJsELcgHx+3QqEKMPtJLokTEU0tzn4zvrimgfjm2Hs2WKW1FyN0GvX7aC57vTxJarkfUMn8kc9PpziiUGQvDB4mao4lvIEj1bnNlC9LZtAoflWQcqnBOmTPoWsGl/8Ij6umaLRL+jmwdHimb0zFkCuiJE3GNLg8Qskw31tZffXvDUgVBGf2SWM7NFl5JEeBh5l9BIZaedM2B9Tt5wqmoZxQ=='),
        (15, 'auQU/znpkvPuqz0Xx2H4k4SKNGl4HTugKEDkjwectoQAbKaR6cogCHkB0P+TXNUmnrF83n8PnHu2O4a8qX5SlF3wGp97UFJ4H4T1jvwzGCv6KRdq+Pjk6rhmibCdd47DRhNQgoN3wgf63UBN8QpxL9NQg0kgZx7ER6l30Bzmt33OHqlgiE2LZaiDGPVKQ1zAOCmiUfjYkLnqMu5Hc/q1j77iSB3PidOCL2DE4x3hDerv9IMol5hhxG8J9xjgApZxgUO0YwQBRP6vfqjxKrEY3oxIEe6QHXxmXDfLp4h8RXxYMYpyIgWAWKjcoYKhItIoF3HawfO03r5BxbHyCWA52A=='),
        (17, 'y5xgPMkRO3vfP1B5e06k1WST0Kz1q72FwTY3TG87LPXermKvKHKEsrbAa816Tga0GzrC7as52oGQXxrUtiONikSc2g8QuwpyFxs/Q9pEr/NJeBBygRyvaL0nOTE7mb/OdhfQbFJpoD504VH5gLXv1cJixwkBDr+8Vh6TYoCIBu4ITqgfWvkZbRm36WP2dKtAkWRSVbEiwq3En1QC1ci8HfFOeBJkERknuEdJXG5CFdEo4FBRB0/FzDsNOH3qBVeRFfYCiGRvd59nIpFxZPig3Br6xHJcWb4wQ/ax+R0w365qoF2Abfv+YbofUYUf9XrKxRpntcOSlMawyxx1WVprEQ=='),
        (18, 'TWJ8oyyXDfax8x5F84ypYNxOrFDEK3nRC8AjxWnkfkzboP59QgX+ms9oNXYRviCaGWtVmjB6O663eqwnBs9QjN+fnpLEilTUJqhEwBMcBhmDdvaTA9RYqurc27jUfl/lxHrq3H3iWPYQyja//RyrwcpJbqEYiHlGy4I2dXWpYv6Z/hDtAuRFijbrPtyu5SJsmL4dh/clsldvvzDSNSQvpzv+I9t1vRIA5WDToscXrhLN6RYCIwFj5kYr6ldneIASlzapG7YUPusGou7JZ792dmcQlJDK65LaGlFOpexHLKQjDUwxB4mp9KNqtoR7ePeGHrTjAPoOncRa4vUFNVW8UQ=='),
        (20, 'UR12qdZ9mjRRFIfo73u3yiqTZML7qGtMNZcqLPNMQ8p1dt3jHiNYAdQ83kXlCNGkjWo0weGS6Fu8HwKbOTjDPZ6PsBmBW8+3sQGOetQe3KxFTC8fMZI/388F5i6WGNW30wlW8eqPZmYP7IV1KI2EMi9i3LZD5vETDtNumpGY0qyYJVl71Jxm5qc6+Brxwyt/A0wGvv1Wt9r1JcIUgKhVCXlYtl6g7nW/dQzasChOaqGk1omSCNDuwsNzDMHL88NiRjePI8Ks1LuR29wMgY9dhNq9mtQw+qIM+x74UPdZtSS61d3bDjQbgaxBpHNQWIeMGmfchWAu3J+KV7FrIYJTAw=='),
        (22, 'RErEHwmP9pOuu4nTdObmlB6abSYBJU1K56N2tiaCVkEGEMojvcyoDSxGdCfv+K0bxOlg2ZJ5ohB1F9za+HxsjH4vu0h25PT7r5Wm1tOBZJCO6oxJi7OLa/0r4Nbb8y+8sYT46MLsSuQP0y4o1CJ8VT7WFdUPPdRDvXQarLdlGVo2zUiKb/IZhd/QXpswAx7Oko1R2d8TUyy1fohJK3o237l/exM9bBVXq70MtiTJA9b8fQ0fDAdcYOFAlKVnDVBWpaYVWFeFVBb7co4827eNYubRx2cP6WGs1Kuy7cWr/+qLqO/6UuPe19Uit95gGY0G5vKnGsvUwuAgrODtnenxKw=='),
        (23, '3PNXG35pA9FgyQnL8ts/EhyH6OxY6caK8tsfgt8200uEWWkEmulNY+X/a3INJdgX6uowGHX7c0MtOtJmLkflynn9tWQXYSQ8u1QkmH34KGpo3M0vEMavP5ei8daaUc5tuln7YMa60nUHmAa1VZe568BG8jKTLguAEl9DTwxi0Sbc5Mk+xqBlOwjarCSkm/MaEk1OtI3oS6lQuuWAX6/loTBEV043CMLaaN0gO9BGNkZZO44+pTwkEiFrmxq3Y1cHEyKol/TE1RsiWY0tHEGP9LrRyniEWoooQR+sTYjOwlAMou78QFL3gVKF9okWQAEeMWLwNiARsMf/tmEAWzsTUw==')
) AS assinaturas(cod_relatorio, assinatura)
JOIN tb_relatorio relatorio ON relatorio.id = assinaturas.cod_relatorio;

-- Simula o escalonamento de um alerta urgente.
UPDATE tb_alerta
SET nivel_atual = 'GESTOR'
WHERE id = (
    SELECT id
    FROM tb_alerta
    WHERE nivel_gravidade = 'URGENTE'
    ORDER BY id DESC
    LIMIT 1
);

-- =============================
-- 12. LOG DE ACESSO
-- =============================
INSERT INTO tb_log_acesso (
    cod_usuario, tentativa_sucesso, ip_origem, user_agent, motivo_falha
)
SELECT usuario.id, eventos.sucesso, eventos.ip::INET, 'Mozilla/5.0', eventos.motivo
FROM (VALUES
    ('operador002', TRUE, '192.168.1.10', NULL),
    ('operador032', TRUE, '192.168.1.11', NULL),
    ('operador033', TRUE, '192.168.1.12', NULL),
    ('operador052', TRUE, '192.168.1.13', NULL),
    ('operador042', FALSE, '192.168.1.14', 'Senha incorreta')
) AS eventos(username, sucesso, ip, motivo)
JOIN tb_usuario usuario ON usuario.username = eventos.username;

INSERT INTO tb_log_acesso (
    cod_usuario, tentativa_sucesso, ip_origem, user_agent, motivo_falha, data_hora
)
SELECT
    usuario.id,
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
FROM generate_series(1, 100) gs
JOIN tb_usuario usuario ON usuario.username = 'operador' || LPAD(gs::TEXT, 3, '0');

INSERT INTO tb_log_acesso
    (cod_usuario, tentativa_sucesso, ip_origem, user_agent, motivo_falha, data_hora)
SELECT
    CASE
        WHEN serie.gs % 10 <> 0 OR serie.gs % 20 = 0 THEN operador.id
        ELSE NULL
    END,
    serie.gs % 10 <> 0,
    ('10.' || (20 + (operador.cod_cd % 200)) || '.' ||
        ((serie.gs / 250) + 1) || '.' || ((serie.gs % 250) + 1))::INET,
    CASE serie.gs % 3
        WHEN 0 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0'
        WHEN 1 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Firefox/130.0'
        ELSE 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) Safari/604.1'
    END,
    CASE
        WHEN serie.gs % 10 <> 0 THEN NULL
        WHEN serie.gs % 20 <> 0 THEN 'USUARIO_INEXISTENTE'
        ELSE 'SENHA_INCORRETA'
    END,
    CURRENT_TIMESTAMP
        - ((serie.gs % 30) * INTERVAL '1 day')
        - ((serie.gs % 24) * INTERVAL '1 hour')
FROM generate_series(1, 500) AS serie(gs)
CROSS JOIN LATERAL (
    SELECT id, cod_cd
    FROM tb_usuario
    WHERE nivel_acesso = 'OPERADOR'
    ORDER BY id
    OFFSET ((serie.gs - 1) % 200)
    LIMIT 1
) AS operador
ORDER BY serie.gs;

COMMIT;
