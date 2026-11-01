-- =============================
-- MASSA DE DADOS
-- =============================
BEGIN;
SET LOCAL timezone TO 'America/Sao_Paulo';

-- Dados legados de teste: IDs 1..45; 46..50 ficam para a carga RPA.
-- Executar uma unica vez em banco novo. Este arquivo nao migra dados existentes.

-- =============================
-- 1. ESTADOS
-- =============================
INSERT INTO tb_estado (estado) VALUES
    ('AC'), ('AL'), ('AP'), ('AM'), ('BA'), ('CE'), ('DF'), ('ES'), ('GO'),
    ('MA'), ('MT'), ('MS'), ('MG'), ('PA'), ('PB'), ('PR'), ('PE'), ('PI'),
    ('RJ'), ('RN'), ('RS'), ('RO'), ('RR'), ('SC'), ('SP'), ('SE'), ('TO');


-- =============================
-- 2. CENTROS DE DISTRIBUIÇÃO — MESMOS IDs DO LEGADO
-- =============================
INSERT INTO tb_cd (id, nome, cnpj) VALUES
    (1, 'CD São Paulo - Unidade 1', '00000000000001'),
    (2, 'CD Rio de Janeiro - Unidade 2', '00000000000002'),
    (3, 'CD Belo Horizonte - Unidade 3', '00000000000003'),
    (4, 'CD Curitiba - Unidade 4', '00000000000004'),
    (5, 'CD Porto Alegre - Unidade 5', '00000000000005'),
    (6, 'CD Salvador - Unidade 6', '00000000000006'),
    (7, 'CD Recife - Unidade 7', '00000000000007'),
    (8, 'CD Fortaleza - Unidade 8', '00000000000008'),
    (9, 'CD Brasília - Unidade 9', '00000000000009'),
    (10, 'CD Manaus - Unidade 10', '00000000000010'),
    (11, 'CD São Paulo - Unidade 11', '00000000000011'),
    (12, 'CD Rio de Janeiro - Unidade 12', '00000000000012'),
    (13, 'CD Belo Horizonte - Unidade 13', '00000000000013'),
    (14, 'CD Curitiba - Unidade 14', '00000000000014'),
    (15, 'CD Porto Alegre - Unidade 15', '00000000000015'),
    (16, 'CD Salvador - Unidade 16', '00000000000016'),
    (17, 'CD Recife - Unidade 17', '00000000000017'),
    (18, 'CD Fortaleza - Unidade 18', '00000000000018'),
    (19, 'CD Brasília - Unidade 19', '00000000000019'),
    (20, 'CD Manaus - Unidade 20', '00000000000020'),
    (21, 'CD São Paulo - Unidade 21', '00000000000021'),
    (22, 'CD Rio de Janeiro - Unidade 22', '00000000000022'),
    (23, 'CD Belo Horizonte - Unidade 23', '00000000000023'),
    (24, 'CD Curitiba - Unidade 24', '00000000000024'),
    (25, 'CD Porto Alegre - Unidade 25', '00000000000025'),
    (26, 'CD Salvador - Unidade 26', '00000000000026'),
    (27, 'CD Recife - Unidade 27', '00000000000027'),
    (28, 'CD Fortaleza - Unidade 28', '00000000000028'),
    (29, 'CD Brasília - Unidade 29', '00000000000029'),
    (30, 'CD Manaus - Unidade 30', '00000000000030'),
    (31, 'CD São Paulo - Unidade 31', '00000000000031'),
    (32, 'CD Rio de Janeiro - Unidade 32', '00000000000032'),
    (33, 'CD Belo Horizonte - Unidade 33', '00000000000033'),
    (34, 'CD Curitiba - Unidade 34', '00000000000034'),
    (35, 'CD Porto Alegre - Unidade 35', '00000000000035'),
    (36, 'CD Salvador - Unidade 36', '00000000000036'),
    (37, 'CD Recife - Unidade 37', '00000000000037'),
    (38, 'CD Fortaleza - Unidade 38', '00000000000038'),
    (39, 'CD Brasília - Unidade 39', '00000000000039'),
    (40, 'CD Manaus - Unidade 40', '00000000000040'),
    (41, 'CD São Paulo - Unidade 41', '00000000000041'),
    (42, 'CD Rio de Janeiro - Unidade 42', '00000000000042'),
    (43, 'CD Belo Horizonte - Unidade 43', '00000000000043'),
    (44, 'CD Curitiba - Unidade 44', '00000000000044'),
    (45, 'CD Porto Alegre - Unidade 45', '00000000000045');

-- =============================
-- 3. ENDEREÇOS — UF RESOLVIDA EM tb_estado
-- =============================
INSERT INTO tb_endereco (id, cep, rua, numero, cidade, bairro, complemento, cod_estado, cod_cd) VALUES
    (1, '10000137', 'Rua das Flores', 101, 'São Paulo', 'Zona Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'SP'), 1),
    (2, '10000274', 'Rua Industrial', 102, 'Rio de Janeiro', 'Distrito Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'RJ'), 2),
    (3, '10000411', 'Rua Comercial', 103, 'Belo Horizonte', 'Setor Logístico', NULL, (SELECT id FROM tb_estado WHERE estado = 'MG'), 3),
    (4, '10000548', 'Rua dos Andradas', 104, 'Curitiba', 'Vila Operária', NULL, (SELECT id FROM tb_estado WHERE estado = 'PR'), 4),
    (5, '10000685', 'Rua Voluntários', 105, 'Porto Alegre', 'Centro', NULL, (SELECT id FROM tb_estado WHERE estado = 'RS'), 5),
    (6, '10000822', 'Rua Brasil', 106, 'Salvador', 'Zona Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'BA'), 6),
    (7, '10000959', 'Rua Central', 107, 'Recife', 'Distrito Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'PE'), 7),
    (8, '10001096', 'Rua Norte', 108, 'Fortaleza', 'Setor Logístico', NULL, (SELECT id FROM tb_estado WHERE estado = 'CE'), 8),
    (9, '10001233', 'Rua Sul', 109, 'Brasília', 'Vila Operária', NULL, (SELECT id FROM tb_estado WHERE estado = 'DF'), 9),
    (10, '10001370', 'Rua das Nações', 110, 'Manaus', 'Centro', NULL, (SELECT id FROM tb_estado WHERE estado = 'AM'), 10),
    (11, '10001507', 'Rua das Flores', 111, 'São Paulo', 'Zona Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'SP'), 11),
    (12, '10001644', 'Rua Industrial', 112, 'Rio de Janeiro', 'Distrito Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'RJ'), 12),
    (13, '10001781', 'Rua Comercial', 113, 'Belo Horizonte', 'Setor Logístico', NULL, (SELECT id FROM tb_estado WHERE estado = 'MG'), 13),
    (14, '10001918', 'Rua dos Andradas', 114, 'Curitiba', 'Vila Operária', NULL, (SELECT id FROM tb_estado WHERE estado = 'PR'), 14),
    (15, '10002055', 'Rua Voluntários', 115, 'Porto Alegre', 'Centro', NULL, (SELECT id FROM tb_estado WHERE estado = 'RS'), 15),
    (16, '10002192', 'Rua Brasil', 116, 'Salvador', 'Zona Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'BA'), 16),
    (17, '10002329', 'Rua Central', 117, 'Recife', 'Distrito Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'PE'), 17),
    (18, '10002466', 'Rua Norte', 118, 'Fortaleza', 'Setor Logístico', NULL, (SELECT id FROM tb_estado WHERE estado = 'CE'), 18),
    (19, '10002603', 'Rua Sul', 119, 'Brasília', 'Vila Operária', NULL, (SELECT id FROM tb_estado WHERE estado = 'DF'), 19),
    (20, '10002740', 'Rua das Nações', 120, 'Manaus', 'Centro', NULL, (SELECT id FROM tb_estado WHERE estado = 'AM'), 20),
    (21, '10002877', 'Rua das Flores', 121, 'São Paulo', 'Zona Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'SP'), 21),
    (22, '10003014', 'Rua Industrial', 122, 'Rio de Janeiro', 'Distrito Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'RJ'), 22),
    (23, '10003151', 'Rua Comercial', 123, 'Belo Horizonte', 'Setor Logístico', NULL, (SELECT id FROM tb_estado WHERE estado = 'MG'), 23),
    (24, '10003288', 'Rua dos Andradas', 124, 'Curitiba', 'Vila Operária', NULL, (SELECT id FROM tb_estado WHERE estado = 'PR'), 24),
    (25, '10003425', 'Rua Voluntários', 125, 'Porto Alegre', 'Centro', NULL, (SELECT id FROM tb_estado WHERE estado = 'RS'), 25),
    (26, '10003562', 'Rua Brasil', 126, 'Salvador', 'Zona Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'BA'), 26),
    (27, '10003699', 'Rua Central', 127, 'Recife', 'Distrito Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'PE'), 27),
    (28, '10003836', 'Rua Norte', 128, 'Fortaleza', 'Setor Logístico', NULL, (SELECT id FROM tb_estado WHERE estado = 'CE'), 28),
    (29, '10003973', 'Rua Sul', 129, 'Brasília', 'Vila Operária', NULL, (SELECT id FROM tb_estado WHERE estado = 'DF'), 29),
    (30, '10004110', 'Rua das Nações', 130, 'Manaus', 'Centro', NULL, (SELECT id FROM tb_estado WHERE estado = 'AM'), 30),
    (31, '10004247', 'Rua das Flores', 131, 'São Paulo', 'Zona Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'SP'), 31),
    (32, '10004384', 'Rua Industrial', 132, 'Rio de Janeiro', 'Distrito Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'RJ'), 32),
    (33, '10004521', 'Rua Comercial', 133, 'Belo Horizonte', 'Setor Logístico', NULL, (SELECT id FROM tb_estado WHERE estado = 'MG'), 33),
    (34, '10004658', 'Rua dos Andradas', 134, 'Curitiba', 'Vila Operária', NULL, (SELECT id FROM tb_estado WHERE estado = 'PR'), 34),
    (35, '10004795', 'Rua Voluntários', 135, 'Porto Alegre', 'Centro', NULL, (SELECT id FROM tb_estado WHERE estado = 'RS'), 35),
    (36, '10004932', 'Rua Brasil', 136, 'Salvador', 'Zona Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'BA'), 36),
    (37, '10005069', 'Rua Central', 137, 'Recife', 'Distrito Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'PE'), 37),
    (38, '10005206', 'Rua Norte', 138, 'Fortaleza', 'Setor Logístico', NULL, (SELECT id FROM tb_estado WHERE estado = 'CE'), 38),
    (39, '10005343', 'Rua Sul', 139, 'Brasília', 'Vila Operária', NULL, (SELECT id FROM tb_estado WHERE estado = 'DF'), 39),
    (40, '10005480', 'Rua das Nações', 140, 'Manaus', 'Centro', NULL, (SELECT id FROM tb_estado WHERE estado = 'AM'), 40),
    (41, '10005617', 'Rua das Flores', 141, 'São Paulo', 'Zona Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'SP'), 41),
    (42, '10005754', 'Rua Industrial', 142, 'Rio de Janeiro', 'Distrito Industrial', NULL, (SELECT id FROM tb_estado WHERE estado = 'RJ'), 42),
    (43, '10005891', 'Rua Comercial', 143, 'Belo Horizonte', 'Setor Logístico', NULL, (SELECT id FROM tb_estado WHERE estado = 'MG'), 43),
    (44, '10006028', 'Rua dos Andradas', 144, 'Curitiba', 'Vila Operária', NULL, (SELECT id FROM tb_estado WHERE estado = 'PR'), 44),
    (45, '10006165', 'Rua Voluntários', 145, 'Porto Alegre', 'Centro', NULL, (SELECT id FROM tb_estado WHERE estado = 'RS'), 45);

-- =============================
-- 4. USUÁRIOS — IDs DO LEGADO E CONTAS LOCAIS SEPARADAS
-- =============================
-- Limpa o contexto antes de criar a conta tecnica usada pela auditoria.
SELECT set_config('app.usuario_atual', '', true);
INSERT INTO tb_usuario (id, nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor) VALUES
    (1000001, 'Worker Skadi', 'skadi_worker', NULL, 'skadi.enterprise@gmail.com', '$2a$12$HZ7dYoDeadUb.jpyhXV63uEH2PN525cWcV0dNEt5I3J1uuFQ02Sge', 'SUPER_ADMIN', NULL, NULL);
SELECT set_config('app.usuario_atual', '1000001', true);

INSERT INTO tb_usuario (id, nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor) VALUES
    (1000002, 'Beatriz Hinsching', 'beatriz.hinsching', NULL, 'beatriz.carvalho@institutojef.org.br', '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL),
    (1000003, 'Diego Valadares', 'diego.valadares', NULL, 'diego.valadares@institutojef.org.br', '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL),
    (1000004, 'Enzo Nascimento', 'enzo.nascimento', NULL, 'enzo.nascimento@institutojef.org.br', '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL),
    (1000005, 'Giovanna Santos', 'giovanna.santos', NULL, 'giovanna.santos@institutojef.org.br', '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL),
    (1000006, 'Gustavo Munhoz', 'gustavo.munhoz', NULL, 'gustavo.munhoz@institutojef.org.br', '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL),
    (1000007, 'Mariana Proque', 'mariana.proque', NULL, 'mariana.proque@institutojef.org.br', '$2a$12$j3weiXa7rwLd16llFhTHruukeZNfl8Ekp/pNJcYZfoOOAGLYlFhRm', 'SUPER_ADMIN', NULL, NULL);

-- ADMIN usa tb_admin_cd; seu cod_cd direto deve ser NULL no modelo novo.
INSERT INTO tb_usuario (id, nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor) VALUES
    (1, 'Ana Souza', 'usuario1', '00000000001', 'usuario1@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'ADMIN', NULL, NULL),
    (2, 'Carlos Lima', 'usuario2', '00000000002', 'usuario2@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'ADMIN', NULL, NULL),
    (3, 'Fernanda Ribeiro', 'usuario3', '00000000003', 'usuario3@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'ADMIN', NULL, NULL),
    (4, 'João Almeida', 'usuario4', '00000000004', 'usuario4@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'ADMIN', NULL, NULL),
    (5, 'Mariana Nunes', 'usuario5', '00000000005', 'usuario5@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'ADMIN', NULL, NULL),
    (6, 'Rafael Dias', 'usuario6', '00000000006', 'usuario6@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'ADMIN', NULL, NULL),
    (7, 'Beatriz Costa', 'usuario7', '00000000007', 'usuario7@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'ADMIN', NULL, NULL),
    (8, 'Eduardo Pereira', 'usuario8', '00000000008', 'usuario8@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'ADMIN', NULL, NULL),
    (9, 'Camila Santos', 'usuario9', '00000000009', 'usuario9@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'ADMIN', NULL, NULL),
    (10, 'Lucas Oliveira', 'usuario10', '00000000010', 'usuario10@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'ADMIN', NULL, NULL),
    (11, 'Patrícia Barbosa', 'usuario11', '00000000011', 'usuario11@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'GESTOR', 11, NULL),
    (12, 'Rodrigo Cardoso', 'usuario12', '00000000012', 'usuario12@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'GESTOR', 12, NULL),
    (13, 'Juliana Teixeira', 'usuario13', '00000000013', 'usuario13@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'GESTOR', 13, NULL),
    (14, 'Marcos Rocha', 'usuario14', '00000000014', 'usuario14@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'GESTOR', 14, NULL),
    (15, 'Larissa Martins', 'usuario15', '00000000015', 'usuario15@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'GESTOR', 15, NULL),
    (16, 'Gustavo Souza', 'usuario16', '00000000016', 'usuario16@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'GESTOR', 16, NULL),
    (17, 'Vanessa Lima', 'usuario17', '00000000017', 'usuario17@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'GESTOR', 17, NULL),
    (18, 'Thiago Ribeiro', 'usuario18', '00000000018', 'usuario18@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'GESTOR', 18, NULL),
    (19, 'Renata Almeida', 'usuario19', '00000000019', 'usuario19@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'GESTOR', 19, NULL),
    (20, 'Bruno Nunes', 'usuario20', '00000000020', 'usuario20@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'GESTOR', 20, NULL),
    (21, 'Ana Dias', 'usuario21', '00000000021', 'usuario21@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 11, 11),
    (22, 'Carlos Costa', 'usuario22', '00000000022', 'usuario22@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 12, 12),
    (23, 'Fernanda Pereira', 'usuario23', '00000000023', 'usuario23@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 13, 13),
    (24, 'João Santos', 'usuario24', '00000000024', 'usuario24@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 14, 14),
    (25, 'Mariana Oliveira', 'usuario25', '00000000025', 'usuario25@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 15, 15),
    (26, 'Rafael Barbosa', 'usuario26', '00000000026', 'usuario26@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 16, 16),
    (27, 'Beatriz Cardoso', 'usuario27', '00000000027', 'usuario27@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 17, 17),
    (28, 'Eduardo Teixeira', 'usuario28', '00000000028', 'usuario28@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 18, 18),
    (29, 'Camila Rocha', 'usuario29', '00000000029', 'usuario29@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 19, 19),
    (30, 'Lucas Martins', 'usuario30', '00000000030', 'usuario30@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 20, 20),
    (31, 'Patrícia Souza', 'usuario31', '00000000031', 'usuario31@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 11, 11),
    (32, 'Rodrigo Lima', 'usuario32', '00000000032', 'usuario32@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 12, 12),
    (33, 'Juliana Ribeiro', 'usuario33', '00000000033', 'usuario33@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 13, 13),
    (34, 'Marcos Almeida', 'usuario34', '00000000034', 'usuario34@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 14, 14),
    (35, 'Larissa Nunes', 'usuario35', '00000000035', 'usuario35@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 15, 15),
    (36, 'Gustavo Dias', 'usuario36', '00000000036', 'usuario36@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 16, 16),
    (37, 'Vanessa Costa', 'usuario37', '00000000037', 'usuario37@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 17, 17),
    (38, 'Thiago Pereira', 'usuario38', '00000000038', 'usuario38@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 18, 18),
    (39, 'Renata Santos', 'usuario39', '00000000039', 'usuario39@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 19, 19),
    (40, 'Bruno Oliveira', 'usuario40', '00000000040', 'usuario40@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 20, 20),
    (41, 'Ana Barbosa', 'usuario41', '00000000041', 'usuario41@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 11, 11),
    (42, 'Carlos Cardoso', 'usuario42', '00000000042', 'usuario42@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 12, 12),
    (43, 'Fernanda Teixeira', 'usuario43', '00000000043', 'usuario43@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 13, 13),
    (44, 'João Rocha', 'usuario44', '00000000044', 'usuario44@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 14, 14),
    (45, 'Mariana Martins', 'usuario45', '00000000045', 'usuario45@logfresh.com', '$2b$12$GWiEYtdYsR0js0JldsOfGu5NA6r2gJTaJuXZ9YVWxU.d6cQsrSdDW', 'OPERADOR', 15, 15);

-- Vinculos de ADMIN adaptados do texto legado para os CDs presentes.
INSERT INTO tb_admin_cd (cod_admin, cod_cd) VALUES
    (1, 1),
    (2, 2),
    (3, 3),
    (4, 4),
    (5, 5),
    (6, 6),
    (7, 7),
    (8, 8),
    (9, 9),
    (10, 10),
    (1, 11),
    (2, 12),
    (3, 13),
    (4, 14),
    (5, 15),
    (6, 16),
    (7, 17),
    (8, 18),
    (9, 19),
    (10, 20),
    (1, 21),
    (2, 22),
    (3, 23),
    (4, 24),
    (5, 25),
    (6, 26),
    (7, 27),
    (8, 28),
    (9, 29),
    (10, 30),
    (1, 31),
    (2, 32),
    (3, 33),
    (4, 34),
    (5, 35),
    (6, 36),
    (7, 37),
    (8, 38),
    (9, 39),
    (10, 40),
    (1, 41),
    (2, 42),
    (3, 43),
    (4, 44),
    (5, 45);

-- =============================
-- 5. SOLICITAÇÕES DE SUPORTE
-- =============================
-- 60 chamados sintéticos: 20 REGISTRADO, 20 EM_ATENDIMENTO e 20 ATENDIDO.
-- As transições passam pelas triggers normais, sem desativar validações.
DO $$
DECLARE
    v_solicitantes INTEGER[];
    v_responsaveis INTEGER[];
    v_indice INTEGER;
    v_chamado INTEGER;
    v_responsavel INTEGER;
    v_abertura TIMESTAMP;
BEGIN
    SELECT array_agg(id ORDER BY id) INTO v_solicitantes
    FROM tb_usuario WHERE nivel_acesso = 'OPERADOR';
    SELECT array_agg(id ORDER BY id) INTO v_responsaveis
    FROM tb_usuario WHERE nivel_acesso = 'SUPER_ADMIN' AND username <> 'skadi_worker';

    IF v_solicitantes IS NULL OR v_responsaveis IS NULL THEN
        RAISE EXCEPTION 'A massa de suporte exige OPERADOR e SUPER_ADMIN cadastrados.';
    END IF;

    FOR v_indice IN 1..60 LOOP
        v_abertura := (CURRENT_TIMESTAMP AT TIME ZONE 'America/Sao_Paulo')
            - (((v_indice - 1) % 20) + 1) * INTERVAL '1 day'
            - (v_indice % 8) * INTERVAL '1 hour';
        v_responsavel := v_responsaveis[((v_indice - 1) % array_length(v_responsaveis, 1)) + 1];

        INSERT INTO tb_solicitacao_suporte (
            cod_usuario_solicitante, categoria, descricao, status, data_hora_abertura
        ) VALUES (
            v_solicitantes[((v_indice - 1) % array_length(v_solicitantes, 1)) + 1],
            (ARRAY['DUVIDA', 'SUGESTAO', 'RECLAMACAO', 'OUTRO'])[((v_indice - 1) % 4) + 1],
            '[TESTE_SUPORTE_' || lpad(v_indice::text, 3, '0') || '] '
                || CASE ((v_indice - 1) % 4)
                    WHEN 0 THEN 'Dúvida sobre o procedimento de conferência da câmara.'
                    WHEN 1 THEN 'Sugestão para facilitar a consulta do histórico de leituras.'
                    WHEN 2 THEN 'Relato de dificuldade ao acessar uma funcionalidade do sistema.'
                    ELSE 'Solicitação de orientação sobre o uso da plataforma.'
                   END,
            'REGISTRADO', v_abertura
        ) RETURNING id INTO v_chamado;

        IF v_indice % 3 IN (1, 2) THEN
            UPDATE tb_solicitacao_suporte
            SET status = 'EM_ATENDIMENTO', cod_usuario_responsavel = v_responsavel
            WHERE id = v_chamado;
        END IF;

        IF v_indice % 3 = 2 THEN
            UPDATE tb_solicitacao_suporte
            SET status = 'ATENDIDO',
                resposta = 'Resposta de demonstração para teste do dashboard de suporte.',
                data_hora_encerramento = v_abertura
                    + (((v_indice * 7) % 24) + 1) * INTERVAL '30 minutes'
            WHERE id = v_chamado;
        END IF;
    END LOOP;
END;
$$;

-- =============================

-- =============================
-- 6. TERMÔMETROS — MESMOS IDs DO LEGADO
-- =============================
INSERT INTO tb_termometro (id, modelo) VALUES
    (1, 'Sensor DHT-2200'),
    (2, 'Sensor TempLog X3'),
    (3, 'Sensor TermoSense Pro'),
    (4, 'Sensor IoT-Cold'),
    (5, 'Sensor ThermoGuard'),
    (6, 'Sensor DHT-2200'),
    (7, 'Sensor TempLog X3'),
    (8, 'Sensor TermoSense Pro'),
    (9, 'Sensor IoT-Cold'),
    (10, 'Sensor ThermoGuard'),
    (11, 'Sensor DHT-2200'),
    (12, 'Sensor TempLog X3'),
    (13, 'Sensor TermoSense Pro'),
    (14, 'Sensor IoT-Cold'),
    (15, 'Sensor ThermoGuard'),
    (16, 'Sensor DHT-2200'),
    (17, 'Sensor TempLog X3'),
    (18, 'Sensor TermoSense Pro'),
    (19, 'Sensor IoT-Cold'),
    (20, 'Sensor ThermoGuard'),
    (21, 'Sensor DHT-2200'),
    (22, 'Sensor TempLog X3'),
    (23, 'Sensor TermoSense Pro'),
    (24, 'Sensor IoT-Cold'),
    (25, 'Sensor ThermoGuard'),
    (26, 'Sensor DHT-2200'),
    (27, 'Sensor TempLog X3'),
    (28, 'Sensor TermoSense Pro'),
    (29, 'Sensor IoT-Cold'),
    (30, 'Sensor ThermoGuard'),
    (31, 'Sensor DHT-2200'),
    (32, 'Sensor TempLog X3'),
    (33, 'Sensor TermoSense Pro'),
    (34, 'Sensor IoT-Cold'),
    (35, 'Sensor ThermoGuard'),
    (36, 'Sensor DHT-2200'),
    (37, 'Sensor TempLog X3'),
    (38, 'Sensor TermoSense Pro'),
    (39, 'Sensor IoT-Cold'),
    (40, 'Sensor ThermoGuard'),
    (41, 'Sensor DHT-2200'),
    (42, 'Sensor TempLog X3'),
    (43, 'Sensor TermoSense Pro'),
    (44, 'Sensor IoT-Cold'),
    (45, 'Sensor ThermoGuard');

-- =============================
-- 7. CATEGORIAS — FAIXAS E VIDA ÚTIL DO LEGADO
-- =============================
INSERT INTO tb_categoria (id, nome, temperatura_min, temperatura_max, vida_util_horas) VALUES
    (1, 'Picanha Bovina Premium Congelado', -25.00, -18.00, INTERVAL '3 hours 12 minutes'),
    (2, 'Alcatra Bovina Premium Resfriado', 0.00, 4.00, INTERVAL '0 hours 55 minutes'),
    (3, 'Maminha Bovina Premium Congelado', -25.00, -18.00, INTERVAL '2 hours 20 minutes'),
    (4, 'Patinho Bovino Premium Resfriado', 0.00, 4.00, INTERVAL '1 hours 0 minutes'),
    (5, 'Fraldinha Bovina Premium Congelado', -25.00, -18.00, INTERVAL '3 hours 24 minutes'),
    (6, 'Contra Filé Bovino Premium Resfriado', 0.00, 4.00, INTERVAL '0 hours 58 minutes'),
    (7, 'Coxão Mole Bovino Premium Congelado', -25.00, -18.00, INTERVAL '3 hours 33 minutes'),
    (8, 'Acém Bovino Premium Resfriado', 0.00, 4.00, INTERVAL '1 hours 5 minutes'),
    (9, 'Peito de Frango Premium Congelado', -25.00, -18.00, INTERVAL '2 hours 15 minutes'),
    (10, 'Sobrecoxa de Frango Premium Resfriado', 0.00, 4.00, INTERVAL '0 hours 37 minutes'),
    (11, 'Picanha Bovina Standard Congelado', -25.00, -18.00, INTERVAL '3 hours 15 minutes'),
    (12, 'Alcatra Bovina Standard Resfriado', 0.00, 4.00, INTERVAL '0 hours 54 minutes'),
    (13, 'Maminha Bovina Standard Congelado', -25.00, -18.00, INTERVAL '2 hours 24 minutes'),
    (14, 'Patinho Bovino Standard Resfriado', 0.00, 4.00, INTERVAL '1 hours 1 minutes'),
    (15, 'Fraldinha Bovina Standard Congelado', -25.00, -18.00, INTERVAL '3 hours 27 minutes'),
    (16, 'Contra Filé Bovino Standard Resfriado', 0.00, 4.00, INTERVAL '0 hours 56 minutes'),
    (17, 'Coxão Mole Bovino Standard Congelado', -25.00, -18.00, INTERVAL '3 hours 30 minutes'),
    (18, 'Acém Bovino Standard Resfriado', 0.00, 4.00, INTERVAL '1 hours 4 minutes'),
    (19, 'Peito de Frango Standard Congelado', -25.00, -18.00, INTERVAL '2 hours 19 minutes'),
    (20, 'Sobrecoxa de Frango Standard Resfriado', 0.00, 4.00, INTERVAL '0 hours 35 minutes'),
    (21, 'Picanha Bovina Econômica Congelado', -25.00, -18.00, INTERVAL '3 hours 18 minutes'),
    (22, 'Alcatra Bovina Econômica Resfriado', 0.00, 4.00, INTERVAL '0 hours 59 minutes'),
    (23, 'Maminha Bovina Econômica Congelado', -25.00, -18.00, INTERVAL '2 hours 26 minutes'),
    (24, 'Patinho Bovino Econômica Resfriado', 0.00, 4.00, INTERVAL '1 hours 2 minutes'),
    (25, 'Fraldinha Bovina Econômica Congelado', -25.00, -18.00, INTERVAL '3 hours 36 minutes'),
    (26, 'Contra Filé Bovino Econômica Resfriado', 0.00, 4.00, INTERVAL '0 hours 57 minutes'),
    (27, 'Coxão Mole Bovino Econômica Congelado', -25.00, -18.00, INTERVAL '3 hours 39 minutes'),
    (28, 'Acém Bovino Econômica Resfriado', 0.00, 4.00, INTERVAL '1 hours 6 minutes'),
    (29, 'Peito de Frango Econômica Congelado', -25.00, -18.00, INTERVAL '2 hours 17 minutes'),
    (30, 'Sobrecoxa de Frango Econômica Resfriado', 0.00, 4.00, INTERVAL '0 hours 36 minutes'),
    (31, 'Picanha Bovina Especial Congelado', -25.00, -18.00, INTERVAL '3 hours 21 minutes'),
    (32, 'Alcatra Bovina Especial Resfriado', 0.00, 4.00, INTERVAL '0 hours 34 minutes'),
    (33, 'Maminha Bovina Especial Congelado', -25.00, -18.00, INTERVAL '2 hours 28 minutes'),
    (34, 'Patinho Bovino Especial Resfriado', 0.00, 4.00, INTERVAL '1 hours 3 minutes'),
    (35, 'Fraldinha Bovina Especial Congelado', -25.00, -18.00, INTERVAL '3 hours 45 minutes'),
    (36, 'Contra Filé Bovino Especial Resfriado', 0.00, 4.00, INTERVAL '0 hours 56 minutes'),
    (37, 'Coxão Mole Bovino Especial Congelado', -25.00, -18.00, INTERVAL '3 hours 42 minutes'),
    (38, 'Acém Bovino Especial Resfriado', 0.00, 4.00, INTERVAL '1 hours 7 minutes'),
    (39, 'Peito de Frango Especial Congelado', -25.00, -18.00, INTERVAL '2 hours 20 minutes'),
    (40, 'Sobrecoxa de Frango Especial Resfriado', 0.00, 4.00, INTERVAL '0 hours 38 minutes'),
    (41, 'Picanha Bovina Básica Congelado', -25.00, -18.00, INTERVAL '3 hours 48 minutes'),
    (42, 'Alcatra Bovina Básica Resfriado', 0.00, 4.00, INTERVAL '0 hours 33 minutes'),
    (43, 'Maminha Bovina Básica Congelado', -25.00, -18.00, INTERVAL '2 hours 31 minutes'),
    (44, 'Patinho Bovino Básica Resfriado', 0.00, 4.00, INTERVAL '1 hours 8 minutes'),
    (45, 'Fraldinha Bovina Básica Congelado', -25.00, -18.00, INTERVAL '3 hours 51 minutes');

-- =============================
-- 8. CÂMARAS FRIGORÍFICAS — MESMOS IDs DO LEGADO
-- =============================
INSERT INTO tb_camara_frigorifica (id, localizacao, temperatura_min, temperatura_max, cod_cd, cod_termometro) VALUES
    (1, 'Setor A - Corredor 1', -25.00, -18.00, 1, 1),
    (2, 'Setor B - Corredor 2', 0.00, 4.00, 2, 2),
    (3, 'Setor C - Corredor 3', -25.00, -18.00, 3, 3),
    (4, 'Setor D - Corredor 4', 0.00, 4.00, 4, 4),
    (5, 'Setor A - Corredor 5', -25.00, -18.00, 5, 5),
    (6, 'Setor B - Corredor 6', 0.00, 4.00, 6, 6),
    (7, 'Setor C - Corredor 1', -25.00, -18.00, 7, 7),
    (8, 'Setor D - Corredor 2', 0.00, 4.00, 8, 8),
    (9, 'Setor A - Corredor 3', -25.00, -18.00, 9, 9),
    (10, 'Setor B - Corredor 4', 0.00, 4.00, 10, 10),
    (11, 'Setor C - Corredor 5', -25.00, -18.00, 11, 11),
    (12, 'Setor D - Corredor 6', 0.00, 4.00, 12, 12),
    (13, 'Setor A - Corredor 1', -25.00, -18.00, 13, 13),
    (14, 'Setor B - Corredor 2', 0.00, 4.00, 14, 14),
    (15, 'Setor C - Corredor 3', -25.00, -18.00, 15, 15),
    (16, 'Setor D - Corredor 4', 0.00, 4.00, 16, 16),
    (17, 'Setor A - Corredor 5', -25.00, -18.00, 17, 17),
    (18, 'Setor B - Corredor 6', 0.00, 4.00, 18, 18),
    (19, 'Setor C - Corredor 1', -25.00, -18.00, 19, 19),
    (20, 'Setor D - Corredor 2', 0.00, 4.00, 20, 20),
    (21, 'Setor A - Corredor 3', -25.00, -18.00, 21, 21),
    (22, 'Setor B - Corredor 4', 0.00, 4.00, 22, 22),
    (23, 'Setor C - Corredor 5', -25.00, -18.00, 23, 23),
    (24, 'Setor D - Corredor 6', 0.00, 4.00, 24, 24),
    (25, 'Setor A - Corredor 1', -25.00, -18.00, 25, 25),
    (26, 'Setor B - Corredor 2', 0.00, 4.00, 26, 26),
    (27, 'Setor C - Corredor 3', -25.00, -18.00, 27, 27),
    (28, 'Setor D - Corredor 4', 0.00, 4.00, 28, 28),
    (29, 'Setor A - Corredor 5', -25.00, -18.00, 29, 29),
    (30, 'Setor B - Corredor 6', 0.00, 4.00, 30, 30),
    (31, 'Setor C - Corredor 1', -25.00, -18.00, 31, 31),
    (32, 'Setor D - Corredor 2', 0.00, 4.00, 32, 32),
    (33, 'Setor A - Corredor 3', -25.00, -18.00, 33, 33),
    (34, 'Setor B - Corredor 4', 0.00, 4.00, 34, 34),
    (35, 'Setor C - Corredor 5', -25.00, -18.00, 35, 35),
    (36, 'Setor D - Corredor 6', 0.00, 4.00, 36, 36),
    (37, 'Setor A - Corredor 1', -25.00, -18.00, 37, 37),
    (38, 'Setor B - Corredor 2', 0.00, 4.00, 38, 38),
    (39, 'Setor C - Corredor 3', -25.00, -18.00, 39, 39),
    (40, 'Setor D - Corredor 4', 0.00, 4.00, 40, 40),
    (41, 'Setor A - Corredor 5', -25.00, -18.00, 41, 41),
    (42, 'Setor B - Corredor 6', 0.00, 4.00, 42, 42),
    (43, 'Setor C - Corredor 1', -25.00, -18.00, 43, 43),
    (44, 'Setor D - Corredor 2', 0.00, 4.00, 44, 44),
    (45, 'Setor A - Corredor 3', -25.00, -18.00, 45, 45);

-- =============================
-- 9. LOTES E VÍNCULOS COM CÂMARAS — MESMOS IDs DO LEGADO
-- =============================
INSERT INTO tb_lote (id, codigo_lote, cod_categoria, data_fabricacao, data_validade, status) VALUES
    (1, 'LT-2026-0001', 1, CURRENT_DATE - 2, CURRENT_DATE + 178, 'ATIVO'),
    (2, 'LT-2026-0002', 2, CURRENT_DATE - 3, CURRENT_DATE + 4, 'ATIVO'),
    (3, 'LT-2026-0003', 3, CURRENT_DATE - 4, CURRENT_DATE + 176, 'VENDIDO'),
    (4, 'LT-2026-0004', 4, CURRENT_DATE - 5, CURRENT_DATE + 2, 'ATIVO'),
    (5, 'LT-2026-0005', 5, CURRENT_DATE - 6, CURRENT_DATE + 174, 'EXPEDIDO'),
    (6, 'LT-2026-0006', 6, CURRENT_DATE - 7, CURRENT_DATE + 0, 'ATIVO'),
    (7, 'LT-2026-0007', 7, CURRENT_DATE - 8, CURRENT_DATE + 172, 'BLOQUEADO'),
    (8, 'LT-2026-0008', 8, CURRENT_DATE - 9, CURRENT_DATE - 2, 'ATIVO'),
    (9, 'LT-2026-0009', 9, CURRENT_DATE - 10, CURRENT_DATE + 170, 'ATIVO'),
    (10, 'LT-2026-0010', 10, CURRENT_DATE - 11, CURRENT_DATE - 4, 'VENDIDO'),
    (11, 'LT-2026-0011', 11, CURRENT_DATE - 12, CURRENT_DATE + 168, 'ATIVO'),
    (12, 'LT-2026-0012', 12, CURRENT_DATE - 13, CURRENT_DATE - 6, 'EXPEDIDO'),
    (13, 'LT-2026-0013', 13, CURRENT_DATE - 14, CURRENT_DATE + 166, 'ATIVO'),
    (14, 'LT-2026-0014', 14, CURRENT_DATE - 15, CURRENT_DATE - 8, 'BLOQUEADO'),
    (15, 'LT-2026-0015', 15, CURRENT_DATE - 16, CURRENT_DATE + 164, 'ATIVO'),
    (16, 'LT-2026-0016', 16, CURRENT_DATE - 17, CURRENT_DATE - 10, 'ATIVO'),
    (17, 'LT-2026-0017', 17, CURRENT_DATE - 18, CURRENT_DATE + 162, 'VENDIDO'),
    (18, 'LT-2026-0018', 18, CURRENT_DATE - 19, CURRENT_DATE - 12, 'ATIVO'),
    (19, 'LT-2026-0019', 19, CURRENT_DATE - 20, CURRENT_DATE + 160, 'EXPEDIDO'),
    (20, 'LT-2026-0020', 20, CURRENT_DATE - 21, CURRENT_DATE - 14, 'ATIVO'),
    (21, 'LT-2026-0021', 21, CURRENT_DATE - 22, CURRENT_DATE + 158, 'BLOQUEADO'),
    (22, 'LT-2026-0022', 22, CURRENT_DATE - 23, CURRENT_DATE - 16, 'ATIVO'),
    (23, 'LT-2026-0023', 23, CURRENT_DATE - 24, CURRENT_DATE + 156, 'ATIVO'),
    (24, 'LT-2026-0024', 24, CURRENT_DATE - 25, CURRENT_DATE - 18, 'VENDIDO'),
    (25, 'LT-2026-0025', 25, CURRENT_DATE - 26, CURRENT_DATE + 154, 'ATIVO'),
    (26, 'LT-2026-0026', 26, CURRENT_DATE - 27, CURRENT_DATE - 20, 'EXPEDIDO'),
    (27, 'LT-2026-0027', 27, CURRENT_DATE - 28, CURRENT_DATE + 152, 'ATIVO'),
    (28, 'LT-2026-0028', 28, CURRENT_DATE - 29, CURRENT_DATE - 22, 'BLOQUEADO'),
    (29, 'LT-2026-0029', 29, CURRENT_DATE - 30, CURRENT_DATE + 150, 'ATIVO'),
    (30, 'LT-2026-0030', 30, CURRENT_DATE - 1, CURRENT_DATE + 6, 'ATIVO'),
    (31, 'LT-2026-0031', 31, CURRENT_DATE - 2, CURRENT_DATE + 178, 'VENDIDO'),
    (32, 'LT-2026-0032', 32, CURRENT_DATE - 3, CURRENT_DATE + 4, 'ATIVO'),
    (33, 'LT-2026-0033', 33, CURRENT_DATE - 4, CURRENT_DATE + 176, 'EXPEDIDO'),
    (34, 'LT-2026-0034', 34, CURRENT_DATE - 5, CURRENT_DATE + 2, 'ATIVO'),
    (35, 'LT-2026-0035', 35, CURRENT_DATE - 6, CURRENT_DATE + 174, 'BLOQUEADO'),
    (36, 'LT-2026-0036', 36, CURRENT_DATE - 7, CURRENT_DATE + 0, 'ATIVO'),
    (37, 'LT-2026-0037', 37, CURRENT_DATE - 8, CURRENT_DATE + 172, 'ATIVO'),
    (38, 'LT-2026-0038', 38, CURRENT_DATE - 9, CURRENT_DATE - 2, 'VENDIDO'),
    (39, 'LT-2026-0039', 39, CURRENT_DATE - 10, CURRENT_DATE + 170, 'ATIVO'),
    (40, 'LT-2026-0040', 40, CURRENT_DATE - 11, CURRENT_DATE - 4, 'EXPEDIDO'),
    (41, 'LT-2026-0041', 41, CURRENT_DATE - 12, CURRENT_DATE + 168, 'ATIVO'),
    (42, 'LT-2026-0042', 42, CURRENT_DATE - 13, CURRENT_DATE - 6, 'BLOQUEADO'),
    (43, 'LT-2026-0043', 43, CURRENT_DATE - 14, CURRENT_DATE + 166, 'ATIVO'),
    (44, 'LT-2026-0044', 44, CURRENT_DATE - 15, CURRENT_DATE - 8, 'ATIVO'),
    (45, 'LT-2026-0045', 45, CURRENT_DATE - 16, CURRENT_DATE + 164, 'VENDIDO');

INSERT INTO tb_lote_camara_frigorifica (id, cod_lote, cod_camara_frigorifica, data_entrada, data_saida) VALUES
    (1, 1, 1, CURRENT_TIMESTAMP - INTERVAL '2 days', NULL),
    (2, 2, 2, CURRENT_TIMESTAMP - INTERVAL '3 days', NULL),
    (3, 3, 3, CURRENT_TIMESTAMP - INTERVAL '4 days', NULL),
    (4, 4, 4, CURRENT_TIMESTAMP - INTERVAL '5 days', NULL),
    (5, 5, 5, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),
    (6, 6, 6, CURRENT_TIMESTAMP - INTERVAL '7 days', NULL),
    (7, 7, 7, CURRENT_TIMESTAMP - INTERVAL '8 days', NULL),
    (8, 8, 8, CURRENT_TIMESTAMP - INTERVAL '9 days', NULL),
    (9, 9, 9, CURRENT_TIMESTAMP - INTERVAL '10 days', NULL),
    (10, 10, 10, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),
    (11, 11, 11, CURRENT_TIMESTAMP - INTERVAL '12 days', NULL),
    (12, 12, 12, CURRENT_TIMESTAMP - INTERVAL '13 days', NULL),
    (13, 13, 13, CURRENT_TIMESTAMP - INTERVAL '14 days', NULL),
    (14, 14, 14, CURRENT_TIMESTAMP - INTERVAL '15 days', NULL),
    (15, 15, 15, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),
    (16, 16, 16, CURRENT_TIMESTAMP - INTERVAL '17 days', NULL),
    (17, 17, 17, CURRENT_TIMESTAMP - INTERVAL '18 days', NULL),
    (18, 18, 18, CURRENT_TIMESTAMP - INTERVAL '19 days', NULL),
    (19, 19, 19, CURRENT_TIMESTAMP - INTERVAL '20 days', NULL),
    (20, 20, 20, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),
    (21, 21, 21, CURRENT_TIMESTAMP - INTERVAL '2 days', NULL),
    (22, 22, 22, CURRENT_TIMESTAMP - INTERVAL '3 days', NULL),
    (23, 23, 23, CURRENT_TIMESTAMP - INTERVAL '4 days', NULL),
    (24, 24, 24, CURRENT_TIMESTAMP - INTERVAL '5 days', NULL),
    (25, 25, 25, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),
    (26, 26, 26, CURRENT_TIMESTAMP - INTERVAL '7 days', NULL),
    (27, 27, 27, CURRENT_TIMESTAMP - INTERVAL '8 days', NULL),
    (28, 28, 28, CURRENT_TIMESTAMP - INTERVAL '9 days', NULL),
    (29, 29, 29, CURRENT_TIMESTAMP - INTERVAL '10 days', NULL),
    (30, 30, 30, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),
    (31, 31, 31, CURRENT_TIMESTAMP - INTERVAL '12 days', NULL),
    (32, 32, 32, CURRENT_TIMESTAMP - INTERVAL '13 days', NULL),
    (33, 33, 33, CURRENT_TIMESTAMP - INTERVAL '14 days', NULL),
    (34, 34, 34, CURRENT_TIMESTAMP - INTERVAL '15 days', NULL),
    (35, 35, 35, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),
    (36, 36, 36, CURRENT_TIMESTAMP - INTERVAL '17 days', NULL),
    (37, 37, 37, CURRENT_TIMESTAMP - INTERVAL '18 days', NULL),
    (38, 38, 38, CURRENT_TIMESTAMP - INTERVAL '19 days', NULL),
    (39, 39, 39, CURRENT_TIMESTAMP - INTERVAL '20 days', NULL),
    (40, 40, 40, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),
    (41, 41, 41, CURRENT_TIMESTAMP - INTERVAL '2 days', NULL),
    (42, 42, 42, CURRENT_TIMESTAMP - INTERVAL '3 days', NULL),
    (43, 43, 43, CURRENT_TIMESTAMP - INTERVAL '4 days', NULL),
    (44, 44, 44, CURRENT_TIMESTAMP - INTERVAL '5 days', NULL),
    (45, 45, 45, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '4 days');

-- Ajusta sequencias depois dos IDs explicitos (incluindo contas locais).
SELECT setval(pg_get_serial_sequence('tb_cd', 'id'), (SELECT MAX(id) FROM tb_cd));
SELECT setval(pg_get_serial_sequence('tb_endereco', 'id'), (SELECT MAX(id) FROM tb_endereco));
SELECT setval(pg_get_serial_sequence('tb_usuario', 'id'), (SELECT MAX(id) FROM tb_usuario));
SELECT setval(pg_get_serial_sequence('tb_termometro', 'id'), (SELECT MAX(id) FROM tb_termometro));
SELECT setval(pg_get_serial_sequence('tb_categoria', 'id'), (SELECT MAX(id) FROM tb_categoria));
SELECT setval(pg_get_serial_sequence('tb_camara_frigorifica', 'id'), (SELECT MAX(id) FROM tb_camara_frigorifica));
SELECT setval(pg_get_serial_sequence('tb_lote', 'id'), (SELECT MAX(id) FROM tb_lote));
SELECT setval(pg_get_serial_sequence('tb_lote_camara_frigorifica', 'id'), (SELECT MAX(id) FROM tb_lote_camara_frigorifica));

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
SELECT exemplo.cod_termometro, exemplo.temperatura, exemplo.data_hora::TIMESTAMP
FROM (VALUES
    (1, 4.80, '2026-09-02 08:00:00'),
    (2, 6.80, '2026-09-02 08:30:00'),
    (7, 5.00, '2026-09-02 09:00:00'),
    (10, -8.00, '2026-09-02 09:30:00')
) AS exemplo(cod_termometro, temperatura, data_hora)
JOIN tb_camara_frigorifica cam ON cam.cod_termometro = exemplo.cod_termometro
-- As triggers exigem lote ativo ainda presente para gerar um alerta.
WHERE EXISTS (
    SELECT 1 FROM tb_lote_camara_frigorifica vinculo
    JOIN tb_lote lote ON lote.id = vinculo.cod_lote
    WHERE vinculo.cod_camara_frigorifica = cam.id
      AND vinculo.data_saida IS NULL AND lote.status = 'ATIVO'
);

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
  AND EXISTS (
      SELECT 1 FROM tb_lote_camara_frigorifica vinculo
      JOIN tb_lote lote ON lote.id = vinculo.cod_lote
      WHERE vinculo.cod_camara_frigorifica = cam.id
        AND vinculo.data_saida IS NULL AND lote.status = 'ATIVO'
  )
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
    (cod_usuario_gerador, cod_cd, hash_conteudo, conteudo, periodo_inicio, periodo_fim, status)
SELECT
    admin.id,
    cd.id,
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
   AND admin.nivel_acesso = 'ADMIN'
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
    cod_usuario_gerador, cod_cd, hash_conteudo, periodo_inicio, periodo_fim, status, conteudo
)
VALUES
((SELECT id FROM tb_usuario WHERE username = 'usuario1'), 1,
 'e59d3e70d8e55ce6fc36361645a3708294c6c4e5971a1ea0cf7844a4c7d6d862',
 '2026-08-01', '2026-08-31', 'GERADO',
 'Relatorio operacional do periodo de agosto de 2026 - usuario 2.'),
((SELECT id FROM tb_usuario WHERE username = 'usuario2'), 2,
 '998be91f97fd94a6e41e184ece055dd2a3d30fa1a36beda81784fde6ce0d259c',
 '2026-08-01', '2026-08-31', 'ASSINADO',
 'Relatorio operacional do periodo de agosto de 2026 - usuario 3.'),
((SELECT id FROM tb_usuario WHERE username = 'usuario3'), 3,
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

-- Simula o escalonamento de um alerta CRITICO.
UPDATE tb_alerta
SET nivel_atual = 'GESTOR'
WHERE id = (
    SELECT id
    FROM tb_alerta
    WHERE nivel_gravidade = 'CRITICO'
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
    ('usuario21', TRUE, '192.168.1.10', NULL),
    ('usuario22', TRUE, '192.168.1.11', NULL),
    ('usuario23', TRUE, '192.168.1.12', NULL),
    ('usuario24', TRUE, '192.168.1.13', NULL),
    ('usuario25', FALSE, '192.168.1.14', 'Senha incorreta')
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
JOIN tb_usuario usuario ON usuario.username = 'usuario' || (21 + ((gs - 1) % 25))::TEXT;

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
    OFFSET ((serie.gs - 1) % (SELECT COUNT(*) FROM tb_usuario WHERE nivel_acesso = 'OPERADOR'))
    LIMIT 1
) AS operador
ORDER BY serie.gs;

COMMIT;
