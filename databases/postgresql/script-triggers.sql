DROP TRIGGER IF EXISTS trg_criar_atendimento_pendente ON tb_alerta;
DROP TRIGGER IF EXISTS trg_resolver_atendimento_por_justificativa ON tb_justificativa;
DROP TRIGGER IF EXISTS trg_validar_temperatura_produto_refrigerador ON tb_produto_refrigerador;
DROP TRIGGER IF EXISTS trg_gerar_alerta_por_leitura ON tb_leitura_temperatura;


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


CREATE OR REPLACE FUNCTION fn_validar_temperatura_produto_refrigerador() 
RETURNS TRIGGER AS $$
DECLARE
	v_temp_novo DECIMAL(5,2);
	v_temp_existente DECIMAL(5,2);
BEGIN
	SELECT temperatura_ideal 
	INTO v_temp_novo 
	FROM tb_produto 
	WHERE id = NEW.cod_produto;

	SELECT p.temperatura_ideal 
	INTO v_temp_existente
	FROM tb_produto p
	JOIN tb_produto_refrigerador pr 
		ON pr.cod_produto = p.id
	WHERE pr.cod_refrigerador = NEW.cod_refrigerador
	LIMIT 1;

	IF v_temp_existente IS NOT NULL AND v_temp_existente != v_temp_novo THEN
		RAISE EXCEPTION 'Produto com temperatura ideal % incompatível com refrigerador (já há produto com temperatura %).', v_temp_novo, v_temp_existente;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_temperatura_produto_refrigerador
BEFORE INSERT ON tb_produto_refrigerador
FOR EACH ROW EXECUTE FUNCTION fn_validar_temperatura_produto_refrigerador();


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
    WHERE r.cod_termometro = NEW.cod_termometro;

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