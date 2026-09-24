CREATE OR REPLACE PROCEDURE sp_reconhecer_alerta(
    p_cod_alerta INTEGER,
    p_cod_usuario INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tb_alerta
        WHERE id = p_cod_alerta
    ) THEN
        RAISE EXCEPTION 'Alerta % não encontrado.', p_cod_alerta;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_usuario
        WHERE id = p_cod_usuario
    ) THEN
        RAISE EXCEPTION 'Usuário % não encontrado.', p_cod_usuario;
    END IF;

    UPDATE tb_atendimento
    SET cod_usuario = p_cod_usuario,
        data_hora_reconhecimento = CURRENT_TIMESTAMP,
        status = 'em_andamento'
    WHERE cod_alerta = p_cod_alerta AND status = 'pendente';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Nenhum atendimento pendente encontrado para o alerta %.', p_cod_alerta;
    END IF;

    UPDATE tb_alerta
    SET status = 'reconhecido'
    WHERE id = p_cod_alerta AND status = 'ativo';
END;
$$;


CREATE OR REPLACE PROCEDURE sp_notificar_nivel_acesso(
    p_cod_alerta INTEGER,
    p_nivel VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tb_alerta
        WHERE id = p_cod_alerta
    ) THEN
        RAISE EXCEPTION 'Alerta % não encontrado.', p_cod_alerta;
    END IF;

    IF p_nivel NOT IN ('operador', 'gestor', 'admin') THEN
        RAISE EXCEPTION 'Nível de acesso inválido: %.', p_nivel;
    END IF;

    INSERT INTO tb_notificacao_alerta (cod_alerta, cod_usuario)
    SELECT a.id, u.id
    FROM tb_alerta a
    JOIN tb_camara_frigorifica c
        ON c.id = a.cod_camara_frigorifica
    JOIN tb_usuario u
        ON u.cod_cd = c.cod_cd AND u.nivel_acesso = p_nivel
    WHERE a.id = p_cod_alerta;
END;
$$;


CREATE OR REPLACE PROCEDURE sp_escalonar_alertas_pendentes()
LANGUAGE plpgsql AS $$
DECLARE
    v_alerta RECORD;
    v_nivel_novo VARCHAR(8);
BEGIN
    FOR v_alerta IN
        SELECT id, nivel_atual, data_hora
        FROM tb_alerta
        WHERE status = 'ativo' AND nivel_atual IN ('operador', 'gestor')
    LOOP
        v_nivel_novo := NULL;

        IF CURRENT_TIMESTAMP >= v_alerta.data_hora
            + fn_calcular_prazo_escalonamento(v_alerta.id, 70) * INTERVAL '1 hour' THEN
            v_nivel_novo := 'admin';
        ELSIF CURRENT_TIMESTAMP >= v_alerta.data_hora
            + fn_calcular_prazo_escalonamento(v_alerta.id, 40) * INTERVAL '1 hour'
            AND v_alerta.nivel_atual = 'operador' THEN
            v_nivel_novo := 'gestor';
        END IF;

        IF v_nivel_novo IS NOT NULL THEN
            UPDATE tb_alerta 
            SET nivel_atual = v_nivel_novo
            WHERE id = v_alerta.id;

            CALL sp_notificar_nivel_acesso(v_alerta.id, v_nivel_novo);
        END IF;
    END LOOP;
END;
$$;


CREATE OR REPLACE PROCEDURE sp_cadastrar_usuario(
    p_nome VARCHAR(150),
    p_username VARCHAR(50),
    p_cpf VARCHAR(11),
    p_email VARCHAR(255),
    p_senha VARCHAR(255),
    p_nivel_acesso VARCHAR(8),
    p_cod_cd INTEGER,
    p_cod_gestor INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_cod_executor INTEGER;
    v_nivel_executor VARCHAR(8);
    v_cd_executor INTEGER;
    v_usuario_atual TEXT;
BEGIN
    v_usuario_atual := current_setting('app.usuario_atual', true);

    IF v_usuario_atual IS NULL OR v_usuario_atual = '' THEN
        RAISE EXCEPTION 'Usuário executor não informado.';
    END IF;

    BEGIN
        v_cod_executor := v_usuario_atual::INTEGER;
    EXCEPTION WHEN invalid_text_representation THEN
        RAISE EXCEPTION 'app.usuario_atual deve conter um ID inteiro.';
    END;

    SELECT u.nivel_acesso, u.cod_cd
    INTO v_nivel_executor, v_cd_executor
    FROM tb_usuario u
    WHERE u.id = v_cod_executor;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário executor % não encontrado.', v_cod_executor;
    END IF;

    IF p_nivel_acesso NOT IN ('operador', 'gestor', 'admin') THEN
        RAISE EXCEPTION 'Nível de acesso inválido para cadastro: %.', p_nivel_acesso;
    END IF;

    IF p_cod_cd IS NULL THEN
        RAISE EXCEPTION 'O CD do novo usuário é obrigatório.';
    END IF;

    IF v_nivel_executor = 'admin' THEN
        IF v_cd_executor IS DISTINCT FROM p_cod_cd THEN
            RAISE EXCEPTION 'O administrador só pode cadastrar usuários do próprio CD.';
        END IF;

        IF p_nivel_acesso = 'admin' THEN
            RAISE EXCEPTION 'Administradores não podem cadastrar outro administrador.';
        END IF;
    ELSIF v_nivel_executor = 'sistema' THEN
        IF p_nivel_acesso <> 'admin' THEN
            RAISE EXCEPTION 'O sistema só pode cadastrar o administrador inicial do CD.';
        END IF;

        IF EXISTS (
            SELECT 1
            FROM tb_usuario u
            WHERE u.cod_cd = p_cod_cd
              AND u.nivel_acesso = 'admin'
        ) THEN
            RAISE EXCEPTION 'O CD % já possui um administrador.', p_cod_cd;
        END IF;
    ELSE
        RAISE EXCEPTION 'O usuário executor não possui permissão para cadastrar usuários.';
    END IF;

    IF p_nivel_acesso <> 'operador' AND p_cod_gestor IS NOT NULL THEN
        RAISE EXCEPTION 'Somente operadores podem possuir um gestor responsável.';
    END IF;

    INSERT INTO tb_usuario (
        nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor
    ) VALUES (
        p_nome, p_username, p_cpf, p_email, p_senha,
        p_nivel_acesso, p_cod_cd, p_cod_gestor
    );
END;
$$;
