-- Executar apenas este arquivo no PostgreSQL existente; não recria tabelas.
-- Mantém a trigger existente e substitui somente a função chamada por ela.
BEGIN;

CREATE OR REPLACE FUNCTION fn_gerar_alerta_por_leitura()
RETURNS TRIGGER AS $$
DECLARE
    v_camara INTEGER;
    v_temperatura_min DECIMAL(5,2);
    v_temperatura_max DECIMAL(5,2);
    v_gravidade VARCHAR(20);
    v_vida_util INTERVAL;
    v_alerta INTEGER;
BEGIN
    SELECT cam.id, cam.temperatura_min, cam.temperatura_max
    INTO v_camara, v_temperatura_min, v_temperatura_max
    FROM tb_camara_frigorifica cam
    -- Serializa leituras da mesma câmara antes de verificar/criar o alerta.
    WHERE cam.cod_termometro = NEW.cod_termometro
    FOR UPDATE;

    IF v_camara IS NULL THEN
        RAISE EXCEPTION
            'Termômetro % não está associado a nenhuma câmara frigorífica.',
            NEW.cod_termometro;
    END IF;

    IF (NEW.temperatura < v_temperatura_min
        OR NEW.temperatura > v_temperatura_max)
       AND NOT EXISTS (
           SELECT 1
           FROM tb_alerta
           WHERE cod_camara_frigorifica = v_camara
             AND status IN ('ATIVO', 'RECONHECIDO')
       )
    THEN
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
            v_camara, v_vida_util, 'OPERADOR',
            NEW.data_hora, v_gravidade, 'ATIVO'
        )
        RETURNING id INTO v_alerta;

        UPDATE tb_leitura_temperatura
        SET cod_alerta = v_alerta
        WHERE id = NEW.id;

        CALL sp_notificar_nivel_acesso(v_alerta, 'OPERADOR');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMIT;
