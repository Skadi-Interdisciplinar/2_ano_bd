DROP TRIGGER IF EXISTS trg_criar_atendimento_pendente ON tb_alerta;
DROP TRIGGER IF EXISTS trg_resolver_atendimento_por_justificativa ON tb_justificativa;
DROP TRIGGER IF EXISTS trg_validar_temperatura_categoria_camara ON tb_lote_camara_frigorifica;
DROP TRIGGER IF EXISTS trg_gerar_alerta_por_leitura ON tb_leitura_temperatura;
DROP TRIGGER IF EXISTS trg_notificar_novo_alerta ON tb_alerta;


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
        CURRENT_TIMESTAMP
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
    v_temp_ideal DECIMAL(5,2);
    v_temp_min DECIMAL(5,2);
    v_temp_max DECIMAL(5,2);
BEGIN
    SELECT c.temperatura_ideal, cam.temperatura_min, cam.temperatura_max
      INTO v_temp_ideal, v_temp_min, v_temp_max
      FROM tb_lote l
      JOIN tb_categoria c ON c.id = l.cod_categoria
      JOIN tb_camara_frigorifica cam ON cam.id = NEW.cod_camara_frigorifica
     WHERE l.id = NEW.cod_lote;

    IF v_temp_ideal IS NULL THEN
        RAISE EXCEPTION 'Lote % ou câmara frigorífica % não encontrado.', NEW.cod_lote, NEW.cod_camara_frigorifica;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM tb_lote_camara_frigorifica lr
          JOIN tb_lote lote_existente
            ON lote_existente.id = lr.cod_lote
          JOIN tb_categoria categoria_existente
            ON categoria_existente.id = lote_existente.cod_categoria
         WHERE lr.cod_camara_frigorifica = NEW.cod_camara_frigorifica
           AND lr.data_saida IS NULL
           AND lr.cod_lote <> NEW.cod_lote
           AND lote_existente.status = 'ativo'
           AND categoria_existente.temperatura_ideal IS DISTINCT FROM v_temp_ideal
    ) THEN
        RAISE EXCEPTION 'A câmara frigorífica % já possui lote ativo com temperatura ideal incompatível.', NEW.cod_camara_frigorifica;
    END IF;

    IF v_temp_ideal < v_temp_min OR v_temp_ideal > v_temp_max THEN
        RAISE EXCEPTION 'Temperatura ideal da categoria (%) incompatível com a faixa da câmara frigorífica (% a %).',
            v_temp_ideal, v_temp_min, v_temp_max;
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
