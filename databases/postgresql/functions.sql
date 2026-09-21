CREATE OR REPLACE FUNCTION fn_calcular_vida_util_camara(
    p_cod_camara INTEGER
)
RETURNS DECIMAL(7,2) AS $$
DECLARE
    v_vida_util DECIMAL(7,2);
BEGIN
    SELECT MIN(c.vida_util_horas)
    INTO v_vida_util
    FROM tb_lote_camara_frigorifica lr
    JOIN tb_lote l 
        ON l.id = lr.cod_lote AND l.status = 'ativo'
    JOIN tb_categoria c 
        ON c.id = l.cod_categoria
    WHERE lr.cod_camara_frigorifica = p_cod_camara AND lr.data_saida IS NULL;

    IF v_vida_util IS NULL THEN
        RAISE EXCEPTION 'A câmara frigorífica % não possui lote ativo.', p_cod_camara;
    END IF;

    RETURN v_vida_util;
END;
$$ LANGUAGE plpgsql;


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

    SELECT COALESCE(a.vida_util_referencia_horas, fn_calcular_vida_util_camara(a.cod_camara_frigorifica))
    INTO v_vida_util
    FROM tb_alerta a
    WHERE a.id = p_cod_alerta;

    IF v_vida_util IS NULL THEN
        RAISE EXCEPTION 'Alerta % não possui vida útil de referência.', p_cod_alerta;
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

    SELECT lt.temperatura, MIN(c.temperatura_ideal)
    INTO v_temperatura_atual, v_temperatura_ideal
    FROM tb_camara_frigorifica r
    JOIN tb_lote_camara_frigorifica lr
        ON lr.cod_camara_frigorifica = r.id AND lr.data_saida IS NULL
    JOIN tb_lote l
        ON l.id = lr.cod_lote AND l.status = 'ativo'
    JOIN tb_categoria c
        ON c.id = l.cod_categoria
    JOIN tb_leitura_temperatura lt
        ON r.cod_termometro = lt.cod_termometro
    WHERE lt.id = p_cod_leitura
    GROUP BY lt.temperatura;

    IF v_temperatura_ideal IS NULL THEN
        RAISE EXCEPTION 'Nenhum lote ativo associado à câmara frigorífica da leitura %.', p_cod_leitura;
    END IF;

    v_diferenca := ABS(v_temperatura_atual - v_temperatura_ideal);

    IF v_diferenca <= 1 THEN
        RETURN 'estável';
    ELSIF v_diferenca <= 3 THEN
        RETURN 'atenção';
    ELSIF v_diferenca <= 5 THEN
        RETURN 'crítica';
    ELSE
        RETURN 'urgente';
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_camara_temperatura_normal(
    p_cod_camara INTEGER,
    p_data_hora TIMESTAMP
)
RETURNS BOOLEAN AS $$
DECLARE
    v_temperatura DECIMAL(5,2);
    v_temperatura_min DECIMAL(5,2);
    v_temperatura_max DECIMAL(5,2);
BEGIN
    SELECT lt.temperatura, c.temperatura_min, c.temperatura_max
    INTO v_temperatura, v_temperatura_min, v_temperatura_max
    FROM tb_camara_frigorifica c
    JOIN tb_leitura_temperatura lt
        ON c.cod_termometro = lt.cod_termometro
    WHERE c.id = p_cod_camara
       AND lt.data_hora <= p_data_hora
    ORDER BY lt.data_hora DESC, lt.id DESC
    LIMIT 1;

    RETURN v_temperatura IS NOT NULL
       AND v_temperatura BETWEEN v_temperatura_min AND v_temperatura_max;
END;
$$ LANGUAGE plpgsql;
