DROP TRIGGER IF EXISTS trg_criar_atendimento_pendente ON tb_alerta;
DROP TRIGGER IF EXISTS trg_resolver_atendimento_por_justificativa ON tb_justificativa;
DROP TRIGGER IF EXISTS trg_validar_temperatura_produto_refrigerador ON tb_produto_refrigerador;


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
BEGIN
	UPDATE tb_atendimento
	SET status = 'resolvido', data_hora_resolucao = CURRENT_TIMESTAMP
	WHERE id = NEW.cod_atendimento;
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