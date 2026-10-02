DROP TRIGGER IF EXISTS trg_criar_atendimento_pendente ON tb_alerta;
DROP TRIGGER IF EXISTS trg_resolver_atendimento_por_justificativa ON tb_justificativa;
DROP TRIGGER IF EXISTS trg_validar_temperatura_categoria_camara ON tb_lote_camara_frigorifica;
DROP TRIGGER IF EXISTS trg_gerar_alerta_por_leitura ON tb_leitura_temperatura;
DROP TRIGGER IF EXISTS trg_notificar_novo_alerta ON tb_alerta;
DROP TRIGGER IF EXISTS trg_validar_gestor_usuario ON tb_usuario;
DROP TRIGGER IF EXISTS trg_validar_solicitacao_suporte ON tb_solicitacao_suporte;

CREATE OR REPLACE FUNCTION fn_validar_gestor_usuario()
RETURNS TRIGGER AS $$
BEGIN
    -- Super ADM administra a plataforma e não possui CPF, CD ou gestor.
    IF NEW.nivel_acesso = 'super_admin' THEN
        IF NEW.cpf IS NOT NULL THEN
            RAISE EXCEPTION
                'Usuário super_admin não pode possuir CPF.';
        END IF;

        IF NEW.cod_cd IS NOT NULL THEN
            RAISE EXCEPTION
                'Usuário super_admin não pode estar vinculado a um CD.';
        END IF;

        IF NEW.cod_gestor IS NOT NULL THEN
            RAISE EXCEPTION
                'Usuário super_admin não pode possuir gestor responsável.';
        END IF;

        RETURN NEW;
    END IF;

    -- ADM, Gestor e Operador devem possuir CPF e CD.
    IF NEW.cpf IS NULL THEN
        RAISE EXCEPTION
            'Usuário com nível % deve possuir CPF.',
            NEW.nivel_acesso;
    END IF;

    IF NEW.cod_cd IS NULL THEN
        RAISE EXCEPTION
            'Usuário com nível % deve estar vinculado a um CD.',
            NEW.nivel_acesso;
    END IF;

    -- ADM e Gestor não possuem gestor responsável.
    IF NEW.nivel_acesso IN ('admin', 'gestor')
       AND NEW.cod_gestor IS NOT NULL THEN
        RAISE EXCEPTION
            'Usuário com nível % não pode possuir gestor responsável.',
            NEW.nivel_acesso;
    END IF;

    -- Operador deve possuir gestor responsável.
    IF NEW.nivel_acesso = 'operador'
       AND NEW.cod_gestor IS NULL THEN
        RAISE EXCEPTION
            'Usuário operador deve possuir gestor responsável.';
    END IF;

    -- O gestor do operador deve ser gestor e pertencer ao mesmo CD.
    IF NEW.nivel_acesso = 'operador'
       AND NOT EXISTS (
            SELECT 1
            FROM tb_usuario gestor
            WHERE gestor.id = NEW.cod_gestor
              AND gestor.nivel_acesso = 'gestor'
              AND gestor.cod_cd = NEW.cod_cd
       ) THEN
        RAISE EXCEPTION
            'O gestor % deve existir, ter nível gestor e pertencer ao mesmo CD do operador %.',
            NEW.cod_gestor,
            NEW.id;
    END IF;

    -- Um gestor não pode deixar de ser gestor enquanto possuir operadores vinculados.
    IF TG_OP = 'UPDATE'
       AND OLD.nivel_acesso = 'gestor'
       AND NEW.nivel_acesso <> 'gestor'
       AND EXISTS (
            SELECT 1
            FROM tb_usuario subordinado
            WHERE subordinado.cod_gestor = OLD.id
       ) THEN
        RAISE EXCEPTION
            'O gestor % não pode perder o cargo enquanto possuir operadores vinculados.',
            OLD.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_gestor_usuario
BEFORE INSERT OR UPDATE OF cpf, cod_gestor, cod_cd, nivel_acesso
ON tb_usuario
FOR EACH ROW
EXECUTE FUNCTION fn_validar_gestor_usuario();


CREATE OR REPLACE FUNCTION fn_validar_solicitacao_suporte()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.cod_usuario_responsavel IS NOT NULL
       AND NOT EXISTS (
            SELECT 1
            FROM tb_usuario usuario_responsavel
            WHERE usuario_responsavel.id = NEW.cod_usuario_responsavel
              AND usuario_responsavel.nivel_acesso = 'super_admin'
       ) THEN
        RAISE EXCEPTION
            'O responsável da solicitação de suporte deve possuir nível super_admin.';
    END IF;

    IF TG_OP = 'INSERT' AND NEW.status <> 'registrado' THEN
        RAISE EXCEPTION
            'Uma solicitação de suporte deve ser criada com status registrado.';
    END IF;

    IF NEW.status = 'registrado' THEN
        IF NEW.cod_usuario_responsavel IS NOT NULL
           OR NEW.resposta IS NOT NULL
           OR NEW.data_hora_encerramento IS NOT NULL THEN
            RAISE EXCEPTION
                'Uma solicitação registrada não pode possuir responsável, resposta ou data de encerramento.';
        END IF;
    ELSIF NEW.status = 'em_atendimento' THEN
        IF NEW.cod_usuario_responsavel IS NULL THEN
            RAISE EXCEPTION
                'Uma solicitação em atendimento deve possuir um responsável super_admin.';
        END IF;

        IF NEW.data_hora_encerramento IS NOT NULL THEN
            RAISE EXCEPTION
                'Uma solicitação em atendimento não pode possuir data de encerramento.';
        END IF;
    ELSIF NEW.status = 'atendido' THEN
        IF NEW.cod_usuario_responsavel IS NULL
           OR NEW.resposta IS NULL
           OR NEW.data_hora_encerramento IS NULL THEN
            RAISE EXCEPTION
                'Uma solicitação atendida deve possuir responsável, resposta e data de encerramento.';
        END IF;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF OLD.status = 'registrado'
           AND NEW.status NOT IN ('registrado', 'em_atendimento') THEN
            RAISE EXCEPTION
                'A solicitação deve passar de registrado para em_atendimento antes de ser atendida.';
        END IF;

        IF OLD.status = 'em_atendimento'
           AND NEW.status NOT IN ('em_atendimento', 'atendido') THEN
            RAISE EXCEPTION
                'A solicitação em atendimento só pode permanecer nesse status ou ser atendida.';
        END IF;

        IF OLD.status = 'atendido' AND NEW.status <> 'atendido' THEN
            RAISE EXCEPTION
                'Uma solicitação atendida não pode retornar a um status anterior.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_solicitacao_suporte
BEFORE INSERT OR UPDATE OF status, resposta, data_hora_encerramento, cod_usuario_responsavel
ON tb_solicitacao_suporte
FOR EACH ROW
EXECUTE FUNCTION fn_validar_solicitacao_suporte();


CREATE OR REPLACE FUNCTION fn_criar_atendimento_pendente()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO tb_atendimento (cod_alerta, status)
    VALUES (NEW.id, 'pendente');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_criar_atendimento_pendente
AFTER INSERT ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_criar_atendimento_pendente();


CREATE OR REPLACE FUNCTION fn_resolver_atendimento_por_justificativa()
RETURNS TRIGGER AS $$
DECLARE
    v_cod_alerta INTEGER;
    v_cod_camara INTEGER;
    v_data_alerta TIMESTAMP;
    v_status_atendimento VARCHAR(50);
BEGIN
    SELECT
        a.id,
        a.cod_camara_frigorifica,
        a.data_hora,
        atd.status
    INTO
        v_cod_alerta,
        v_cod_camara,
        v_data_alerta,
        v_status_atendimento
    FROM tb_atendimento atd
    JOIN tb_alerta a
        ON a.id = atd.cod_alerta
    WHERE atd.id = NEW.cod_atendimento;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Atendimento % não encontrado.',
            NEW.cod_atendimento;
    END IF;

    IF v_status_atendimento <> 'em_andamento' THEN
        RAISE EXCEPTION
            'O atendimento precisa estar em andamento para ser resolvido.';
    END IF;

    IF fn_camara_temperatura_normal(
        v_cod_camara,
        CURRENT_TIMESTAMP::TIMESTAMP
    ) THEN

        UPDATE tb_atendimento
           SET status = 'resolvido',
               data_hora_resolucao = CURRENT_TIMESTAMP
         WHERE id = NEW.cod_atendimento;

        UPDATE tb_alerta
           SET status = 'resolvido'
         WHERE id = v_cod_alerta;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_resolver_atendimento_por_justificativa
AFTER INSERT ON tb_justificativa
FOR EACH ROW EXECUTE FUNCTION fn_resolver_atendimento_por_justificativa();


CREATE OR REPLACE FUNCTION fn_validar_temperatura_categoria_camara()
RETURNS TRIGGER AS $$
DECLARE
    v_categoria_temp_min DECIMAL(5,2);
    v_categoria_temp_max DECIMAL(5,2);
    v_camara_temp_min DECIMAL(5,2);
    v_camara_temp_max DECIMAL(5,2);
BEGIN
    SELECT
        c.temperatura_min,
        c.temperatura_max,
        cam.temperatura_min,
        cam.temperatura_max
      INTO
        v_categoria_temp_min,
        v_categoria_temp_max,
        v_camara_temp_min,
        v_camara_temp_max
      FROM tb_lote l
      JOIN tb_categoria c ON c.id = l.cod_categoria
      JOIN tb_camara_frigorifica cam ON cam.id = NEW.cod_camara_frigorifica
     WHERE l.id = NEW.cod_lote;

    IF v_categoria_temp_min IS NULL THEN
        RAISE EXCEPTION 'Lote % ou câmara frigorífica % não encontrado.', NEW.cod_lote, NEW.cod_camara_frigorifica;
    END IF;

    IF v_categoria_temp_min < v_camara_temp_min
       OR v_categoria_temp_max > v_camara_temp_max THEN
        RAISE EXCEPTION
            'Faixa da categoria (% a %) incompatível com a faixa da câmara frigorífica (% a %).',
            v_categoria_temp_min,
            v_categoria_temp_max,
            v_camara_temp_min,
            v_camara_temp_max;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_temperatura_categoria_camara
BEFORE INSERT OR UPDATE OF cod_lote, cod_camara_frigorifica, data_saida
ON tb_lote_camara_frigorifica
FOR EACH ROW EXECUTE FUNCTION fn_validar_temperatura_categoria_camara();


CREATE OR REPLACE FUNCTION fn_gerar_alerta_por_leitura()
RETURNS TRIGGER AS $$
DECLARE
    v_camara INTEGER;
    v_temperatura_min DECIMAL(5,2);
    v_temperatura_max DECIMAL(5,2);
    v_gravidade VARCHAR(20);
    v_vida_util DECIMAL(7,2);
    v_alerta INTEGER;
BEGIN
    SELECT cam.id, cam.temperatura_min, cam.temperatura_max
    INTO v_camara, v_temperatura_min, v_temperatura_max
    FROM tb_camara_frigorifica cam
    WHERE cam.cod_termometro = NEW.cod_termometro;

    IF v_camara IS NULL THEN
        RAISE EXCEPTION 'Termômetro % não está associado a nenhuma câmara frigorífica.', NEW.cod_termometro;
    END IF;

    IF NEW.temperatura < v_temperatura_min OR NEW.temperatura > v_temperatura_max THEN

        v_gravidade := fn_calcular_gravidade_alerta(NEW.id);
        v_vida_util := fn_calcular_vida_util_camara(v_camara);

        INSERT INTO tb_alerta (
            cod_camara_frigorifica,
            vida_util_referencia_horas,
            nivel_atual,
            data_hora,
            nivel_gravidade,
            status
        )
        VALUES (
            v_camara,
            v_vida_util,
            'operador',
            NEW.data_hora,
            v_gravidade,
            'ativo'
        )
        RETURNING id INTO v_alerta;

        UPDATE tb_leitura_temperatura
           SET cod_alerta = v_alerta
         WHERE id = NEW.id;

        CALL sp_notificar_nivel_acesso(v_alerta, 'operador');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gerar_alerta_por_leitura
AFTER INSERT ON tb_leitura_temperatura
FOR EACH ROW EXECUTE FUNCTION fn_gerar_alerta_por_leitura();


CREATE OR REPLACE FUNCTION fn_notificar_novo_alerta()
RETURNS TRIGGER AS $$
DECLARE
    v_horas_prazo DECIMAL(7,2);
BEGIN
    v_horas_prazo := fn_calcular_prazo_escalonamento(NEW.id, 40);

    PERFORM pg_notify(
        'novo_alerta',
        json_build_object(
            'id_alerta', NEW.id,
            'prazo_epoch',
            EXTRACT(EPOCH FROM (
                NEW.data_hora + v_horas_prazo * INTERVAL '1 hour'
            ) AT TIME ZONE 'America/Sao_Paulo')
        )::text
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notificar_novo_alerta
AFTER INSERT ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_notificar_novo_alerta();
