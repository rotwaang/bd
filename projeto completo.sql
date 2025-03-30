-- Criação do banco de dados
CREATE DATABASE IF NOT EXISTS ProjetoBD;
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

-- Stored Procedures para testes das questões

-- Questão 1: Transação ACID
DELIMITER $$
CREATE PROCEDURE TestarACID(IN equipeId INT)
BEGIN
    START TRANSACTION;
    INSERT INTO Alunos (nome, email, matricula) VALUES ('Teste ACID', 'teste@acid.com', '00000000');
    ROLLBACK;  -- Simula rollback para testar atomicidade
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 1, 'Transação ACID testada com rollback.');
END$$
DELIMITER ;

-- Questão 8: Deadlock Simulation
DELIMITER $$
CREATE PROCEDURE SimularDeadlock(IN equipeId INT)
BEGIN
    START TRANSACTION;
    UPDATE Alunos SET email = 'trans1@teste.com' WHERE id = 1; -- Transação 1
    DO SLEEP(5);  -- Dar tempo para outra transação
    UPDATE Alunos SET email = 'trans2@teste.com' WHERE id = 2; -- Causar deadlock
    COMMIT;
    INSERT INTO Logs_Testes (equipe_id, questao_id, evento) 
    VALUES (equipeId, 8, 'Deadlock simulado com sucesso.');
END$$
DELIMITER ;

-- Chamadas de exemplo para os testes
CALL TestarACID(1);
CALL SimularDeadlock(1);

-- Inserção de tentativas exemplares
INSERT INTO Tentativas (equipe_id, questao_id, resposta, status) VALUES
(1, 1, 'Atomicidade verificada via rollback.', 'CORRETA'),
(1, 8, 'Deadlock resolvido com estratégia de retry.', 'CORRETA');

-- Consulta para verificar dados
SELECT * FROM Logs_Testes WHERE equipe_id = 1;
SELECT * FROM Tentativas WHERE equipe_id = 1;