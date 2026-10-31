-- Aplicação isolada em banco existente. Remove os valores de modelo da câmara.
-- A view é recriada; revisar/reaplicar suas concessões de leitura depois.
-- Sem CASCADE: dependências externas causam falha e rollback da transação.
BEGIN;
DROP VIEW IF EXISTS public.vw_dim_camara;
ALTER TABLE public.tb_camara_frigorifica DROP COLUMN IF EXISTS modelo;
CREATE VIEW public.vw_dim_camara AS
SELECT c.id AS camara_id, c.localizacao,
       c.cod_cd AS cd_id, cd.nome AS cd_nome,
       c.cod_termometro AS termometro_id
FROM public.tb_camara_frigorifica c
JOIN public.tb_cd cd ON cd.id = c.cod_cd;
COMMIT;
