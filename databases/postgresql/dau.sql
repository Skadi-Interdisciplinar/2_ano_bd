-- ====================================================================
-- MONITORAMENTO DAU (DAILY ACTIVE USERS)
-- ====================================================================

DROP VIEW IF EXISTS vw_dau_diario;

-- Usuários únicos que realizaram pelo menos um acesso bem-sucedido por dia.
CREATE VIEW vw_dau_diario AS
SELECT
    data_hora::DATE AS data_acesso,
    COUNT(DISTINCT cod_usuario) AS usuarios_ativos
FROM tb_log_acesso
WHERE tentativa_sucesso = TRUE
  AND cod_usuario IS NOT NULL
GROUP BY data_hora::DATE
ORDER BY data_acesso;
