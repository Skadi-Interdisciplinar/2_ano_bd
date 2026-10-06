-- ====================================================================
-- TRANSFORMAÇÕES ETL: CTEs, WINDOW FUNCTIONS E CTE RECURSIVA
-- ====================================================================

WITH leituras_classificadas AS (
	SELECT
		lt.id AS cod_leitura,
		lt.cod_termometro,
		cam.id AS cod_camara_frigorifica,
		cam.localizacao,
		cd.id AS cod_cd,
		cd.nome AS centro_distribuicao,
		lt.temperatura,
		cam.temperatura_min,
		cam.temperatura_max,
		lt.data_hora,
		lt.cod_alerta,
		CASE
			WHEN lt.temperatura BETWEEN cam.temperatura_min AND cam.temperatura_max
				THEN 'NORMAL'
			ELSE 'FORA_DA_FAIXA'
		END AS classificacao
	FROM tb_leitura_temperatura lt
	JOIN tb_camara_frigorifica cam
	  ON cam.cod_termometro = lt.cod_termometro
	JOIN tb_cd cd
	  ON cd.id = cam.cod_cd
)
SELECT
	leituras_classificadas.*,
	LAG(temperatura) OVER (
		PARTITION BY cod_termometro
		ORDER BY data_hora, cod_leitura
	) AS temperatura_anterior,
	temperatura - LAG(temperatura) OVER (
		PARTITION BY cod_termometro
		ORDER BY data_hora, cod_leitura
	) AS variacao_desde_leitura_anterior,
	AVG(temperatura) OVER (
		PARTITION BY cod_termometro
		ORDER BY data_hora, cod_leitura
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	) AS temperatura_media_acumulada,
	ROW_NUMBER() OVER (
		PARTITION BY cod_camara_frigorifica
		ORDER BY data_hora DESC, cod_leitura DESC
	) AS ordem_leitura_mais_recente
FROM leituras_classificadas;


WITH lotes_ativos AS (
	SELECT
		l.id AS cod_lote,
		l.codigo_lote,
		c.nome AS categoria,
		c.vida_util_horas,
		lc.cod_camara_frigorifica,
		lc.data_entrada
	FROM tb_lote l
	JOIN tb_categoria c
	  ON c.id = l.cod_categoria
	JOIN tb_lote_camara_frigorifica lc
	  ON lc.cod_lote = l.id
	 AND lc.data_saida IS NULL
	WHERE l.status = 'ATIVO'
)
SELECT
	lotes_ativos.*,
	MIN(vida_util_horas) OVER (
		PARTITION BY cod_camara_frigorifica
	) AS menor_vida_util_camara,
	COUNT(*) OVER (
		PARTITION BY cod_camara_frigorifica
	) AS total_lotes_ativos_camara
FROM lotes_ativos;


WITH RECURSIVE etapas_escalonamento AS (
	SELECT
		a.id AS cod_alerta,
		a.data_hora AS inicio_alerta,
		'OPERADOR'::VARCHAR(8) AS nivel,
		1 AS ordem_etapa,
		0 AS percentual_vida_util,
		a.nivel_atual
	FROM tb_alerta a

	UNION ALL

	SELECT
		etapas.cod_alerta,
		etapas.inicio_alerta,
		CASE etapas.nivel
			WHEN 'OPERADOR' THEN 'GESTOR'
			WHEN 'GESTOR' THEN 'ADMIN'
		END::VARCHAR(8) AS nivel,
		etapas.ordem_etapa + 1,
		CASE etapas.nivel
			WHEN 'OPERADOR' THEN 40
			WHEN 'GESTOR' THEN 70
		END AS percentual_vida_util,
		etapas.nivel_atual
	FROM etapas_escalonamento etapas
	WHERE etapas.nivel != etapas.nivel_atual
	  AND etapas.nivel IN ('OPERADOR', 'GESTOR')
)
SELECT
	cod_alerta,
	inicio_alerta,
	nivel,
	ordem_etapa,
	percentual_vida_util
FROM etapas_escalonamento
ORDER BY cod_alerta, ordem_etapa;
