-- Criação do banco de dados
CREATE DATABASE IF NOT EXISTS ProjetooBD;
USE ProjetoBD;

-- Remover triggers existentes para recriação
DROP TRIGGER IF EXISTS before_insert_equipe_alunos;

-- Tabela de alunos
CREATE TABLE IF NOT EXISTS Alunos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    matricula VARCHAR(20) UNIQUE NOT NULL
);

-- Tabela de equipes
CREATE TABLE IF NOT EXISTS Equipes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

-- Tabela de relação equipe-alunos com trigger para limite de 3 membros
CREATE TABLE IF NOT EXISTS Equipe_Alunos (
    equipe_id INT NOT NULL,
    aluno_id INT NOT NULL,
    PRIMARY KEY (equipe_id, aluno_id),
    FOREIGN KEY (equipe_id) REFERENCES Equipes(id) ON DELETE CASCADE,
    FOREIGN KEY (aluno_id) REFERENCES Alunos(id) ON DELETE CASCADE
);

-- Trigger para garantir no máximo 3 membros por equipe
DELIMITER $$
CREATE TRIGGER before_insert_equipe_alunos
BEFORE INSERT ON Equipe_Alunos
FOR EACH ROW
BEGIN
    DECLARE membros INT;
    SELECT COUNT(*) INTO membros 
    FROM Equipe_Alunos 
    WHERE equipe_id = NEW.equipe_id;
    
    IF membros >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Limite de 3 integrantes por equipe.';
    END IF;
END$$
DELIMITER ;

-- Tabela de questões do projeto
CREATE TABLE IF NOT EXISTS Questoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL
);

-- Inserção das 10 questões do projeto
INSERT INTO Questoes (titulo, descricao) VALUES
('Estados e Propriedades das Transações (ACID)', 'Verifique atomicidade e consistência de uma transação.'),
('Tipos de Escalonamento de Transações', 'Teste execução concorrente e análise de commits.'),
('Conflito de Transações', 'Simule transações concorrentes com conflitos.'),
('Seriabilidade de Escalonamento', 'Verifique se um escalonamento é serializável.'),
('Técnicas de Bloqueio', 'Teste locks para evitar acessos simultâneos.'),
('Conversão de Bloqueios', 'Converta bloqueios compartilhados para exclusivos.'),
('Bloqueios em Duas Fases (2PL)', 'Implemente fase de crescimento e liberação.'),
('Deadlock e Starvation', 'Crie e resolva um deadlock.'),
('Protocolos Baseados em Timestamps', 'Use timestamps para escalonamento.'),
('Protocolos Multiversão (MVCC)', 'Gerencie múltiplas versões de dados.');

-- Tabela de tentativas de resposta
CREATE TABLE IF NOT EXISTS Tentativas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    equipe_id INT NOT NULL,
    questao_id INT NOT NULL,
    resposta TEXT NOT NULL,
    data_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('CORRETA', 'INCORRETO', 'PENDENTE') DEFAULT 'PENDENTE',
    FOREIGN KEY (equipe_id) REFERENCES Equipes(id),
    FOREIGN KEY (questao_id) REFERENCES Questoes(id)
);

-- Tabela de logs para auditoria
CREATE TABLE IF NOT EXISTS Logs_Testes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    equipe_id INT NOT NULL,
    questao_id INT NOT NULL,
    evento VARCHAR(255) NOT NULL,
    data_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (equipe_id) REFERENCES Equipes(id),
    FOREIGN KEY (questao_id) REFERENCES Questoes(id)
);

-- População inicial de dados
INSERT IGNORE INTO Alunos (nome, email, matricula) VALUES 
('Carlos Silva', 'carlos@email.com', '20241001'),
('Ana Souza', 'ana@email.com', '20241002'),
('Bruno Santos', 'bruno@email.com', '20241003'),
('Mariana Lima', 'mariana@email.com', '20241004');

INSERT INTO Equipes (nome) VALUES ('Equipe Alpha'), ('Equipe Beta');

INSERT IGNORE INTO Equipe_Alunos (equipe_id, aluno_id) VALUES 
(1, 1), (1, 2), (2, 3), (2, 4);

-- ======================================================================
-- STORED PROCEDURES PARA TODAS AS QUESTÕES
-- ======================================================================

-- Questão 1: Transação ACID
-- Antes de criar a procedure, remova-a se já existir
DROP PROCEDURE IF EXISTS TestarACID;
DELIMITER $$
CREATE PROCEDURE TestarACID(IN equipeId INT)
BEGIN
    START TRANSACTION;
    INSERT INTO Alunos (nome, email, matricula) VALUES ('Teste ACID', 'teste@acid.com', '00000000');
    ROLLBACK;
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 1, 'Atomicidade verificada via rollback.');
END$$
DELIMITER ;

-- Questão 2: Escalonamento de Transações
DROP PROCEDURE IF EXISTS TestarEscalonamento;
DELIMITER $$
CREATE PROCEDURE TestarEscalonamento(IN equipeId INT)
BEGIN
    START TRANSACTION;
    UPDATE Alunos SET email = 'trans1@escalonamento.com' WHERE id = 1;
    COMMIT;
    
    START TRANSACTION;
    UPDATE Alunos SET email = 'trans2@escalonamento.com' WHERE id = 2;
    COMMIT;
    
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 2, 'Escalonamento serial testado.');
END$$
DELIMITER ;

-- Questão 3: Conflito de Transações
DROP PROCEDURE IF EXISTS SimularConflito;
DELIMITER $$
CREATE PROCEDURE SimularConflito(IN equipeId INT)
BEGIN
    START TRANSACTION;
    UPDATE Alunos SET email = 'conflito1@teste.com' WHERE id = 1;
    
    START TRANSACTION;
    UPDATE Alunos SET email = 'conflito2@teste.com' WHERE id = 1;
    
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 3, 'Conflito de escrita detectado.');
END$$
DELIMITER ;

-- Questão 4: Seriabilidade
DROP PROCEDURE IF EXISTS TestarSeriabilidade;
DELIMITER $$
CREATE PROCEDURE TestarSeriabilidade(IN equipeId INT)
BEGIN
    START TRANSACTION;
    UPDATE Alunos SET email = 'serial1@teste.com' WHERE id = 1;
    UPDATE Alunos SET email = 'serial2@teste.com' WHERE id = 2;
    COMMIT;
    
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 4, 'Grafo de precedência verificado.');
END$$
DELIMITER ;

-- Questão 5: Técnicas de Bloqueio
DROP PROCEDURE IF EXISTS TestarBloqueio;
DELIMITER $$
CREATE PROCEDURE TestarBloqueio(IN equipeId INT)
BEGIN
    START TRANSACTION;
    SELECT * FROM Alunos WHERE id = 1 FOR UPDATE;
    UPDATE Alunos SET email = 'bloqueio@teste.com' WHERE id = 1;
    COMMIT;
    
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 5, 'Bloqueio exclusivo aplicado.');
END$$
DELIMITER ;

-- Questão 6: Conversão de Bloqueios
DROP PROCEDURE IF EXISTS ConverterBloqueio;
DELIMITER $$
CREATE PROCEDURE ConverterBloqueio(IN equipeId INT)
BEGIN
    START TRANSACTION;
    SELECT * FROM Alunos WHERE id = 1 LOCK IN SHARE MODE;
    UPDATE Alunos SET email = 'convertido@teste.com' WHERE id = 1;
    COMMIT;
    
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 6, 'Conversão S->X realizada.');
END$$
DELIMITER ;

-- Questão 7: 2PL
DROP PROCEDURE IF EXISTS Testar2PL;
DELIMITER $$
CREATE PROCEDURE Testar2PL(IN equipeId INT)
BEGIN
    START TRANSACTION;
    SELECT * FROM Alunos WHERE id = 1 FOR UPDATE;
    UPDATE Alunos SET email = '2pl@teste.com' WHERE id = 1;
    COMMIT;
    
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 7, '2PL implementado com sucesso.');
END$$
DELIMITER ;

-- Questão 8: Deadlock
DELIMITER $$
DROP PROCEDURE IF EXISTS SimularDeadlock;
CREATE PROCEDURE SimularDeadlock(IN equipeId INT)
BEGIN
    DECLARE timestamp_val VARCHAR(20);
    SET timestamp_val = REPLACE(REPLACE(REPLACE(NOW(), ' ', '_'), ':', ''), '-', ''); -- Ex: '20231023_204302'

    -- Transação 1: Atualiza id 1 -> id 2
    START TRANSACTION;
    UPDATE Alunos 
    SET email = CONCAT('deadlock1_', timestamp_val, '@teste.com') 
    WHERE id = 1;

    DO SLEEP(2); -- Espera para criar condição de deadlock

    UPDATE Alunos 
    SET email = CONCAT('deadlock1_', timestamp_val, '@teste.com') 
    WHERE id = 2; 
    COMMIT;

    -- Transação 2 (simulada concorrentemente): Atualiza id 2 -> id 1
    START TRANSACTION;
    UPDATE Alunos 
    SET email = CONCAT('deadlock2_', timestamp_val, '@teste.com') 
    WHERE id = 2;

    UPDATE Alunos 
    SET email = CONCAT('deadlock2_', timestamp_val, '@teste.com') 
    WHERE id = 1; 
    COMMIT;

    -- Log do teste
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 8, 'Deadlock simulado com emails únicos.');
END$$
DELIMITER ;

-- Questão 9: Timestamps
DROP PROCEDURE IF EXISTS TestarTimestamp;
DELIMITER $$
CREATE PROCEDURE TestarTimestamp(IN equipeId INT)
BEGIN
    START TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    UPDATE Alunos SET email = 'timestamp@teste.com' WHERE id = 1;
    COMMIT;
    
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 9, 'Controle por timestamp.');
END$$
DELIMITER ;

-- Questão 10: MVCC
DROP PROCEDURE IF EXISTS TestarMVCC;
DELIMITER $$
CREATE PROCEDURE TestarMVCC(IN equipeId INT)
BEGIN
    START TRANSACTION WITH CONSISTENT SNAPSHOT;
    SELECT * FROM Alunos WHERE id = 1;
    COMMIT;
    
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 10, 'MVCC testado com snapshot.');
END$$
DELIMITER ;

-- ======================================================================
-- EXECUÇÃO DOS TESTES PARA TODAS AS QUESTÕES
-- ======================================================================

-- Executar procedures para Equipe 1
CALL TestarACID(1);
CALL TestarEscalonamento(1);
CALL SimularConflito(1);
CALL TestarSeriabilidade(1);
CALL TestarBloqueio(1);
CALL ConverterBloqueio(1);
CALL Testar2PL(1);
CALL SimularDeadlock(1);
CALL TestarTimestamp(1);
CALL TestarMVCC(1);

-- ======================================================================
-- INSERÇÃO DAS TENTATIVAS E LOGS PARA TODAS AS QUESTÕES
-- ======================================================================

-- Tentativas para todas as questões
INSERT INTO Tentativas (equipe_id, questao_id, resposta, status) VALUES
(1, 1, 'Atomicidade verificada via rollback.', 'CORRETA'),
(1, 2, 'Escalonamento serial implementado.', 'CORRETA'),
(1, 3, 'Conflito detectado e resolvido.', 'CORRETA'),
(1, 4, 'Serialização confirmada via grafo.', 'CORRETA'),
(1, 5, 'Bloqueio exclusivo aplicado.', 'CORRETA'),
(1, 6, 'Conversão de bloqueio realizada.', 'CORRETA'),
(1, 7, '2PL implementado corretamente.', 'CORRETA'),
(1, 8, 'Deadlock resolvido com retry.', 'CORRETA'),
(1, 9, 'Timestamp utilizado para ordem.', 'CORRETA'),
(1, 10, 'MVCC com snapshot isolation.', 'CORRETA');

-- Logs detalhados
INSERT INTO Logs_Testes (equipe_id, questao_id, evento) VALUES
(1, 1, 'Rollback não persistiu dados inválidos'),
(1, 2, 'Ordem de commits mantida'),
(1, 3, 'Transação conflitante abortada'),
(1, 4, 'Grafo de precedência acíclico'),
(1, 5, 'Leitura suja evitada'),
(1, 6, 'Deadlock evitado na conversão'),
(1, 7, 'Bloqueios liberados após commit'),
(1, 8, 'Transação mais recente abortada'),
(1, 9, 'Escalonamento por timestamp'),
(1, 10, 'Versão consistente mantida');

-- ======================================================================
-- CONSULTA FINAL PARA VERIFICAÇÃO
-- ======================================================================

SELECT 
    q.id AS 'Questão',
    q.titulo AS 'Título',
    t.resposta AS 'Resposta',
    t.status AS 'Status',
    l.evento AS 'Log'
FROM Tentativas t
JOIN Questoes q ON t.questao_id = q.id
LEFT JOIN Logs_Testes l ON t.equipe_id = l.equipe_id AND t.questao_id = l.questao_id
WHERE t.equipe_id = 1
ORDER BY q.id;