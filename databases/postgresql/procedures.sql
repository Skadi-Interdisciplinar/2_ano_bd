CREATE OR REPLACE PROCEDURE sp_registrar_atendimento(
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

	IF EXISTS (
        SELECT 1 FROM tb_atendimento
        WHERE cod_alerta = p_cod_alerta AND status != 'pendente'
    ) THEN
        RAISE EXCEPTION 'Alerta % já está sendo atendido ou foi resolvido.', p_cod_alerta;
    END IF;

	UPDATE tb_atendimento
    SET cod_usuario = p_cod_usuario, data_hora_reconhecimento = CURRENT_TIMESTAMP, status = 'em_andamento'
    WHERE cod_alerta = p_cod_alerta AND status = 'pendente';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Nenhum atendimento pendente encontrado para o alerta %.', p_cod_alerta;
    END IF;

	UPDATE tb_alerta SET status = 'reconhecido' WHERE id = p_cod_alerta;
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
	SELECT p_cod_alerta, u.id
	FROM tb_usuario u
	JOIN tb_refrigerador r
        ON r.cod_cd = u.cod_cd
	JOIN tb_alerta a
        ON a.cod_refrigerador = r.id
	WHERE a.id = p_cod_alerta AND u.nivel_acesso = p_nivel;
END;
$$;