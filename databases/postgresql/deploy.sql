-- ====================================================================
-- DEPLOY: schemas.sql
-- ====================================================================

DROP TABLE IF EXISTS tb_assinatura CASCADE;
DROP TABLE IF EXISTS tb_relatorio CASCADE;
DROP TABLE IF EXISTS tb_justificativa CASCADE;
DROP TABLE IF EXISTS tb_atendimento CASCADE;
DROP TABLE IF EXISTS tb_leitura_temperatura CASCADE;
DROP TABLE IF EXISTS tb_notificacao_alerta CASCADE;
DROP TABLE IF EXISTS tb_alerta CASCADE;
DROP TABLE IF EXISTS tb_lote_camara_frigorifica CASCADE;
DROP TABLE IF EXISTS tb_lote CASCADE;
DROP TABLE IF EXISTS tb_categoria CASCADE;
DROP TABLE IF EXISTS tb_camara_frigorifica CASCADE;
DROP TABLE IF EXISTS tb_termometro CASCADE;
DROP TABLE IF EXISTS tb_usuario CASCADE;
DROP TABLE IF EXISTS tb_endereco CASCADE;
DROP TABLE IF EXISTS tb_cd CASCADE;
DROP TABLE IF EXISTS tb_estado CASCADE;


ALTER DATABASE skadi SET timezone TO 'America/Sao_Paulo';


CREATE TABLE tb_estado (
	id SERIAL,
	estado CHAR(2) NOT NULL,

	CONSTRAINT pk_estado PRIMARY KEY (id),
	CONSTRAINT uq_estado_sigla UNIQUE (estado)
);

CREATE TABLE tb_cd (
	id SERIAL,
	nome VARCHAR(150) NOT NULL,
	cnpj VARCHAR(14) NOT NULL,

	CONSTRAINT pk_cd PRIMARY KEY (id),
	CONSTRAINT uq_cd_cnpj UNIQUE (cnpj)
);

CREATE TABLE tb_endereco (
	id SERIAL,
	cep VARCHAR(8) NOT NULL,
	rua VARCHAR(150) NOT NULL,
	numero INTEGER NOT NULL,
	cidade VARCHAR(60) NOT NULL,
	bairro VARCHAR(70) NOT NULL,
	complemento VARCHAR(50),
	cod_estado INTEGER NOT NULL,
	cod_cd INTEGER NOT NULL,

	CONSTRAINT pk_endereco PRIMARY KEY (id),
	CONSTRAINT uq_endereco_cep UNIQUE (cep),
	CONSTRAINT fk_endereco_estado FOREIGN KEY (cod_estado) REFERENCES tb_estado(id),
	CONSTRAINT fk_endereco_cd FOREIGN KEY (cod_cd) REFERENCES tb_cd(id) ON DELETE CASCADE,
	CONSTRAINT ck_endereco_numero CHECK (numero >= 0)
);

CREATE TABLE tb_usuario (
	id SERIAL,
	nome VARCHAR(150) NOT NULL,
	username VARCHAR(50) NOT NULL,
	cpf VARCHAR(11) NOT NULL,
	email VARCHAR(255) NOT NULL,
	senha VARCHAR(255) NOT NULL,
	nivel_acesso VARCHAR(8) NOT NULL DEFAULT 'operador',
	cod_cd INTEGER,
	cod_gestor INTEGER,

	CONSTRAINT pk_usuario PRIMARY KEY (id),
	CONSTRAINT uq_usuario_username UNIQUE (username),
	CONSTRAINT uq_usuario_cpf UNIQUE (cpf),
	CONSTRAINT uq_usuario_email UNIQUE (email),
	CONSTRAINT fk_usuario_cd FOREIGN KEY (cod_cd) REFERENCES tb_cd(id),
	CONSTRAINT uq_usuario_id_cd UNIQUE (id, cod_cd),
	CONSTRAINT fk_usuario_gestor_mesmo_cd FOREIGN KEY (cod_gestor, cod_cd)
		REFERENCES tb_usuario(id, cod_cd),
	CONSTRAINT ck_usuario_nao_eh_proprio_gestor CHECK (cod_gestor IS NULL OR cod_gestor <> id),
	CONSTRAINT ck_usuario_nivel_acesso CHECK (nivel_acesso IN ('operador', 'gestor', 'admin', 'sistema'))
);

CREATE TABLE tb_termometro (
	id SERIAL,
	modelo VARCHAR(150) NOT NULL,

	CONSTRAINT pk_termometro PRIMARY KEY (id)
);

CREATE TABLE tb_categoria (
	id SERIAL,
	nome VARCHAR(150) NOT NULL,
	temperatura_ideal DECIMAL(5,2) NOT NULL,
	vida_util_horas DECIMAL(7,2) NOT NULL,

	CONSTRAINT pk_categoria PRIMARY KEY (id),
	CONSTRAINT uq_categoria_nome UNIQUE (nome),
	CONSTRAINT ck_categoria_vida_util CHECK (vida_util_horas > 0)
);

CREATE TABLE tb_camara_frigorifica (
	id SERIAL,
	modelo VARCHAR(150) NOT NULL,
	localizacao VARCHAR(100) NOT NULL,
	temperatura_min DECIMAL(5,2) NOT NULL,
	temperatura_max DECIMAL(5,2) NOT NULL,
	cod_cd INTEGER NOT NULL,
	cod_termometro INTEGER NOT NULL,

	CONSTRAINT pk_camara_frigorifica PRIMARY KEY (id),
	CONSTRAINT fk_camara_frigorifica_cd FOREIGN KEY (cod_cd) REFERENCES tb_cd(id) ON DELETE RESTRICT,
	CONSTRAINT fk_camara_frigorifica_termometro FOREIGN KEY (cod_termometro) REFERENCES tb_termometro(id),
	CONSTRAINT uq_camara_frigorifica_termometro UNIQUE (cod_termometro),
	CONSTRAINT ck_camara_frigorifica_faixa_temperatura CHECK (temperatura_min < temperatura_max)
);

CREATE TABLE tb_lote (
	id SERIAL,
	codigo_lote VARCHAR(50) NOT NULL,
	cod_categoria INTEGER NOT NULL,
	data_fabricacao DATE NOT NULL,
	data_validade DATE NOT NULL,
	status VARCHAR(20) NOT NULL DEFAULT 'ativo',

	CONSTRAINT pk_lote PRIMARY KEY (id),
	CONSTRAINT uq_lote_codigo UNIQUE (codigo_lote),
	CONSTRAINT fk_lote_categoria FOREIGN KEY (cod_categoria) REFERENCES tb_categoria(id),
	CONSTRAINT ck_lote_datas CHECK (data_validade >= data_fabricacao),
	CONSTRAINT ck_lote_status CHECK (status IN ('ativo', 'bloqueado', 'expedido', 'vencido'))
);

CREATE TABLE tb_lote_camara_frigorifica (
	id SERIAL,
	cod_lote INTEGER NOT NULL,
	cod_camara_frigorifica INTEGER NOT NULL,
	data_entrada TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	data_saida TIMESTAMP,

	CONSTRAINT pk_lote_camara_frigorifica PRIMARY KEY (id),
	CONSTRAINT fk_loteref_lote FOREIGN KEY (cod_lote) REFERENCES tb_lote(id),
	CONSTRAINT fk_loteref_camara_frigorifica FOREIGN KEY (cod_camara_frigorifica) REFERENCES tb_camara_frigorifica(id),
	CONSTRAINT ck_loteref_periodo CHECK (data_saida IS NULL OR data_saida > data_entrada)
);

CREATE TABLE tb_alerta (
	id SERIAL,
	cod_camara_frigorifica INTEGER NOT NULL,
	vida_util_referencia_horas DECIMAL(7,2),
	nivel_atual VARCHAR(8) NOT NULL DEFAULT 'operador',
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	tipo VARCHAR(100) NOT NULL DEFAULT 'temperatura_fora_padrao',
	nivel_gravidade VARCHAR(100) NOT NULL,
	status VARCHAR(100) NOT NULL,

	CONSTRAINT pk_alerta PRIMARY KEY (id),
	CONSTRAINT fk_alerta_camara_frigorifica FOREIGN KEY (cod_camara_frigorifica) REFERENCES tb_camara_frigorifica(id),
	CONSTRAINT ck_alerta_nivel_atual CHECK (nivel_atual IN ('operador', 'gestor', 'admin')),
	CONSTRAINT ck_alerta_nivel_gravidade CHECK (nivel_gravidade IN ('baixa', 'atenção', 'urgente', 'crítica')),
	CONSTRAINT ck_alerta_status CHECK (status IN ('ativo', 'reconhecido', 'resolvido')),
	CONSTRAINT ck_alerta_tipo CHECK (tipo IN ('temperatura_fora_padrao'))
);

CREATE TABLE tb_notificacao_alerta (
	id SERIAL,
	cod_alerta INTEGER NOT NULL,
	cod_usuario INTEGER NOT NULL,
	data_hora_envio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_notificacao_alerta PRIMARY KEY (id),
	CONSTRAINT fk_notificacao_alerta FOREIGN KEY (cod_alerta) REFERENCES tb_alerta(id),
	CONSTRAINT fk_notificacao_usuario FOREIGN KEY (cod_usuario) REFERENCES tb_usuario(id)
);

CREATE TABLE tb_leitura_temperatura (
	id SERIAL,
	cod_termometro INTEGER NOT NULL,
	cod_alerta INTEGER,
	temperatura DECIMAL(5,2) NOT NULL,
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	id_evento_redis VARCHAR(100),

	CONSTRAINT pk_leitura_temperatura PRIMARY KEY (id),
	CONSTRAINT fk_leitura_termometro FOREIGN KEY (cod_termometro) REFERENCES tb_termometro(id),
	CONSTRAINT fk_leitura_alerta FOREIGN KEY (cod_alerta) REFERENCES tb_alerta(id),
	CONSTRAINT uq_leitura_evento_redis UNIQUE (id_evento_redis)
);

CREATE TABLE tb_atendimento (
	id SERIAL,
	cod_alerta INTEGER NOT NULL,
	cod_usuario INTEGER,
	data_hora_reconhecimento TIMESTAMP,
	data_hora_resolucao TIMESTAMP,
	status VARCHAR(50) NOT NULL,

	CONSTRAINT pk_atendimento PRIMARY KEY (id),
	CONSTRAINT fk_atendimento_alerta FOREIGN KEY (cod_alerta) REFERENCES tb_alerta(id),
	CONSTRAINT fk_atendimento_usuario FOREIGN KEY (cod_usuario) REFERENCES tb_usuario(id),
	CONSTRAINT ck_atendimento_status CHECK (status IN ('pendente', 'em_andamento', 'resolvido'))
);

CREATE TABLE tb_justificativa (
	id SERIAL,
	cod_atendimento INTEGER NOT NULL,
	motivo VARCHAR(255) NOT NULL,
	descricao TEXT NOT NULL,
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_justificativa PRIMARY KEY (id),
	CONSTRAINT fk_justificativa_atendimento FOREIGN KEY (cod_atendimento) REFERENCES tb_atendimento(id)
);

CREATE TABLE tb_relatorio (
	id SERIAL,
	cod_usuario_gerador INTEGER NOT NULL,
	data_hora_geracao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	hash_conteudo VARCHAR(64) NOT NULL,
	periodo_inicio DATE NOT NULL,
	periodo_fim DATE NOT NULL,
	status VARCHAR(50) NOT NULL,

	CONSTRAINT pk_relatorio PRIMARY KEY (id),
	CONSTRAINT fk_relatorio_usuario FOREIGN KEY (cod_usuario_gerador) REFERENCES tb_usuario(id),
	CONSTRAINT ck_relatorio_status CHECK (status IN ('gerado', 'assinado', 'arquivado'))
);

CREATE TABLE tb_assinatura (
	id SERIAL,
	cod_relatorio INTEGER NOT NULL,
	certificado_titular VARCHAR(255) NOT NULL,
	numero_serie VARCHAR(64) NOT NULL,
	autoridade_certificadora VARCHAR(255) NOT NULL,
	algoritmo_assinatura VARCHAR(50) NOT NULL,
	assinatura TEXT NOT NULL,
	data_assinatura DATE NOT NULL DEFAULT CURRENT_DATE,
	carimbo_tempo TEXT NOT NULL,

	CONSTRAINT pk_assinatura PRIMARY KEY (id),
	CONSTRAINT fk_assinatura_relatorio FOREIGN KEY (cod_relatorio) REFERENCES tb_relatorio(id)
);


-- ====================================================================
-- DEPLOY: functions.sql
-- ====================================================================

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
        RETURN 'baixa';
    ELSIF v_diferenca <= 3 THEN
        RETURN 'atenção';
    ELSIF v_diferenca <= 5 THEN
        RETURN 'urgente';
    ELSE
        RETURN 'crítica';
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


-- ====================================================================
-- DEPLOY: procedures.sql
-- ====================================================================

CREATE OR REPLACE PROCEDURE sp_reconhecer_alerta(
    p_cod_alerta INTEGER,
    p_cod_usuario INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tb_alerta
        WHERE id = p_cod_alerta
    ) THEN
        RAISE EXCEPTION 'Alerta % não encontrado.', p_cod_alerta;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_usuario
        WHERE id = p_cod_usuario
    ) THEN
        RAISE EXCEPTION 'Usuário % não encontrado.', p_cod_usuario;
    END IF;

    UPDATE tb_atendimento
    SET cod_usuario = p_cod_usuario,
        data_hora_reconhecimento = CURRENT_TIMESTAMP,
        status = 'em_andamento'
    WHERE cod_alerta = p_cod_alerta AND status = 'pendente';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Nenhum atendimento pendente encontrado para o alerta %.', p_cod_alerta;
    END IF;

    UPDATE tb_alerta
    SET status = 'reconhecido'
    WHERE id = p_cod_alerta AND status = 'ativo';
END;
$$;


CREATE OR REPLACE PROCEDURE sp_notificar_nivel_acesso(
    p_cod_alerta INTEGER,
    p_nivel VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tb_alerta
        WHERE id = p_cod_alerta
    ) THEN
        RAISE EXCEPTION 'Alerta % não encontrado.', p_cod_alerta;
    END IF;

    IF p_nivel NOT IN ('operador', 'gestor', 'admin') THEN
        RAISE EXCEPTION 'Nível de acesso inválido: %.', p_nivel;
    END IF;

    INSERT INTO tb_notificacao_alerta (cod_alerta, cod_usuario)
    SELECT a.id, u.id
    FROM tb_alerta a
    JOIN tb_camara_frigorifica c
        ON c.id = a.cod_camara_frigorifica
    JOIN tb_usuario u
        ON u.cod_cd = c.cod_cd AND u.nivel_acesso = p_nivel
    WHERE a.id = p_cod_alerta;
END;
$$;


CREATE OR REPLACE PROCEDURE sp_escalonar_alertas_pendentes()
LANGUAGE plpgsql AS $$
DECLARE
    v_alerta RECORD;
    v_nivel_novo VARCHAR(8);
BEGIN
    FOR v_alerta IN
        SELECT id, nivel_atual, data_hora
        FROM tb_alerta
        WHERE status = 'ativo' AND nivel_atual IN ('operador', 'gestor')
    LOOP
        v_nivel_novo := NULL;

        IF CURRENT_TIMESTAMP >= v_alerta.data_hora
            + fn_calcular_prazo_escalonamento(v_alerta.id, 70) * INTERVAL '1 hour' THEN
            v_nivel_novo := 'admin';
        ELSIF CURRENT_TIMESTAMP >= v_alerta.data_hora
            + fn_calcular_prazo_escalonamento(v_alerta.id, 40) * INTERVAL '1 hour'
            AND v_alerta.nivel_atual = 'operador' THEN
            v_nivel_novo := 'gestor';
        END IF;

        IF v_nivel_novo IS NOT NULL THEN
            UPDATE tb_alerta 
            SET nivel_atual = v_nivel_novo
            WHERE id = v_alerta.id;

            CALL sp_notificar_nivel_acesso(v_alerta.id, v_nivel_novo);
        END IF;
    END LOOP;
END;
$$;


-- Cadastra usuários somente por meio de um executor autorizado.
CREATE OR REPLACE PROCEDURE sp_cadastrar_usuario(
    p_nome VARCHAR(150),
    p_username VARCHAR(50),
    p_cpf VARCHAR(11),
    p_email VARCHAR(255),
    p_senha VARCHAR(255),
    p_nivel_acesso VARCHAR(8),
    p_cod_cd INTEGER,
    p_cod_gestor INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_cod_executor INTEGER;
    v_nivel_executor VARCHAR(8);
    v_cd_executor INTEGER;
    v_usuario_atual TEXT;
BEGIN
    v_usuario_atual := current_setting('app.usuario_atual', true);
    IF v_usuario_atual IS NULL OR v_usuario_atual = '' THEN
        RAISE EXCEPTION 'Usuário executor não informado.';
    END IF;

    BEGIN
        v_cod_executor := v_usuario_atual::INTEGER;
    EXCEPTION WHEN invalid_text_representation THEN
        RAISE EXCEPTION 'app.usuario_atual deve conter um ID inteiro.';
    END;

    SELECT u.nivel_acesso, u.cod_cd
    INTO v_nivel_executor, v_cd_executor
    FROM tb_usuario u
    WHERE u.id = v_cod_executor;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário executor % não encontrado.', v_cod_executor;
    END IF;

    IF p_nivel_acesso NOT IN ('operador', 'gestor', 'admin') THEN
        RAISE EXCEPTION 'Nível de acesso inválido para cadastro: %.', p_nivel_acesso;
    END IF;
    IF p_cod_cd IS NULL THEN
        RAISE EXCEPTION 'O CD do novo usuário é obrigatório.';
    END IF;

    IF v_nivel_executor = 'admin' THEN
        IF v_cd_executor IS DISTINCT FROM p_cod_cd THEN
            RAISE EXCEPTION 'O administrador só pode cadastrar usuários do próprio CD.';
        END IF;
        IF p_nivel_acesso = 'admin' THEN
            RAISE EXCEPTION 'Administradores não podem cadastrar outro administrador.';
        END IF;
    ELSIF v_nivel_executor = 'sistema' THEN
        IF p_nivel_acesso <> 'admin' THEN
            RAISE EXCEPTION 'O sistema só pode cadastrar o administrador inicial do CD.';
        END IF;
        IF EXISTS (
            SELECT 1 FROM tb_usuario u
            WHERE u.cod_cd = p_cod_cd AND u.nivel_acesso = 'admin'
        ) THEN
            RAISE EXCEPTION 'O CD % já possui um administrador.', p_cod_cd;
        END IF;
    ELSE
        RAISE EXCEPTION 'O usuário executor não possui permissão para cadastrar usuários.';
    END IF;

    IF p_nivel_acesso <> 'operador' AND p_cod_gestor IS NOT NULL THEN
        RAISE EXCEPTION 'Somente operadores podem possuir um gestor responsável.';
    END IF;

    INSERT INTO tb_usuario (
        nome, username, cpf, email, senha, nivel_acesso, cod_cd, cod_gestor
    ) VALUES (
        p_nome, p_username, p_cpf, p_email, p_senha,
        p_nivel_acesso, p_cod_cd, p_cod_gestor
    );
END;
$$;


-- ====================================================================
-- DEPLOY: triggers.sql
-- ====================================================================

DROP TRIGGER IF EXISTS trg_criar_atendimento_pendente ON tb_alerta;
DROP TRIGGER IF EXISTS trg_resolver_atendimento_por_justificativa ON tb_justificativa;
DROP TRIGGER IF EXISTS trg_validar_temperatura_categoria_camara ON tb_lote_camara_frigorifica;
DROP TRIGGER IF EXISTS trg_gerar_alerta_por_leitura ON tb_leitura_temperatura;
DROP TRIGGER IF EXISTS trg_notificar_novo_alerta ON tb_alerta;
DROP TRIGGER IF EXISTS trg_validar_gestor_usuario ON tb_usuario;


CREATE OR REPLACE FUNCTION fn_validar_gestor_usuario()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.cod_gestor IS NOT NULL AND NEW.nivel_acesso <> 'operador' THEN
        RAISE EXCEPTION
            'Somente usuários operadores podem possuir um gestor responsável.';
    END IF;

    IF NEW.cod_gestor IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM tb_usuario gestor
        WHERE gestor.id = NEW.cod_gestor
          AND gestor.nivel_acesso = 'gestor'
          AND gestor.cod_cd = NEW.cod_cd
    ) THEN
        RAISE EXCEPTION
            'O gestor % deve existir, ter nível gestor e pertencer ao mesmo CD do usuário %.',
            NEW.cod_gestor, NEW.id;
    END IF;

    IF TG_OP = 'UPDATE'
       AND OLD.nivel_acesso = 'gestor'
       AND NEW.nivel_acesso <> 'gestor'
       AND EXISTS (
           SELECT 1
           FROM tb_usuario subordinado
           WHERE subordinado.cod_gestor = OLD.id
       ) THEN
        RAISE EXCEPTION
            'O gestor % não pode perder o cargo enquanto possuir operadores vinculados.',
            OLD.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_gestor_usuario
BEFORE INSERT OR UPDATE OF cod_gestor, cod_cd, nivel_acesso
ON tb_usuario
FOR EACH ROW EXECUTE FUNCTION fn_validar_gestor_usuario();


CREATE OR REPLACE FUNCTION fn_criar_atendimento_pendente()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO tb_atendimento (cod_alerta, status)
    VALUES (NEW.id, 'pendente');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_criar_atendimento_pendente
AFTER INSERT ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_criar_atendimento_pendente();


CREATE OR REPLACE FUNCTION fn_resolver_atendimento_por_justificativa()
RETURNS TRIGGER AS $$
DECLARE
    v_cod_alerta INTEGER;
    v_cod_camara INTEGER;
    v_data_alerta TIMESTAMP;
    v_status_atendimento VARCHAR(50);
BEGIN
    SELECT
        a.id,
        a.cod_camara_frigorifica,
        a.data_hora,
        atd.status
    INTO
        v_cod_alerta,
        v_cod_camara,
        v_data_alerta,
        v_status_atendimento
    FROM tb_atendimento atd
    JOIN tb_alerta a
        ON a.id = atd.cod_alerta
    WHERE atd.id = NEW.cod_atendimento;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Atendimento % não encontrado.',
            NEW.cod_atendimento;
    END IF;

    IF v_status_atendimento <> 'em_andamento' THEN
        RAISE EXCEPTION
            'O atendimento precisa estar em andamento para ser resolvido.';
    END IF;

    IF fn_camara_temperatura_normal(
        v_cod_camara,
        CURRENT_TIMESTAMP::TIMESTAMP
    ) THEN

        UPDATE tb_atendimento
           SET status = 'resolvido',
               data_hora_resolucao = CURRENT_TIMESTAMP
         WHERE id = NEW.cod_atendimento;

        UPDATE tb_alerta
           SET status = 'resolvido'
         WHERE id = v_cod_alerta;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_resolver_atendimento_por_justificativa
AFTER INSERT ON tb_justificativa
FOR EACH ROW EXECUTE FUNCTION fn_resolver_atendimento_por_justificativa();


CREATE OR REPLACE FUNCTION fn_validar_temperatura_categoria_camara()
RETURNS TRIGGER AS $$
DECLARE
    v_temp_ideal DECIMAL(5,2);
    v_temp_min DECIMAL(5,2);
    v_temp_max DECIMAL(5,2);
BEGIN
    SELECT c.temperatura_ideal, cam.temperatura_min, cam.temperatura_max
      INTO v_temp_ideal, v_temp_min, v_temp_max
      FROM tb_lote l
      JOIN tb_categoria c ON c.id = l.cod_categoria
      JOIN tb_camara_frigorifica cam ON cam.id = NEW.cod_camara_frigorifica
     WHERE l.id = NEW.cod_lote;

    IF v_temp_ideal IS NULL THEN
        RAISE EXCEPTION 'Lote % ou câmara frigorífica % não encontrado.', NEW.cod_lote, NEW.cod_camara_frigorifica;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM tb_lote_camara_frigorifica lr
          JOIN tb_lote lote_existente
            ON lote_existente.id = lr.cod_lote
          JOIN tb_categoria categoria_existente
            ON categoria_existente.id = lote_existente.cod_categoria
         WHERE lr.cod_camara_frigorifica = NEW.cod_camara_frigorifica
           AND lr.data_saida IS NULL
           AND lr.cod_lote <> NEW.cod_lote
           AND lote_existente.status = 'ativo'
           AND categoria_existente.temperatura_ideal IS DISTINCT FROM v_temp_ideal
    ) THEN
        RAISE EXCEPTION 'A câmara frigorífica % já possui lote ativo com temperatura ideal incompatível.', NEW.cod_camara_frigorifica;
    END IF;

    IF v_temp_ideal < v_temp_min OR v_temp_ideal > v_temp_max THEN
        RAISE EXCEPTION 'Temperatura ideal da categoria (%) incompatível com a faixa da câmara frigorífica (% a %).',
            v_temp_ideal, v_temp_min, v_temp_max;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_temperatura_categoria_camara
BEFORE INSERT OR UPDATE OF cod_lote, cod_camara_frigorifica, data_saida
ON tb_lote_camara_frigorifica
FOR EACH ROW EXECUTE FUNCTION fn_validar_temperatura_categoria_camara();


CREATE OR REPLACE FUNCTION fn_gerar_alerta_por_leitura()
RETURNS TRIGGER AS $$
DECLARE
    v_camara INTEGER;
    v_temperatura_min DECIMAL(5,2);
    v_temperatura_max DECIMAL(5,2);
    v_gravidade VARCHAR(20);
    v_vida_util DECIMAL(7,2);
    v_alerta INTEGER;
BEGIN
    SELECT cam.id, cam.temperatura_min, cam.temperatura_max
    INTO v_camara, v_temperatura_min, v_temperatura_max
    FROM tb_camara_frigorifica cam
    WHERE cam.cod_termometro = NEW.cod_termometro;

    IF v_camara IS NULL THEN
        RAISE EXCEPTION 'Termômetro % não está associado a nenhuma câmara frigorífica.', NEW.cod_termometro;
    END IF;

    IF NEW.temperatura < v_temperatura_min OR NEW.temperatura > v_temperatura_max THEN

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
            v_camara,
            v_vida_util,
            'operador',
            NEW.data_hora,
            v_gravidade,
            'ativo'
        )
        RETURNING id INTO v_alerta;

        UPDATE tb_leitura_temperatura
           SET cod_alerta = v_alerta
         WHERE id = NEW.id;

        CALL sp_notificar_nivel_acesso(v_alerta, 'operador');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gerar_alerta_por_leitura
AFTER INSERT ON tb_leitura_temperatura
FOR EACH ROW EXECUTE FUNCTION fn_gerar_alerta_por_leitura();


CREATE OR REPLACE FUNCTION fn_notificar_novo_alerta()
RETURNS TRIGGER AS $$
DECLARE
    v_horas_prazo DECIMAL(7,2);
BEGIN
    v_horas_prazo := fn_calcular_prazo_escalonamento(NEW.id, 40);

    PERFORM pg_notify(
        'novo_alerta',
        json_build_object(
            'id_alerta', NEW.id,
            'prazo_epoch',
            EXTRACT(EPOCH FROM (
                NEW.data_hora + v_horas_prazo * INTERVAL '1 hour'
            ) AT TIME ZONE 'America/Sao_Paulo')
        )::text
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notificar_novo_alerta
AFTER INSERT ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_notificar_novo_alerta();


-- ====================================================================
-- DEPLOY: audit.sql
-- ====================================================================

DROP TABLE IF EXISTS tb_log_acesso;
DROP TABLE IF EXISTS tb_log_auditoria;
DROP TABLE IF EXISTS tb_log_acesso_relatorio;
DROP TABLE IF EXISTS tb_log_escalonamento;
DROP TABLE IF EXISTS tb_log_sensor;
DROP TRIGGER IF EXISTS trg_auditoria_usuario ON tb_usuario;
DROP TRIGGER IF EXISTS trg_auditoria_alerta ON tb_alerta;
DROP TRIGGER IF EXISTS trg_log_escalonamento ON tb_alerta;


-- =============================================
-- TABELAS DE LOG
-- =============================================
CREATE TABLE tb_log_acesso (
	id SERIAL,
	cod_usuario INTEGER,
	tentativa_sucesso BOOLEAN NOT NULL,
	ip_origem INET NOT NULL,
	user_agent TEXT NOT NULL,
	motivo_falha VARCHAR(50),
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_acesso PRIMARY KEY (id),
	CONSTRAINT fk_log_acesso_usuario FOREIGN KEY (cod_usuario) REFERENCES tb_usuario(id)
);

CREATE TABLE tb_log_auditoria (
	id SERIAL,
	cod_usuario INTEGER NOT NULL,
	usuario_bd VARCHAR(100) NOT NULL,
	acao VARCHAR(150) NOT NULL,
	entidade_afetada VARCHAR(50) NOT NULL,
	entidade_id INTEGER NOT NULL,
	dados_antigos JSONB,      
	dados_novos JSONB,  
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_auditoria PRIMARY KEY (id),
	CONSTRAINT fk_log_auditoria_usuario FOREIGN KEY (cod_usuario) REFERENCES tb_usuario(id)
);

CREATE TABLE tb_log_acesso_relatorio (
	id SERIAL,
	cod_relatorio INTEGER NOT NULL,
	cod_usuario INTEGER NOT NULL,
	acao VARCHAR(20) NOT NULL,
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_acesso_relatorio PRIMARY KEY (id),
	CONSTRAINT fk_log_acesso_relatorio_relatorio FOREIGN KEY (cod_relatorio) REFERENCES tb_relatorio(id),
	CONSTRAINT fk_log_acesso_relatorio_usuario FOREIGN KEY (cod_usuario) REFERENCES tb_usuario(id),
	CONSTRAINT ck_log_acesso_relatorio_acao CHECK (acao IN ('visualizou', 'baixou'))
);

CREATE TABLE tb_log_escalonamento (
	id SERIAL,
	cod_alerta INTEGER NOT NULL,
	nivel_anterior VARCHAR(8),
	nivel_novo VARCHAR(8) NOT NULL,
	motivo VARCHAR(50) NOT NULL DEFAULT 'tempo_limite_excedido',
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_escalonamento PRIMARY KEY (id),
	CONSTRAINT fk_log_escalonamento_alerta FOREIGN KEY (cod_alerta) REFERENCES tb_alerta(id)
);

CREATE TABLE tb_log_sensor (
	id SERIAL,
	cod_termometro INTEGER NOT NULL,
	tipo_evento VARCHAR(50) NOT NULL,
	detalhes TEXT NOT NULL,
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_sensor PRIMARY KEY (id),
	CONSTRAINT fk_log_sensor_termometro FOREIGN KEY (cod_termometro) REFERENCES tb_termometro(id)
);


-- =============================================
-- TRIGGERS DE AUDITORIA
-- =============================================
CREATE OR REPLACE FUNCTION fn_log_auditoria() 
RETURNS TRIGGER AS $$
DECLARE
	v_entidade_id INTEGER;
BEGIN
	IF TG_OP = 'DELETE' THEN
		v_entidade_id := OLD.id;
	ELSE
		v_entidade_id := NEW.id;
	END IF;

	INSERT INTO tb_log_auditoria (cod_usuario, usuario_bd, acao, entidade_afetada, entidade_id, dados_antigos, dados_novos)
	VALUES (
		current_setting('app.usuario_atual')::INTEGER,
		CURRENT_USER,
		TG_OP,
		TG_TABLE_NAME,
		v_entidade_id,
		CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
		CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END
	);

	IF TG_OP = 'DELETE' THEN
		RETURN OLD;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auditoria_usuario
AFTER INSERT OR UPDATE OR DELETE ON tb_usuario
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

CREATE TRIGGER trg_auditoria_alerta
AFTER INSERT OR UPDATE OR DELETE ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();


CREATE OR REPLACE FUNCTION fn_log_escalonamento() 
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.nivel_atual IS DISTINCT FROM OLD.nivel_atual THEN
		INSERT INTO tb_log_escalonamento (cod_alerta, nivel_anterior, nivel_novo)
		VALUES (NEW.id, OLD.nivel_atual, NEW.nivel_atual);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_escalonamento
AFTER UPDATE OF nivel_atual ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_log_escalonamento();

-- ====================================================================
-- DEPLOY: catalogo-dados.sql
-- ====================================================================

-- ====================================================================
-- LIMPEZA E CRIAÇÃO DA TABELA
-- Tabela centralizadora do Catálogo de Dados corporativo. 
-- Armazena o inventário de metadados, regras de negócio e mapeamento de segurança. 
-- Serve para auditoria, controle de LGPD e documentação técnica unificada.
-- ====================================================================
DROP TABLE IF EXISTS tb_catalogo_dados;


CREATE TABLE tb_catalogo_dados (
	id SERIAL,
	nome_tabela VARCHAR(100) NOT NULL,
	nome_coluna VARCHAR(100) NOT NULL,
	tipo_dado VARCHAR(50) NOT NULL,
	obrigatorio BOOLEAN NOT NULL DEFAULT FALSE,
	chave VARCHAR(2),
	descricao TEXT NOT NULL,
	regra_negocio TEXT,
	nivel_acesso_leitura VARCHAR(8) NOT NULL DEFAULT 'operador',
	dado_sensivel BOOLEAN NOT NULL DEFAULT FALSE,

	CONSTRAINT pk_catalogo_dados PRIMARY KEY (id),
	CONSTRAINT uq_catalogo_tabela_coluna UNIQUE (nome_tabela, nome_coluna),
	CONSTRAINT ck_catalogo_chave CHECK (chave IN ('PK', 'FK','NK')),
	CONSTRAINT ck_catalogo_nivel_acesso CHECK (nivel_acesso_leitura IN ('sistema', 'operador', 'gestor', 'admin'))
);


-- ====================================================================
-- CARGA DE DADOS DO CATÁLOGO
-- ====================================================================
INSERT INTO tb_catalogo_dados (nome_tabela, nome_coluna, tipo_dado, obrigatorio, chave, descricao, regra_negocio, nivel_acesso_leitura, dado_sensivel) VALUES
 
-- ==============================================
-- tb_estado
-- ==============================================
('tb_estado', 'estado', 'CHAR(2)', TRUE, 'NK', 'Sigla da unidade federativa', 'Única no sistema; armazenada no padrão de duas letras', 'operador', FALSE),

-- ==============================================
-- tb_cd
-- ==============================================
('tb_cd', 'id', 'SERIAL', TRUE, 'PK', 'Identificador único do centro de distribuição', NULL, 'operador', FALSE),
('tb_cd', 'cnpj', 'VARCHAR(14)', TRUE, 'NK', 'CNPJ do centro de distribuição', 'Único no sistema, sem formatação (apenas dígitos)', 'gestor', FALSE),
 
-- ==============================================
-- tb_usuario
-- ==============================================
('tb_usuario', 'id', 'SERIAL', TRUE, 'PK', 'Identificador único do funcionário', NULL, 'operador', FALSE),
('tb_usuario', 'username', 'VARCHAR(50)', TRUE, 'NK', 'Nome de usuário para autenticação', 'Único no sistema; usado no login da aplicação', 'admin', TRUE),
('tb_usuario', 'cpf', 'VARCHAR(11)', TRUE, 'NK', 'CPF do funcionário', 'Único no sistema; dado pessoal protegido por LGPD', 'admin', TRUE),
('tb_usuario', 'email', 'VARCHAR(255)', TRUE, 'NK', 'E-mail do funcionário', 'Único no sistema; usado para login e notificações', 'admin', TRUE),
('tb_usuario', 'senha', 'VARCHAR(255)', TRUE, NULL, 'Hash da senha de acesso', 'Nunca armazenada em texto plano; nunca exposta em relatórios ou exports', 'admin', TRUE),
('tb_usuario', 'nivel_acesso', 'VARCHAR(8)', TRUE, NULL, 'Cargo do funcionário no sistema', 'Níveis: operador, gestor, admin e sistema; sistema representa a administração da plataforma', 'gestor', FALSE),
('tb_usuario', 'cod_cd', 'INTEGER', TRUE, 'FK', 'Centro de distribuição ao qual o funcionário pertence', 'Referencia tb_cd(id)', 'operador', FALSE),
('tb_usuario', 'cod_gestor', 'INTEGER', FALSE, 'FK', 'Gestor responsável pelo funcionário', 'Opcional; deve referenciar um usuário com nível gestor e do mesmo CD', 'gestor', FALSE),
 
-- ==============================================
-- tb_categoria
-- ==============================================
('tb_categoria', 'nome', 'VARCHAR(150)', TRUE, 'NK', 'Categoria de armazenamento', 'Única no sistema; concentra os parâmetros comuns aos lotes', 'operador', FALSE),
('tb_categoria', 'temperatura_ideal', 'DECIMAL(5,2)', TRUE, NULL, 'Temperatura ideal da categoria', 'Usada para calcular a gravidade dos alertas', 'operador', FALSE),
('tb_categoria', 'vida_util_horas', 'DECIMAL(7,2)', TRUE, NULL, 'Vida útil da categoria em horas', 'Base direta do escalonamento do alerta', 'operador', FALSE),
 
-- ==============================================
-- tb_lote
-- ==============================================
('tb_lote', 'codigo_lote', 'VARCHAR(50)', TRUE, 'NK', 'Identificador operacional do lote', 'Único no sistema', 'operador', FALSE),
('tb_lote', 'cod_categoria', 'INTEGER', TRUE, 'FK', 'Categoria do lote', 'Cada lote pertence a exatamente uma categoria', 'operador', FALSE),
('tb_lote', 'data_fabricacao', 'DATE', TRUE, NULL, 'Data de fabricação do lote', 'Usada para rastreabilidade', 'operador', FALSE),
('tb_lote', 'data_validade', 'DATE', TRUE, NULL, 'Data de validade do lote', 'Deve ser igual ou posterior à fabricação', 'operador', FALSE),

-- ==============================================
-- tb_lote_camara_frigorifica
-- ==============================================
('tb_lote_camara_frigorifica', 'cod_lote', 'INTEGER', TRUE, 'FK', 'Lote movimentado', 'Um lote pode passar por várias câmaras frigoríficas ao longo do tempo', 'operador', FALSE),
('tb_lote_camara_frigorifica', 'cod_camara_frigorifica', 'INTEGER', TRUE, 'FK', 'Câmara frigorífica do lote', 'Apenas uma localização atual pode ficar aberta por lote', 'operador', FALSE),
('tb_lote_camara_frigorifica', 'data_entrada', 'TIMESTAMP', TRUE, NULL, 'Entrada do lote na câmara frigorífica', 'Início do período de armazenamento', 'operador', FALSE),
('tb_lote_camara_frigorifica', 'data_saida', 'TIMESTAMP', FALSE, NULL, 'Saída do lote da câmara frigorífica', 'NULL indica a localização atual', 'operador', FALSE),
 
-- ==============================================
-- tb_camara_frigorifica
-- ==============================================
('tb_camara_frigorifica', 'cod_termometro', 'INTEGER', TRUE, 'FK', 'Termômetro instalado na câmara frigorífica', 'Relação 1:1 — cada termômetro pertence a exatamente uma câmara frigorífica (UNIQUE)', 'operador', FALSE),
 
-- ==============================================
-- tb_alerta
-- ==============================================
('tb_alerta', 'nivel_atual', 'VARCHAR(8)', TRUE, NULL, 'Cargo responsável pelo alerta no momento', 'Nasce como operador; muda automaticamente por escalonamento (trigger monitora esse campo)', 'operador', FALSE),
('tb_alerta', 'cod_camara_frigorifica', 'INTEGER', TRUE, 'FK', 'Câmara frigorífica que originou o alerta', 'Todo alerta pertence à câmara que originou a ocorrência', 'operador', FALSE),
('tb_alerta', 'vida_util_referencia_horas', 'DECIMAL(7,2)', FALSE, NULL, 'Menor vida útil entre os lotes ativos no momento do alerta', 'Base dos prazos fixos de escalonamento', 'gestor', FALSE),
('tb_alerta', 'status', 'VARCHAR(100)', TRUE, NULL, 'Fase do atendimento do alerta', 'Não confundir com nivel_atual: status é sobre o atendimento (ativo/reconhecido/resolvido), nivel_atual é sobre o cargo responsável', 'operador', FALSE),
('tb_alerta', 'nivel_gravidade', 'VARCHAR(100)', TRUE, NULL, 'Gravidade do alerta', 'Calculada via fn_calcular_gravidade_alerta: baixa, atenção, urgente ou crítica', 'operador', FALSE),
('tb_alerta', 'data_hora', 'TIMESTAMP', TRUE, NULL, 'Momento de criação do alerta', 'Usado como referência para o escalonamento', 'operador', FALSE),
('tb_alerta', 'tipo', 'VARCHAR(100)', TRUE, NULL, 'Tipo da ocorrência', 'Atualmente limitado a temperatura_fora_padrao', 'operador', FALSE),

-- tb_notificacao_alerta
-- ==============================================
('tb_notificacao_alerta', 'cod_alerta', 'INTEGER', TRUE, 'FK', 'Alerta notificado', 'Relaciona a notificação ao alerta correspondente', 'operador', FALSE),
('tb_notificacao_alerta', 'cod_usuario', 'INTEGER', TRUE, 'FK', 'Usuário notificado', 'Usuário do mesmo CD e nível de acesso do escalonamento', 'operador', FALSE),
('tb_notificacao_alerta', 'data_hora_envio', 'TIMESTAMP', TRUE, NULL, 'Momento do registro da notificação', 'Usado para histórico de envio das notificações push', 'operador', FALSE),

-- tb_leitura_temperatura
-- ==============================================
('tb_leitura_temperatura', 'cod_termometro', 'INTEGER', TRUE, 'FK', 'Termômetro de origem da leitura', 'A câmara é identificada pelo termômetro associado', 'operador', FALSE),
('tb_leitura_temperatura', 'cod_alerta', 'INTEGER', FALSE, 'FK', 'Alerta gerado pela leitura', 'Preenchido quando a leitura está fora da faixa da câmara', 'operador', FALSE),
('tb_leitura_temperatura', 'temperatura', 'DECIMAL(5,2)', TRUE, NULL, 'Temperatura medida', 'Comparada com a faixa da câmara e com a temperatura ideal da categoria', 'operador', FALSE),
('tb_leitura_temperatura', 'data_hora', 'TIMESTAMP', TRUE, NULL, 'Momento da medição', 'Preservado no histórico do PostgreSQL após a fila Redis', 'operador', FALSE),
('tb_leitura_temperatura', 'id_evento_redis', 'VARCHAR(100)', FALSE, 'NK', 'Identificador da leitura no Redis', 'Evita duplicidade quando o consumidor reprocessa uma mensagem', 'admin', FALSE),
 
-- ==============================================
-- tb_atendimento
-- ==============================================
('tb_atendimento', 'cod_usuario', 'INTEGER', FALSE, 'FK', 'Funcionário responsável pelo atendimento', 'Aceita NULL: atendimento nasce pendente (via trigger), sem usuário atribuído até alguém reconhecer o alerta', 'operador', FALSE),
('tb_atendimento', 'status', 'VARCHAR(50)', TRUE, NULL, 'Situação do atendimento', 'pendente -> em_andamento -> resolvido; transições controladas por sp_reconhecer_alerta e trigger de justificativa', 'operador', FALSE),
('tb_atendimento', 'data_hora_reconhecimento', 'TIMESTAMP', FALSE, NULL, 'Momento em que alguém assumiu o alerta', 'Diferente de data_hora_resolucao: reconhecimento é "estou ciente", resolução é "problema resolvido de fato"', 'operador', FALSE),
('tb_atendimento', 'data_hora_resolucao', 'TIMESTAMP', FALSE, NULL, 'Momento em que o atendimento foi finalizado', 'Métrica de HACCP: mede quanto tempo o lote ficou de fato em risco, não só sem monitoramento', 'operador', FALSE),
 
-- ==============================================
-- tb_justificativa
-- ==============================================
('tb_justificativa', 'cod_atendimento', 'INTEGER', TRUE, 'FK', 'Atendimento ao qual a justificativa se refere', 'Ao ser inserida, dispara trigger que valida a temperatura e resolve o atendimento somente se ele estiver em andamento e a câmara estiver normalizada', 'operador', FALSE),
 
-- ==============================================
-- tb_relatorio
-- ==============================================
('tb_relatorio', 'hash_conteudo', 'VARCHAR(64)', TRUE, NULL, 'Hash SHA-256 do conteúdo do relatório', 'Garante integridade: qualquer alteração no conteúdo altera o hash, evidenciando adulteração', 'admin', TRUE),
('tb_relatorio', 'status', 'VARCHAR(50)', TRUE, NULL, 'Situação do relatório', 'gerado -> assinado -> arquivado', 'gestor', FALSE),
('tb_relatorio', 'periodo_inicio', 'DATE', TRUE, NULL, 'Início do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: força quem gera o relatório a informar o período explicitamente', 'gestor', FALSE),
('tb_relatorio', 'periodo_fim', 'DATE', TRUE, NULL, 'Fim do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: evita relatório de período incorreto por esquecimento', 'gestor', FALSE),
 
-- ==============================================
-- tb_assinatura
-- ==============================================
('tb_assinatura', 'numero_serie', 'VARCHAR(64)', TRUE, NULL, 'Número de série do certificado ICP-Brasil', 'Identifica unicamente o certificado usado para dar validade jurídica ao relatório', 'admin', TRUE),
('tb_assinatura', 'carimbo_tempo', 'TEXT', TRUE, NULL, 'Token de carimbo de tempo (RFC 3161)', 'Emitido por Autoridade de Carimbo do Tempo externa; garante quando a assinatura ocorreu, de forma não manipulável', 'admin', TRUE),
 
-- ==============================================
-- tb_log_auditoria
-- ==============================================
('tb_log_auditoria', 'usuario_bd', 'VARCHAR(100)', TRUE, NULL, 'Login de conexão do Postgres (CURRENT_USER) que executou a ação', 'Diferente de cod_usuario: detecta alterações feitas fora da aplicação', 'admin', FALSE),
('tb_log_auditoria', 'dados_antigos', 'JSONB', FALSE, NULL, 'Estado da linha antes da alteração (OLD)', 'Preenchido apenas em UPDATE/DELETE; pode conter dados sensíveis das tabelas auditadas', 'admin', TRUE),
('tb_log_auditoria', 'dados_novos', 'JSONB', FALSE, NULL, 'Estado da linha depois da alteração (NEW)', 'Preenchido apenas em INSERT/UPDATE; pode conter dados sensíveis das tabelas auditadas', 'admin', TRUE),
 
-- ==============================================
-- tb_log_escalonamento
-- ==============================================
('tb_log_escalonamento', 'nivel_anterior', 'VARCHAR(8)', FALSE, NULL, 'Cargo que tinha o alerta antes da escalada', 'NULL na primeira escalada (alerta nasce sem "nível anterior")', 'operador', FALSE),
 
-- ==============================================
-- tb_log_acesso
-- ==============================================
('tb_log_acesso', 'ip_origem', 'INET', TRUE, NULL, 'Endereço IP de onde partiu a tentativa de acesso', 'Considerado dado pessoal pela LGPD (permite identificação indireta do usuário)', 'admin', TRUE);



-- ====================================================================
-- DEPLOY: dau.sql
-- ====================================================================

DROP VIEW IF EXISTS vw_dau_diario;

CREATE VIEW vw_dau_diario AS
SELECT
    data_hora::DATE AS data_acesso,
    COUNT(DISTINCT cod_usuario) AS usuarios_ativos
FROM tb_log_acesso
WHERE tentativa_sucesso = TRUE
  AND cod_usuario IS NOT NULL
GROUP BY data_hora::DATE;

-- ====================================================================
-- DEPLOY: etl-transformacoes.sql
-- ====================================================================

-- ====================================================================
-- TRANSFORMAÇÕES ETL: CTEs, WINDOW FUNCTIONS E CTE RECURSIVA
-- ====================================================================

-- 1. CTE + Window Functions:
-- consolida as leituras persistidas, classifica a situação térmica e
-- calcula a variação e a média acumulada de cada termômetro.
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
				THEN 'normal'
			ELSE 'fora_da_faixa'
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

-- 2. CTE + Window Functions:
-- identifica a menor vida útil entre os lotes ativos de cada câmara.
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
	WHERE l.status = 'ativo'
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

-- 3. CTE recursiva:
-- transforma a hierarquia de escalonamento em etapas de negócio.
-- A recursão avança apenas até o nivel_atual real do alerta, então a
-- profundidade varia por linha (1 a 3 etapas), em vez de ser sempre fixa.
WITH RECURSIVE etapas_escalonamento AS (
	SELECT
		a.id AS cod_alerta,
		a.data_hora AS inicio_alerta,
		'operador'::VARCHAR(8) AS nivel,
		1 AS ordem_etapa,
		0 AS percentual_vida_util,
		a.nivel_atual
	FROM tb_alerta a

	UNION ALL

	SELECT
		etapas.cod_alerta,
		etapas.inicio_alerta,
		CASE etapas.nivel
			WHEN 'operador' THEN 'gestor'
			WHEN 'gestor' THEN 'admin'
		END::VARCHAR(8) AS nivel,
		etapas.ordem_etapa + 1,
		CASE etapas.nivel
			WHEN 'operador' THEN 40
			WHEN 'gestor' THEN 70
		END AS percentual_vida_util,
		etapas.nivel_atual
	FROM etapas_escalonamento etapas
	WHERE etapas.nivel != etapas.nivel_atual
	  AND etapas.nivel IN ('operador', 'gestor')
)
SELECT
	cod_alerta,
	inicio_alerta,
	nivel,
	ordem_etapa,
	percentual_vida_util
FROM etapas_escalonamento
ORDER BY cod_alerta, ordem_etapa;

-- ====================================================================
-- DEPLOY: indices.sql
-- ====================================================================

DROP INDEX IF EXISTS idx_leitura_termometro_data;
DROP INDEX IF EXISTS idx_alerta_escalonamento;
DROP INDEX IF EXISTS idx_lote_camara_ativos;
DROP INDEX IF EXISTS idx_atendimento_alerta_status;

ANALYZE tb_leitura_temperatura;
ANALYZE tb_alerta;
ANALYZE tb_lote_camara_frigorifica;

-- 1. CENÁRIO INICIAL: análise sem os índices
EXPLAIN (ANALYZE, BUFFERS)
SELECT lt.id, lt.temperatura, lt.data_hora
FROM tb_leitura_temperatura lt
WHERE lt.cod_termometro = 1
ORDER BY lt.data_hora DESC, lt.id DESC
LIMIT 1;

EXPLAIN (ANALYZE, BUFFERS)
SELECT a.id, a.nivel_atual, a.data_hora
FROM tb_alerta a
WHERE a.status = 'ativo'
  AND a.nivel_atual IN ('operador', 'gestor')
ORDER BY a.data_hora;

EXPLAIN (ANALYZE, BUFFERS)
SELECT lc.cod_lote, lc.cod_camara_frigorifica
FROM tb_lote_camara_frigorifica lc
WHERE lc.cod_camara_frigorifica = 1
  AND lc.data_saida IS NULL;


-- ====================================================================
-- DEPLOY: roles.sql
-- ====================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'skadi_operador') THEN
        EXECUTE 'CREATE ROLE skadi_operador NOLOGIN';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'skadi_gestor') THEN
        EXECUTE 'CREATE ROLE skadi_gestor NOLOGIN';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'skadi_admin') THEN
        EXECUTE 'CREATE ROLE skadi_admin NOLOGIN';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'skadi_sistema') THEN
        EXECUTE 'CREATE ROLE skadi_sistema NOLOGIN';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'skadi_worker') THEN
        EXECUTE 'CREATE ROLE skadi_worker NOLOGIN';
    END IF;
END;
$$;

GRANT USAGE ON SCHEMA public
TO skadi_operador, skadi_gestor, skadi_admin, skadi_sistema, skadi_worker;

GRANT SELECT ON
    tb_cd,
    tb_camara_frigorifica,
    tb_categoria,
    tb_lote,
    tb_lote_camara_frigorifica,
    tb_alerta,
    tb_notificacao_alerta,
    tb_atendimento,
    tb_justificativa,
    tb_leitura_temperatura
TO skadi_operador, skadi_gestor, skadi_admin;

GRANT SELECT (id, nome, username, email, nivel_acesso, cod_cd, cod_gestor)
ON tb_usuario
TO skadi_operador, skadi_gestor, skadi_admin;

GRANT EXECUTE ON PROCEDURE sp_reconhecer_alerta(INTEGER, INTEGER)
TO skadi_operador, skadi_gestor, skadi_admin;

REVOKE EXECUTE ON PROCEDURE sp_reconhecer_alerta(INTEGER, INTEGER) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE sp_notificar_nivel_acesso(INTEGER, VARCHAR) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE sp_escalonar_alertas_pendentes() FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE sp_cadastrar_usuario(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INTEGER, INTEGER) FROM PUBLIC;

GRANT SELECT ON
    tb_relatorio,
    tb_assinatura,
    tb_catalogo_dados,
    tb_log_auditoria,
    tb_log_escalonamento,
    tb_log_acesso,
    tb_log_acesso_relatorio,
    tb_log_sensor
TO skadi_gestor, skadi_admin;

GRANT EXECUTE ON PROCEDURE sp_cadastrar_usuario(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INTEGER, INTEGER)
TO skadi_sistema, skadi_admin;

GRANT SELECT ON
    tb_camara_frigorifica,
    tb_lote_camara_frigorifica,
    tb_lote,
    tb_categoria
TO skadi_worker;
GRANT SELECT (id, nivel_acesso, cod_cd)
ON tb_usuario TO skadi_worker;
GRANT INSERT ON tb_leitura_temperatura TO skadi_worker;
GRANT UPDATE (cod_alerta) ON tb_leitura_temperatura TO skadi_worker;
GRANT INSERT ON tb_alerta, tb_atendimento, tb_notificacao_alerta TO skadi_worker;
GRANT USAGE, SELECT ON SEQUENCE tb_leitura_temperatura_id_seq TO skadi_worker;
GRANT USAGE, SELECT ON SEQUENCE tb_alerta_id_seq, tb_atendimento_id_seq, tb_notificacao_alerta_id_seq TO skadi_worker;
GRANT EXECUTE ON PROCEDURE sp_notificar_nivel_acesso(INTEGER, VARCHAR)
TO skadi_worker;
GRANT EXECUTE ON PROCEDURE sp_escalonar_alertas_pendentes()
TO skadi_worker;

REVOKE INSERT, UPDATE, DELETE ON tb_usuario
FROM skadi_operador, skadi_gestor, skadi_admin, skadi_sistema, skadi_worker;

-- 2. ÍNDICES APLICADOS
CREATE INDEX idx_leitura_termometro_data
    ON tb_leitura_temperatura (cod_termometro, data_hora DESC, id DESC);

CREATE INDEX idx_alerta_escalonamento
    ON tb_alerta (status, nivel_atual, data_hora);

CREATE INDEX idx_lote_camara_ativos
    ON tb_lote_camara_frigorifica (cod_camara_frigorifica, cod_lote)
    WHERE data_saida IS NULL;

CREATE INDEX idx_atendimento_alerta_status
    ON tb_atendimento (cod_alerta, status);

ANALYZE tb_leitura_temperatura;
ANALYZE tb_alerta;
ANALYZE tb_lote_camara_frigorifica;

-- 3. CENÁRIO OTIMIZADO: análise após os índices
EXPLAIN (ANALYZE, BUFFERS)
SELECT lt.id, lt.temperatura, lt.data_hora
FROM tb_leitura_temperatura lt
WHERE lt.cod_termometro = 1
ORDER BY lt.data_hora DESC, lt.id DESC
LIMIT 1;

EXPLAIN (ANALYZE, BUFFERS)
SELECT a.id, a.nivel_atual, a.data_hora
FROM tb_alerta a
WHERE a.status = 'ativo'
  AND a.nivel_atual IN ('operador', 'gestor')
ORDER BY a.data_hora;

EXPLAIN (ANALYZE, BUFFERS)
SELECT lc.cod_lote, lc.cod_camara_frigorifica
FROM tb_lote_camara_frigorifica lc
WHERE lc.cod_camara_frigorifica = 1
  AND lc.data_saida IS NULL;
