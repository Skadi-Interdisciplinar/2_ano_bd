CREATE OR REPLACE FUNCTION fn_calcular_prazo_escalonamento(
    p_cod_alerta INTEGER,
    p_percentual INTEGER
)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_tempo_sobrevivencia DECIMAL(5,2);
    v_resultado DECIMAL(5,2);
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tb_alerta
        WHERE id = p_cod_alerta
    ) THEN
        RAISE EXCEPTION 'Alerta % não encontrado.', p_cod_alerta;
    END IF;

    IF p_percentual < 0 OR p_percentual > 100 THEN
        RAISE EXCEPTION 'Percentual de escalonamento inválido. O valor deve estar entre 0 e 100.';
    END IF;

    SELECT MIN(p.tempo_sobrevivencia)
    INTO v_tempo_sobrevivencia
    FROM tb_produto p
    JOIN tb_produto_refrigerador pr 
        ON p.id = pr.cod_produto
    JOIN tb_refrigerador r 
        ON pr.cod_refrigerador = r.id
    JOIN tb_alerta a 
        ON r.id = a.cod_refrigerador
    WHERE a.id = p_cod_alerta;

    IF v_tempo_sobrevivencia IS NULL THEN
        RAISE EXCEPTION 'Nenhum produto associado ao refrigerador do alerta %.', p_cod_alerta;
    END IF;

    v_resultado := v_tempo_sobrevivencia * p_percentual / 100;

    RETURN v_resultado;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_calcular_gravidade_alerta(
    p_cod_leitura INTEGER
)
RETURNS VARCHAR AS $$
DECLARE
    v_temperatura_atual DECIMAL(5,2);
    v_temperatura_ideal DECIMAL(5,2);
    v_diferenca DECIMAL(5,2);
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tb_leitura_temperatura
        WHERE id = p_cod_leitura
    ) THEN
        RAISE EXCEPTION 'Leitura de temperatura % não encontrada.', p_cod_leitura;
    END IF;

    SELECT lt.temperatura, MIN(p.temperatura_ideal)
    INTO v_temperatura_atual, v_temperatura_ideal
    FROM tb_produto p
    JOIN tb_produto_refrigerador pr 
        ON p.id = pr.cod_produto
    JOIN tb_refrigerador r 
        ON pr.cod_refrigerador = r.id
    JOIN tb_leitura_temperatura lt 
        ON r.cod_termometro = lt.cod_termometro
    WHERE lt.id = p_cod_leitura
    GROUP BY lt.temperatura;

    IF v_temperatura_ideal IS NULL THEN
        RAISE EXCEPTION 'Nenhum produto associado ao refrigerador da leitura %.', p_cod_leitura;
    END IF;

    v_diferenca := ABS(v_temperatura_atual - v_temperatura_ideal);

    IF v_diferenca <= 1 THEN
        RETURN 'baixa';
    ELSIF v_diferenca <= 3 THEN
        RETURN 'media';
    ELSIF v_diferenca <= 5 THEN
        RETURN 'alta';
    ELSE
        RETURN 'critica';
    END IF;
END;
$$ LANGUAGE plpgsql;