DROP TRIGGER IF EXISTS trg_criar_atendimento_pendente ON tb_alerta;
DROP TRIGGER IF EXISTS trg_resolver_atendimento_por_justificativa ON tb_justificativa;
DROP TRIGGER IF EXISTS trg_validar_temperatura_categoria_refrigerador ON tb_lote_refrigerador;
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
BEGIN
	SELECT cod_alerta
	INTO v_cod_alerta
	FROM tb_atendimento
	WHERE id = NEW.cod_atendimento;

	UPDATE tb_atendimento
	SET status = 'resolvido', data_hora_resolucao = CURRENT_TIMESTAMP
	WHERE id = NEW.cod_atendimento;

	UPDATE tb_alerta
	SET status = 'resolvido'
	WHERE id = v_cod_alerta;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_resolver_atendimento_por_justificativa
AFTER INSERT ON tb_justificativa
FOR EACH ROW EXECUTE FUNCTION fn_resolver_atendimento_por_justificativa();


CREATE OR REPLACE FUNCTION fn_validar_temperatura_categoria_refrigerador()
RETURNS TRIGGER AS $$
DECLARE
	v_temp_ideal DECIMAL(5,2);
	v_temp_min DECIMAL(5,2);
	v_temp_max DECIMAL(5,2);
BEGIN
	SELECT c.temperatura_ideal, r.temperatura_min, r.temperatura_max
	INTO v_temp_ideal, v_temp_min, v_temp_max
	FROM tb_lote l
	JOIN tb_categoria c 
        ON c.id = l.cod_categoria
	CROSS JOIN tb_refrigerador r
	WHERE l.id = NEW.cod_lote AND r.id = NEW.cod_refrigerador;

	IF v_temp_ideal IS NULL THEN
		RAISE EXCEPTION 'Lote % ou refrigerador % não encontrado.', NEW.cod_lote, NEW.cod_refrigerador;
	END IF;
	IF EXISTS (
		SELECT 1
		FROM tb_lote_refrigerador lr
		JOIN tb_lote lote_existente 
            ON lote_existente.id = lr.cod_lote
		WHERE lr.cod_refrigerador = NEW.cod_refrigerador
            AND lr.data_saida IS NULL
		    AND lr.cod_lote <> NEW.cod_lote
		    AND lote_existente.cod_categoria <> (SELECT cod_categoria FROM tb_lote WHERE id = NEW.cod_lote)
	) THEN
		RAISE EXCEPTION 'O refrigerador % já possui lote ativo de outra categoria.', NEW.cod_refrigerador;
	END IF;
	IF v_temp_ideal < v_temp_min OR v_temp_ideal > v_temp_max THEN
		RAISE EXCEPTION 'Temperatura ideal da categoria (%) incompatível com a faixa do refrigerador (% a %).', v_temp_ideal, v_temp_min, v_temp_max;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_temperatura_categoria_refrigerador
BEFORE INSERT OR UPDATE ON tb_lote_refrigerador
FOR EACH ROW EXECUTE FUNCTION fn_validar_temperatura_categoria_refrigerador();


CREATE OR REPLACE FUNCTION fn_gerar_alerta_por_leitura()
RETURNS TRIGGER AS $$
DECLARE
    v_refrigerador INTEGER;
    v_temperatura_min DECIMAL(5,2);
    v_temperatura_max DECIMAL(5,2);
    v_gravidade VARCHAR(20);
    v_canal VARCHAR(100);
    v_alerta INTEGER;
BEGIN
    SELECT
        r.id,
        r.temperatura_min,
        r.temperatura_max
    INTO
        v_refrigerador,
        v_temperatura_min,
        v_temperatura_max
    FROM tb_refrigerador r
    JOIN tb_lote_refrigerador lr 
        ON lr.cod_refrigerador = r.id AND lr.data_saida IS NULL
    JOIN tb_lote l 
        ON l.id = lr.cod_lote AND l.status = 'ativo'
    WHERE r.cod_termometro = NEW.cod_termometro
    ORDER BY l.data_validade
    LIMIT 1;

	IF v_refrigerador IS NULL THEN
        RAISE EXCEPTION 'Termômetro % não está associado a nenhum refrigerador.', NEW.cod_termometro;
    END IF;

    -- Verifica se a temperatura está fora da faixa permitida
    IF NEW.temperatura < v_temperatura_min
       OR NEW.temperatura > v_temperatura_max THEN

        -- Calcula a gravidade utilizando a function existente
        v_gravidade := fn_calcular_gravidade_alerta(NEW.id);

        -- Define o canal de acordo com a gravidade
        CASE v_gravidade
            WHEN 'baixa' THEN
                v_canal := 'E-mail';

            WHEN 'media' THEN
                v_canal := 'E-mail';

            WHEN 'alta' THEN
                v_canal := 'Whatsapp';

            WHEN 'critica' THEN
                v_canal := 'SMS';
        END CASE;

        -- Cria o alerta
        INSERT INTO tb_alerta (
            cod_refrigerador,
            nivel_atual,
            data_hora,
            nivel_gravidade,
            status,
            canal
        )
        VALUES (
            v_refrigerador,
            'operador',
            NEW.data_hora,
            v_gravidade,
            'ativo',
            v_canal
        )
        RETURNING id INTO v_alerta;

        -- Relaciona a leitura ao alerta
        UPDATE tb_leitura_temperatura
        SET cod_alerta = v_alerta
        WHERE id = NEW.id;

        -- Notifica os usuários do nível atual do alerta
        CALL sp_notificar_nivel_acesso(
            v_alerta,
            'operador'
        );

    END IF;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_gerar_alerta_por_leitura
AFTER INSERT ON tb_leitura_temperatura
FOR EACH ROW
EXECUTE FUNCTION fn_gerar_alerta_por_leitura();


CREATE OR REPLACE FUNCTION fn_notificar_novo_alerta()
RETURNS TRIGGER AS $$
DECLARE
	v_horas_prazo DECIMAL(5,2);
BEGIN
	-- A vida útil da categoria é expressa em horas.
	v_horas_prazo := fn_calcular_prazo_escalonamento(NEW.id, 40); -- 40% para 1º escalonamento (operador -> gestor)
 
	PERFORM pg_notify('novo_alerta', json_build_object(
		'id_alerta', NEW.id,
		'prazo_epoch', EXTRACT(EPOCH FROM (NEW.data_hora + v_horas_prazo * INTERVAL '1 hour') AT TIME ZONE 'America/Sao_Paulo')
	)::text);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_notificar_novo_alerta
AFTER INSERT ON tb_alerta
FOR EACH ROW
EXECUTE FUNCTION fn_notificar_novo_alerta();
