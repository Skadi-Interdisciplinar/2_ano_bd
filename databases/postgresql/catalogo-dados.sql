-- ====================================================================
-- CRIAÇÃO IDEMPOTENTE E COMPLEMENTAÇÃO DO CATÁLOGO
-- Tabela centralizadora do Catálogo de Dados corporativo.
-- Armazena o inventário de metadados, regras de negócio e mapeamento de segurança.
-- Serve para auditoria, controle de LGPD e documentação técnica unificada.
-- ====================================================================
CREATE TABLE IF NOT EXISTS tb_catalogo_dados (
	id SERIAL,
	nome_tabela VARCHAR(100) NOT NULL,
	nome_coluna VARCHAR(100) NOT NULL,
	tipo_dado VARCHAR(50) NOT NULL,
	obrigatorio BOOLEAN NOT NULL DEFAULT FALSE,
	chave VARCHAR(2),
	descricao TEXT NOT NULL,
	regra_negocio TEXT,
	nivel_acesso_leitura VARCHAR(8) NOT NULL DEFAULT 'OPERADOR',
	dado_sensivel BOOLEAN NOT NULL DEFAULT FALSE,

	CONSTRAINT pk_catalogo_dados PRIMARY KEY (id),
	CONSTRAINT uq_catalogo_tabela_coluna UNIQUE (nome_tabela, nome_coluna),
	CONSTRAINT ck_catalogo_chave CHECK (chave IN ('PK', 'FK','NK')),
	CONSTRAINT ck_catalogo_nivel_acesso CHECK (nivel_acesso_leitura IN ('OPERADOR', 'GESTOR', 'ADMIN'))
);


-- ====================================================================
-- CARGA DE DADOS DO CATÁLOGO
-- ====================================================================
INSERT INTO tb_catalogo_dados (nome_tabela, nome_coluna, tipo_dado, obrigatorio, chave, descricao, regra_negocio, nivel_acesso_leitura, dado_sensivel) VALUES

-- ==============================================
-- tb_estado
-- ==============================================
('tb_estado', 'estado', 'CHAR(2)', TRUE, 'NK', 'Sigla da unidade federativa', 'Única no sistema; armazenada no padrão de duas letras', 'OPERADOR', FALSE),

-- ==============================================
-- tb_cd
-- ==============================================
('tb_cd', 'id', 'SERIAL', TRUE, 'PK', 'Identificador único do centro de distribuição', NULL, 'OPERADOR', FALSE),
('tb_cd', 'cnpj', 'VARCHAR(14)', TRUE, 'NK', 'CNPJ do centro de distribuição', 'Único no sistema, sem formatação (apenas dígitos)', 'GESTOR', FALSE),

-- ==============================================
-- tb_usuario
-- ==============================================
('tb_usuario', 'id', 'SERIAL', TRUE, 'PK', 'Identificador único do funcionário', NULL, 'OPERADOR', FALSE),
('tb_usuario', 'username', 'VARCHAR(50)', TRUE, 'NK', 'Nome de usuário para autenticação', 'Único no sistema; usado no login da aplicação', 'ADMIN', TRUE),
('tb_usuario', 'cpf', 'VARCHAR(11)', FALSE, 'NK', 'CPF do funcionário', 'Único quando informado; obrigatório para ADMIN, GESTOR e OPERADOR; deve ser NULL para SUPER_ADMIN', 'ADMIN', TRUE),
('tb_usuario', 'email', 'VARCHAR(255)', TRUE, 'NK', 'E-mail do funcionário', 'Único no sistema; usado para login e notificações', 'ADMIN', TRUE),
('tb_usuario', 'senha', 'VARCHAR(255)', TRUE, NULL, 'Hash da senha de acesso', 'Nunca armazenada em texto plano; nunca exposta em relatórios ou exports', 'ADMIN', TRUE),
('tb_usuario', 'nivel_acesso', 'VARCHAR(11)', TRUE, NULL, 'Cargo do funcionário no sistema', 'Níveis: OPERADOR, GESTOR, ADMIN e SUPER_ADMIN; acessos técnicos ao banco são controlados por roles PostgreSQL', 'GESTOR', FALSE),
('tb_usuario', 'cod_cd', 'INTEGER', FALSE, 'FK', 'Centro de distribuição direto do funcionário', 'Obrigatório para GESTOR e OPERADOR; deve ser NULL para ADMIN e SUPER_ADMIN. CDs do ADMIN são mantidos em tb_admin_cd', 'OPERADOR', FALSE),
('tb_usuario', 'cod_gestor', 'INTEGER', FALSE, 'FK', 'Gestor responsável pelo funcionário', 'Obrigatório para OPERADOR; deve ser NULL nos demais perfis. Referencia um GESTOR do mesmo CD', 'GESTOR', FALSE),

-- ==============================================
-- tb_admin_cd
-- ==============================================
('tb_admin_cd', 'cod_admin', 'INTEGER', TRUE, 'PK', 'Administrador associado ao CD', 'Deve referenciar um usuário ADMIN; compõe a chave primária com cod_cd', 'ADMIN', FALSE),
('tb_admin_cd', 'cod_cd', 'INTEGER', TRUE, 'PK', 'Centro de distribuição administrado', 'Um ADMIN pode ser associado a vários CDs; cada par admin/CD é único', 'ADMIN', FALSE),

-- ==============================================
-- tb_categoria
-- ==============================================
('tb_categoria', 'nome', 'VARCHAR(150)', TRUE, 'NK', 'Categoria de armazenamento', 'Única no sistema; concentra os parâmetros comuns aos lotes', 'OPERADOR', FALSE),
('tb_categoria', 'temperatura_min', 'DECIMAL(5,2)', TRUE, NULL, 'Limite mínimo de temperatura da categoria', 'Deve ser maior ou igual ao limite mínimo da câmara para que o lote possa ser armazenado nela', 'OPERADOR', FALSE),
('tb_categoria', 'temperatura_max', 'DECIMAL(5,2)', TRUE, NULL, 'Limite máximo de temperatura da categoria', 'Deve ser menor ou igual ao limite máximo da câmara para que o lote possa ser armazenado nela', 'OPERADOR', FALSE),
('tb_categoria', 'vida_util_horas', 'INTERVAL HOUR TO MINUTE', TRUE, NULL, 'Vida útil da categoria em horas e minutos', 'Valor positivo limitado a menos de 1000 horas (até 999:59); base direta do escalonamento do alerta', 'OPERADOR', FALSE),

-- ==============================================
-- tb_lote
-- ==============================================
('tb_lote', 'codigo_lote', 'VARCHAR(50)', TRUE, 'NK', 'Identificador operacional do lote', 'Único no sistema', 'OPERADOR', FALSE),
('tb_lote', 'cod_categoria', 'INTEGER', TRUE, 'FK', 'Categoria do lote', 'Cada lote pertence a exatamente uma categoria', 'OPERADOR', FALSE),
('tb_lote', 'data_fabricacao', 'DATE', TRUE, NULL, 'Data de fabricação do lote', 'Usada para rastreabilidade', 'OPERADOR', FALSE),
('tb_lote', 'data_validade', 'DATE', TRUE, NULL, 'Data de validade do lote', 'Deve ser igual ou posterior à fabricação', 'OPERADOR', FALSE),

-- ==============================================
-- tb_lote_camara_frigorifica
-- ==============================================
('tb_lote_camara_frigorifica', 'cod_lote', 'INTEGER', TRUE, 'FK', 'Lote movimentado', 'Um lote pode possuir registros de movimentação em câmaras ao longo do tempo', 'OPERADOR', FALSE),
('tb_lote_camara_frigorifica', 'cod_camara_frigorifica', 'INTEGER', TRUE, 'FK', 'Câmara frigorífica do lote', 'Apenas uma localização atual pode ficar aberta por lote', 'OPERADOR', FALSE),
('tb_lote_camara_frigorifica', 'data_entrada', 'TIMESTAMP', TRUE, NULL, 'Entrada do lote na câmara frigorífica', 'Início do período de armazenamento', 'OPERADOR', FALSE),
('tb_lote_camara_frigorifica', 'data_saida', 'TIMESTAMP', FALSE, NULL, 'Saída do lote da câmara frigorífica', 'NULL indica vínculo ainda aberto; a constraint exige saída posterior à entrada quando informada', 'OPERADOR', FALSE),

-- ==============================================
-- tb_camara_frigorifica
-- ==============================================
('tb_camara_frigorifica', 'cod_termometro', 'INTEGER', TRUE, 'FK', 'Termômetro instalado na câmara frigorífica', 'Cada câmara exige um termômetro; UNIQUE impede que ele esteja em mais de uma câmara. Um termômetro pode ainda não estar associado', 'OPERADOR', FALSE),

-- ==============================================
-- tb_alerta
-- ==============================================
('tb_alerta', 'nivel_atual', 'VARCHAR(8)', TRUE, NULL, 'Cargo responsável pelo alerta no momento', 'Nasce como operador; muda automaticamente por escalonamento (trigger monitora esse campo)', 'OPERADOR', FALSE),
('tb_alerta', 'cod_camara_frigorifica', 'INTEGER', TRUE, 'FK', 'Câmara frigorífica que originou o alerta', 'Todo alerta pertence à câmara que originou a ocorrência', 'OPERADOR', FALSE),
('tb_alerta', 'vida_util_referencia_horas', 'INTERVAL HOUR TO MINUTE', FALSE, NULL, 'Menor vida útil entre os lotes ativos no momento do alerta', 'Quando informada, deve ser positiva e menor que 1000 horas; base dos prazos fixos de escalonamento', 'GESTOR', FALSE),
('tb_alerta', 'status', 'VARCHAR(100)', TRUE, NULL, 'Fase do atendimento do alerta', 'Não confundir com nivel_atual: status é sobre o atendimento (ATIVO/RECONHECIDO/RESOLVIDO), nivel_atual é sobre o cargo responsável', 'OPERADOR', FALSE),
('tb_alerta', 'nivel_gravidade', 'VARCHAR(100)', TRUE, NULL, 'Gravidade do alerta', 'Calculada via fn_calcular_gravidade_alerta: BAIXO, ATENCAO ou CRITICO', 'OPERADOR', FALSE),
('tb_alerta', 'data_hora', 'TIMESTAMP', TRUE, NULL, 'Momento de criação do alerta', 'Usado como referência para o escalonamento', 'OPERADOR', FALSE),
('tb_alerta', 'tipo', 'VARCHAR(100)', TRUE, NULL, 'Tipo da ocorrência', 'Atualmente limitado a TEMPERATURA_FORA_PADRAO', 'OPERADOR', FALSE),

-- ==============================================
-- tb_notificacao_alerta
-- ==============================================
('tb_notificacao_alerta', 'cod_alerta', 'INTEGER', TRUE, 'FK', 'Alerta notificado', 'Relaciona a notificação ao alerta correspondente', 'OPERADOR', FALSE),
('tb_notificacao_alerta', 'cod_usuario', 'INTEGER', TRUE, 'FK', 'Usuário notificado', 'Usuário do mesmo CD e nível de acesso do escalonamento', 'OPERADOR', FALSE),
('tb_notificacao_alerta', 'data_hora_envio', 'TIMESTAMP', TRUE, NULL, 'Momento do registro da notificação', 'Usado para histórico de envio das notificações push', 'OPERADOR', FALSE),
('tb_notificacao_alerta', 'data_hora_leitura', 'TIMESTAMP', FALSE, NULL, 'Momento em que o usuário leu a notificação', 'NULL enquanto a notificação não tiver sido lida; permite medir leitura antes do reconhecimento do alerta', 'OPERADOR', FALSE),

-- ==============================================
-- tb_leitura_temperatura
-- ==============================================
('tb_leitura_temperatura', 'cod_termometro', 'INTEGER', TRUE, 'FK', 'Termômetro de origem da leitura', 'A câmara é identificada pelo termômetro associado', 'OPERADOR', FALSE),
('tb_leitura_temperatura', 'cod_alerta', 'INTEGER', FALSE, 'FK', 'Alerta gerado pela leitura', 'Preenchido quando a leitura está fora da faixa da câmara', 'OPERADOR', FALSE),
('tb_leitura_temperatura', 'temperatura', 'DECIMAL(5,2)', TRUE, NULL, 'Temperatura medida', 'Comparada com a faixa da câmara; os lotes armazenados nela possuem categorias compatíveis com essa faixa', 'OPERADOR', FALSE),
('tb_leitura_temperatura', 'data_hora', 'TIMESTAMP', TRUE, NULL, 'Momento da medição', 'Preservado no histórico do PostgreSQL após a fila Redis', 'OPERADOR', FALSE),
('tb_leitura_temperatura', 'id_evento_redis', 'VARCHAR(100)', FALSE, 'NK', 'Identificador da leitura no Redis', 'Evita duplicidade quando o consumidor reprocessa uma mensagem', 'ADMIN', FALSE),

-- ==============================================
-- tb_atendimento
-- ==============================================
('tb_atendimento', 'cod_usuario', 'INTEGER', FALSE, 'FK', 'Funcionário responsável pelo atendimento', 'Aceita NULL: atendimento nasce PENDENTE (via trigger), sem usuário atribuído até alguém reconhecer o alerta', 'OPERADOR', FALSE),
('tb_atendimento', 'status', 'VARCHAR(50)', TRUE, NULL, 'Situação do atendimento', 'PENDENTE -> EM_ANDAMENTO -> RESOLVIDO; transições controladas por sp_reconhecer_alerta e trigger de justificativa', 'OPERADOR', FALSE),
('tb_atendimento', 'data_hora_reconhecimento', 'TIMESTAMP', FALSE, NULL, 'Momento em que alguém assumiu o alerta', 'Diferente de data_hora_resolucao: reconhecimento é "estou ciente", resolução é "problema resolvido de fato"', 'OPERADOR', FALSE),
('tb_atendimento', 'data_hora_resolucao', 'TIMESTAMP', FALSE, NULL, 'Momento em que o atendimento foi finalizado', 'Registra conclusão do atendimento; isoladamente não comprova duração de exposição térmica de um lote', 'OPERADOR', FALSE),

-- ==============================================
-- tb_justificativa
-- ==============================================
('tb_justificativa', 'cod_atendimento', 'INTEGER', TRUE, 'FK', 'Atendimento ao qual a justificativa se refere', 'Registra a justificativa do atendimento; a normalização também pode resolver alerta e atendimento automaticamente ao inserir uma leitura normal mais recente', 'OPERADOR', FALSE),

-- ==============================================
-- tb_relatorio
-- ==============================================
('tb_relatorio', 'cod_cd', 'INTEGER', TRUE, 'FK', 'Centro de distribuição ao qual o relatório pertence', 'Permite escopo por CD, inclusive quando o ADMIN autor administra vários CDs', 'ADMIN', FALSE),
('tb_relatorio', 'hash_conteudo', 'VARCHAR(64)', TRUE, NULL, 'Hash SHA-256 do conteúdo do relatório', 'Garante integridade: qualquer alteração no conteúdo altera o hash, evidenciando adulteração', 'ADMIN', TRUE),
('tb_relatorio', 'conteudo', 'TEXT', TRUE, NULL, 'Conteúdo integral do relatório', 'Armazena o relatório cujo hash SHA-256 é mantido em hash_conteudo', 'GESTOR', TRUE),
('tb_relatorio', 'status', 'VARCHAR(50)', TRUE, NULL, 'Situação do relatório', 'GERADO -> ASSINADO -> ARQUIVADO', 'GESTOR', FALSE),
('tb_relatorio', 'periodo_inicio', 'DATE', TRUE, NULL, 'Início do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: força quem gera o relatório a informar o período explicitamente', 'GESTOR', FALSE),
('tb_relatorio', 'periodo_fim', 'DATE', TRUE, NULL, 'Fim do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: evita relatório de período incorreto por esquecimento', 'GESTOR', FALSE),

-- ==============================================
-- tb_assinatura
-- ==============================================
('tb_assinatura', 'numero_serie', 'VARCHAR(64)', TRUE, NULL, 'Número de série do certificado ICP-Brasil', 'Identifica unicamente o certificado usado para dar validade jurídica ao relatório', 'ADMIN', TRUE),
('tb_assinatura', 'certificado_publico', 'TEXT', TRUE, NULL, 'Chave pública usada para verificar a assinatura digital', 'Armazenada em Base64 (DER/X.509) para verificação criptográfica da assinatura', 'ADMIN', FALSE),
('tb_assinatura', 'carimbo_tempo', 'TEXT', TRUE, NULL, 'Token de carimbo de tempo (RFC 3161)', 'Emitido por Autoridade de Carimbo do Tempo externa; garante quando a assinatura ocorreu, de forma não manipulável', 'ADMIN', TRUE),

-- ==============================================
-- tb_log_auditoria
-- ==============================================
('tb_log_auditoria', 'cod_usuario', 'INTEGER', FALSE, NULL, 'ID do usuário da aplicação associado à ação, quando informado', 'Pode ser NULL em operações sem contexto de usuário', 'ADMIN', FALSE),
('tb_log_auditoria', 'acao', 'VARCHAR(150)', TRUE, NULL, 'Operação executada sobre a entidade', 'Recebe INSERT, UPDATE ou DELETE do trigger de auditoria', 'ADMIN', FALSE),
('tb_log_auditoria', 'entidade_afetada', 'VARCHAR(50)', TRUE, NULL, 'Nome da tabela alterada', 'Identifica a entidade cujo histórico está sendo registrado', 'ADMIN', FALSE),
('tb_log_auditoria', 'entidade_id', 'INTEGER', TRUE, NULL, 'Referência numérica da entidade alterada', 'Em tb_admin_cd contém cod_admin; o par cod_admin/cod_cd fica nos snapshots, pois a chave é composta', 'ADMIN', FALSE),
('tb_log_auditoria', 'dados_antigos', 'JSONB', FALSE, NULL, 'Estado da linha antes da alteração (OLD)', 'Preenchido apenas em UPDATE/DELETE; omite CPF, e-mail, senha, hash e conteúdo de relatório, número de série, carimbo de tempo e IP', 'ADMIN', FALSE),
('tb_log_auditoria', 'dados_novos', 'JSONB', FALSE, NULL, 'Snapshot sanitizado da linha depois da operação', 'Preenchido em INSERT/UPDATE; omite CPF, e-mail, senha, hash e conteúdo de relatório, número de série, carimbo de tempo e IP', 'ADMIN', FALSE),
('tb_log_auditoria', 'data_hora', 'TIMESTAMP', TRUE, NULL, 'Momento em que a operação foi registrada', 'Gerado pelo banco com CURRENT_TIMESTAMP', 'ADMIN', FALSE),

-- ==============================================
-- tb_log_escalonamento
-- ==============================================
('tb_log_escalonamento', 'nivel_anterior', 'VARCHAR(8)', FALSE, NULL, 'Cargo que tinha o alerta antes da escalada', 'Recebe OLD.nivel_atual quando a trigger registra mudança de nível', 'OPERADOR', FALSE),

-- ==============================================
-- tb_log_acesso
-- ==============================================
('tb_log_acesso', 'ip_origem', 'INET', TRUE, NULL, 'Endereço IP de onde partiu a tentativa de acesso', 'Identificador de origem potencialmente pessoal; não usar como identidade do usuário', 'ADMIN', TRUE)
ON CONFLICT (nome_tabela, nome_coluna) DO UPDATE
SET descricao = EXCLUDED.descricao, regra_negocio = EXCLUDED.regra_negocio;

-- As classificações existentes são preservadas. Novas colunas recebem os
-- níveis aprovados. Este inventário NÃO concede permissões SQL/aplicativas.
WITH colunas AS (
    SELECT c.relname AS tabela, a.attname AS coluna,
           pg_catalog.format_type(a.atttypid, a.atttypmod) AS tipo,
           a.attnotnull AS obrigatorio,
           CASE
             WHEN EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid=c.oid
                          AND k.contype='p' AND a.attnum=ANY(k.conkey)) THEN 'PK'
             WHEN EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid=c.oid
                          AND k.contype='f' AND a.attnum=ANY(k.conkey)) THEN 'FK'
             WHEN EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid=c.oid
                          AND k.contype='u' AND a.attnum=ANY(k.conkey)) THEN 'NK'
           END AS chave,
           (SELECT string_agg(k.conname || ': ' || pg_get_constraintdef(k.oid), '; ' ORDER BY k.conname)
            FROM pg_constraint k WHERE k.conrelid=c.oid AND a.attnum=ANY(k.conkey)) AS constraints_coluna,
           pg_get_expr(d.adbin, d.adrelid) AS valor_padrao
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum>0 AND NOT a.attisdropped
    LEFT JOIN pg_attrdef d ON d.adrelid=c.oid AND d.adnum=a.attnum
    WHERE n.nspname='public' AND c.relkind IN ('r','p') AND c.relname LIKE 'tb\_%' ESCAPE '\'
), descricoes(coluna, descricao) AS (
    VALUES
      ('id', 'Identificador da linha; consultar as constraints para o escopo da chave'),
      ('nome', 'Nome de apresentação da entidade cadastrada'),
      ('modelo', 'Identificação do modelo do termômetro'),
      ('localizacao', 'Localização cadastrada da câmara frigorífica'),
      ('temperatura_min', 'Limite inferior de temperatura cadastrado, em graus Celsius'),
      ('temperatura_max', 'Limite superior de temperatura cadastrado, em graus Celsius'),
      ('cep', 'Código postal do endereço do centro de distribuição'),
      ('rua', 'Logradouro do endereço do centro de distribuição'),
      ('numero', 'Número do endereço do centro de distribuição'),
      ('complemento', 'Complemento do endereço, quando informado'),
      ('bairro', 'Bairro do centro de distribuição'),
      ('cidade', 'Cidade do centro de distribuição'),
      ('cod_estado', 'Referência à unidade federativa cadastrada'),
      ('cod_cd', 'Referência ao centro de distribuição; observar as regras da tabela'),
      ('cod_alerta', 'Referência ao alerta associado ao registro'),
      ('status', 'Estado atual do registro no fluxo da entidade'),
      ('categoria', 'Categoria escolhida para a solicitação de suporte'),
      ('descricao', 'Texto livre de descrição fornecido no fluxo da entidade'),
      ('resposta', 'Texto de resposta registrado no atendimento de suporte'),
      ('cod_usuario_solicitante', 'Usuário que abriu a solicitação de suporte'),
      ('cod_usuario_responsavel', 'SUPER_ADMIN responsável pelo suporte, quando atribuído'),
      ('data_hora_abertura', 'Data e hora de abertura do chamado'),
      ('data_hora_encerramento', 'Data e hora de encerramento do chamado, quando concluído'),
      ('nome_carga', 'Identificador da carga utilizado para recuperar seu checkpoint'),
      ('cod_usuario_gerador', 'Usuário identificado como autor da geração do relatório'),
      ('data_hora_geracao', 'Data e hora de geração do relatório'),
      ('cod_usuario', 'Usuário da aplicação associado ao evento, quando identificado'),
      ('usuario_bd', 'CURRENT_USER da conexão que executou a operação; NULL em histórico sem autoria recuperável'),
      ('data_hora', 'Data e hora registrada para o evento'),
      ('motivo', 'Motivo registrado no fluxo da entidade'),
      ('tentativa_sucesso', 'Indica se a tentativa de autenticação foi bem-sucedida'),
      ('motivo_falha', 'Motivo da falha de acesso, quando houver'),
      ('user_agent', 'Identificação do cliente HTTP que originou a tentativa de acesso'),
      ('nivel_novo', 'Nível responsável após a mudança de escalonamento'),
      ('cod_relatorio', 'Relatório ao qual a assinatura se refere'),
      ('certificado_titular', 'Titular informado no certificado da assinatura'),
      ('autoridade_certificadora', 'Autoridade indicada no certificado da assinatura'),
      ('algoritmo_assinatura', 'Algoritmo informado para verificar a assinatura'),
      ('assinatura', 'Assinatura digital armazenada para o relatório'),
      ('data_assinatura', 'Data registrada para a assinatura do relatório'),
      ('nome_tabela', 'Nome da tabela descrita pelo metadado'),
      ('nome_coluna', 'Nome da coluna descrita pelo metadado'),
      ('tipo_dado', 'Tipo efetivo da coluna no PostgreSQL'),
      ('obrigatorio', 'Indica NOT NULL físico; regras condicionais ficam em regra_negocio'),
      ('chave', 'Classificação estrutural: PK precede FK, que precede chave única NK'),
      ('regra_negocio', 'Descrição documental das regras e das constraints da coluna'),
      ('nivel_acesso_leitura', 'Classificação documental aprovada; não concede acesso ao banco'),
      ('dado_sensivel', 'Sinalização conservadora de conteúdo potencialmente sensível')
)
INSERT INTO tb_catalogo_dados (
    nome_tabela, nome_coluna, tipo_dado, obrigatorio, chave,
    descricao, regra_negocio, nivel_acesso_leitura, dado_sensivel
)
SELECT c.tabela, c.coluna, c.tipo, c.obrigatorio, c.chave,
       COALESCE(d.descricao, 'Campo ' || c.coluna || ' de ' || c.tabela || '; consultar as constraints registradas'),
       NULL::TEXT,
       CASE
         WHEN c.tabela IN ('tb_usuario','tb_solicitacao_suporte','tb_controle_rpa',
                           'tb_assinatura','tb_log_acesso','tb_log_auditoria','tb_catalogo_dados') THEN 'ADMIN'
         WHEN c.tabela IN ('tb_endereco','tb_relatorio') THEN 'GESTOR'
         WHEN c.tabela='tb_justificativa' AND c.coluna IN ('motivo','descricao') THEN 'GESTOR'
         ELSE 'OPERADOR'
       END,
       (c.tabela='tb_usuario' AND c.coluna='nome')
       OR c.coluna IN ('descricao','resposta','motivo','assinatura','certificado_titular','user_agent','usuario_bd')
       OR (c.tabela IN ('tb_solicitacao_suporte','tb_log_acesso','tb_relatorio') AND c.coluna LIKE 'cod\_usuario%' ESCAPE '\')
FROM colunas c LEFT JOIN descricoes d ON d.coluna=c.coluna
ON CONFLICT (nome_tabela, nome_coluna) DO NOTHING;

-- Atualiza características físicas e o bloco gerado de constraints/defaults.
-- Preserva o texto humano e classificações; substitui o bloco em reexecuções.
UPDATE tb_catalogo_dados m
SET tipo_dado=pg_catalog.format_type(a.atttypid,a.atttypmod),
    obrigatorio=a.attnotnull,
    regra_negocio=split_part(COALESCE(m.regra_negocio,''), E'\n[SCHEMA]', 1)
      || E'\n[SCHEMA] ' || concat_ws('; ',
        (SELECT string_agg(k.conname || ': ' || pg_get_constraintdef(k.oid), '; ' ORDER BY k.conname)
         FROM pg_constraint k WHERE k.conrelid=c.oid AND a.attnum=ANY(k.conkey)),
        (SELECT 'DEFAULT: ' || pg_get_expr(d.adbin,d.adrelid)
         FROM pg_attrdef d WHERE d.adrelid=c.oid AND d.adnum=a.attnum)
      ),
    chave=CASE
      WHEN EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid=c.oid AND k.contype='p' AND a.attnum=ANY(k.conkey)) THEN 'PK'
      WHEN EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid=c.oid AND k.contype='f' AND a.attnum=ANY(k.conkey)) THEN 'FK'
      WHEN EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid=c.oid AND k.contype='u' AND a.attnum=ANY(k.conkey)) THEN 'NK'
    END
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum>0 AND NOT a.attisdropped
WHERE n.nspname='public' AND c.relkind IN ('r','p')
  AND m.nome_tabela=c.relname AND m.nome_coluna=a.attname;

DELETE FROM tb_catalogo_dados m
WHERE m.nome_tabela LIKE 'tb\_%' ESCAPE '\' AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns c WHERE c.table_schema='public'
      AND c.table_name=m.nome_tabela AND c.column_name=m.nome_coluna
);
