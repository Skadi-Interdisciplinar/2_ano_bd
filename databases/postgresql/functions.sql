CREATE OR REPLACE FUNCTION fn_calcular_prazo_escalonamento(
    p_cod_alerta INTEGER,
    p_percentual INTEGER
)
RETURNS DECIMAL(7,2) AS $$
DECLARE
    v_vida_util DECIMAL(7,2);
BEGIN
    IF p_percentual < 0 OR p_percentual > 100 THEN
        RAISE EXCEPTION 'Percentual de escalonamento inválido. O valor deve estar entre 0 e 100.';
    END IF;

    SELECT c.vida_util_horas
    INTO v_vida_util
    FROM tb_alerta a
    JOIN tb_lote_refrigerador lr 
        ON lr.cod_refrigerador = a.cod_refrigerador AND lr.data_saida IS NULL
    JOIN tb_lote l 
        ON l.id = lr.cod_lote
    JOIN tb_categoria c 
        ON c.id = l.cod_categoria
    WHERE a.id = p_cod_alerta
    ORDER BY l.data_validade
    LIMIT 1;

    IF v_vida_util IS NULL THEN
        RAISE EXCEPTION 'Alerta % não possui lote/categoria válidos.', p_cod_alerta;
    END IF;

    RETURN v_vida_util * p_percentual / 100;
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

    SELECT lt.temperatura, c.temperatura_ideal
    INTO v_temperatura_atual, v_temperatura_ideal
    FROM tb_refrigerador r
    JOIN tb_lote_refrigerador lr 
        ON lr.cod_refrigerador = r.id AND lr.data_saida IS NULL
    JOIN tb_lote l 
        ON l.id = lr.cod_lote AND l.status = 'ativo'
    JOIN tb_categoria c 
        ON c.id = l.cod_categoria
    JOIN tb_leitura_temperatura lt 
        ON r.cod_termometro = lt.cod_termometro
    WHERE lt.id = p_cod_leitura
    ORDER BY l.data_validade
    LIMIT 1;

    IF v_temperatura_ideal IS NULL THEN
        RAISE EXCEPTION 'Nenhum lote ativo associado ao refrigerador da leitura %.', p_cod_leitura;
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
