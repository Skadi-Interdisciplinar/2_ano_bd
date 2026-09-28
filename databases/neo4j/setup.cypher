// Restrições de identidade dos nós principais.
CREATE CONSTRAINT cd_id IF NOT EXISTS
FOR (n:CD) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT camara_id IF NOT EXISTS
FOR (n:CamaraFrigorifica) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT termometro_id IF NOT EXISTS
FOR (n:Termometro) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT categoria_id IF NOT EXISTS
FOR (n:Categoria) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT lote_id IF NOT EXISTS
FOR (n:Lote) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT usuario_id IF NOT EXISTS
FOR (n:Usuario) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT alerta_id IF NOT EXISTS
FOR (n:Alerta) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT atendimento_id IF NOT EXISTS
FOR (n:Atendimento) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT justificativa_id IF NOT EXISTS
FOR (n:Justificativa) REQUIRE n.id IS UNIQUE;

// Índices para filtros frequentes das perguntas de negócio.
CREATE INDEX alerta_status IF NOT EXISTS
FOR (n:Alerta) ON (n.status);

CREATE INDEX lote_status IF NOT EXISTS
FOR (n:Lote) ON (n.status);

CREATE INDEX categoria_nome IF NOT EXISTS
FOR (n:Categoria) ON (n.nome);
