BEGIN;

CREATE OR REPLACE VIEW public.vw_dim_data AS
WITH datas AS (
    SELECT data_hora::date AS data FROM public.tb_alerta
    UNION
    SELECT data_hora_abertura::date FROM public.tb_solicitacao_suporte
    UNION
    SELECT data_hora_encerramento::date FROM public.tb_solicitacao_suporte
)
SELECT data AS data_id, EXTRACT(YEAR FROM data)::integer AS ano,
       EXTRACT(MONTH FROM data)::integer AS mes,
       EXTRACT(DAY FROM data)::integer AS dia,
       EXTRACT(ISODOW FROM data)::integer AS dia_semana,
       EXTRACT(QUARTER FROM data)::integer AS trimestre
FROM datas WHERE data IS NOT NULL;

CREATE OR REPLACE VIEW public.vw_dim_camara AS
SELECT c.id AS camara_id, c.localizacao,
       c.cod_cd AS cd_id, cd.nome AS cd_nome,
       c.cod_termometro AS termometro_id
FROM public.tb_camara_frigorifica c
JOIN public.tb_cd cd ON cd.id = c.cod_cd;

-- Somente atributos necessários à análise; sem dados de autenticação.
CREATE OR REPLACE VIEW public.vw_dim_usuario AS
SELECT id AS usuario_id, nivel_acesso, cod_cd AS cd_id
FROM public.tb_usuario;

CREATE OR REPLACE VIEW public.vw_dim_categoria_suporte AS
SELECT DISTINCT categoria AS categoria_id
FROM public.tb_solicitacao_suporte;

CREATE OR REPLACE VIEW public.vw_dim_status_suporte AS
SELECT DISTINCT status AS status_id
FROM public.tb_solicitacao_suporte;

CREATE OR REPLACE VIEW public.vw_dim_gravidade_alerta AS
SELECT DISTINCT nivel_gravidade AS gravidade_id FROM public.tb_alerta;

CREATE OR REPLACE VIEW public.vw_dim_status_alerta AS
SELECT DISTINCT status AS status_id FROM public.tb_alerta;

CREATE OR REPLACE VIEW public.vw_fato_chamado AS
SELECT id AS chamado_id,
       cod_usuario_solicitante AS solicitante_id,
       cod_usuario_responsavel AS responsavel_id,
       categoria AS categoria_id, status AS status_id,
       data_hora_abertura::date AS data_abertura_id,
       data_hora_encerramento::date AS data_encerramento_id,
       data_hora_abertura, data_hora_encerramento,
       1::integer AS quantidade,
       CASE WHEN status IN ('REGISTRADO', 'EM_ATENDIMENTO') THEN 1 ELSE 0 END AS quantidade_aberta,
       CASE WHEN status = 'ATENDIDO' THEN 1 ELSE 0 END AS quantidade_finalizada,
       CASE WHEN status = 'ATENDIDO' AND data_hora_encerramento >= data_hora_abertura
            THEN EXTRACT(EPOCH FROM (data_hora_encerramento - data_hora_abertura)) / 3600.0
       END AS tempo_resolucao_horas
FROM public.tb_solicitacao_suporte;

CREATE OR REPLACE VIEW public.vw_fato_alerta AS
SELECT id AS alerta_id, cod_camara_frigorifica AS camara_id,
       data_hora::date AS data_id, data_hora,
       nivel_gravidade AS gravidade_id, status AS status_id,
       nivel_atual, tipo, 1::integer AS quantidade,
       CASE WHEN status IN ('ATIVO', 'RECONHECIDO') THEN 1 ELSE 0 END AS quantidade_aberta,
       CASE WHEN status = 'RESOLVIDO' THEN 1 ELSE 0 END AS quantidade_resolvida
FROM public.tb_alerta;

COMMENT ON VIEW public.vw_fato_chamado IS
    'Grão: um chamado. Somar quantidade; média de tempo_resolucao_horas somente para ATENDIDO com encerramento válido.';
COMMENT ON VIEW public.vw_fato_alerta IS
    'Grão: um alerta, no estado atual. Não representa histórico de mudanças de gravidade ou status.';
COMMENT ON VIEW public.vw_dim_usuario IS
    'Uma linha por usuário; usada nos papéis solicitante e responsável. Sem CPF, senha, email ou nome.';

COMMIT;
