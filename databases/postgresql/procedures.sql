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
