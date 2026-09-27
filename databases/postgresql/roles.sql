-- ====================================================================
-- ROLES E USUÁRIOS DO POSTGRESQL
-- ====================================================================

-- 1. SYSTEM ROLES
-- Estas roles controlam acessos técnicos ao banco. Os níveis operador,
-- gestor e admin pertencem à aplicação e ficam em tb_usuario.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sys_database_admin') THEN
        EXECUTE 'CREATE ROLE sys_database_admin NOLOGIN';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'skadi_worker') THEN
        EXECUTE 'CREATE ROLE skadi_worker NOLOGIN';
    END IF;
END;
$$;

-- 2. USERS
-- As senhas abaixo são placeholders e devem ser substituídas fora do repositório.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'giovanna') THEN
        EXECUTE 'CREATE USER giovanna WITH PASSWORD ''CHANGE_PASSWORD_GIOVANNA''';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mariana') THEN
        EXECUTE 'CREATE USER mariana WITH PASSWORD ''CHANGE_PASSWORD_MARIANA''';
    END IF;
END;
$$;

-- 3. ROLE ASSIGNMENTS
GRANT sys_database_admin TO giovanna;
GRANT sys_database_admin TO mariana;

-- 4. DATABASE ADMIN
GRANT USAGE, CREATE ON SCHEMA public TO sys_database_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sys_database_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO sys_database_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO sys_database_admin;

GRANT EXECUTE ON PROCEDURE sp_reconhecer_alerta(INTEGER, INTEGER)
TO sys_database_admin;
GRANT EXECUTE ON PROCEDURE sp_cadastrar_usuario(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INTEGER, INTEGER)
TO sys_database_admin;

-- 5. WORKER
GRANT USAGE ON SCHEMA public TO skadi_worker;
GRANT SELECT ON
    tb_camara_frigorifica,
    tb_lote_camara_frigorifica,
    tb_lote,
    tb_categoria
TO skadi_worker;
GRANT SELECT (id, nivel_acesso, cod_cd)
ON tb_usuario TO skadi_worker;
GRANT INSERT ON tb_leitura_temperatura TO skadi_worker;
GRANT UPDATE (cod_alerta) ON tb_leitura_temperatura TO skadi_worker;
GRANT INSERT ON tb_alerta, tb_atendimento, tb_notificacao_alerta TO skadi_worker;
GRANT USAGE, SELECT ON SEQUENCE
    tb_leitura_temperatura_id_seq,
    tb_alerta_id_seq,
    tb_atendimento_id_seq,
    tb_notificacao_alerta_id_seq
TO skadi_worker;
GRANT EXECUTE ON PROCEDURE sp_notificar_nivel_acesso(INTEGER, VARCHAR)
TO skadi_worker;
GRANT EXECUTE ON PROCEDURE sp_escalonar_alertas_pendentes()
TO skadi_worker;

-- 6. DEFAULT PRIVILEGES
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON TABLES TO sys_database_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON SEQUENCES TO sys_database_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON FUNCTIONS TO sys_database_admin;

-- Procedures sensíveis não ficam disponíveis para PUBLIC.
REVOKE EXECUTE ON PROCEDURE sp_reconhecer_alerta(INTEGER, INTEGER) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE sp_notificar_nivel_acesso(INTEGER, VARCHAR) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE sp_escalonar_alertas_pendentes() FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE sp_cadastrar_usuario(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INTEGER, INTEGER) FROM PUBLIC;
