-- Criando o banco de dados do projeto
CREATE DATABASE IF NOT EXISTS ProjetoBD;
USE ProjetoBD;
DROP TRIGGER IF EXISTS before_insert_equipe_alunos;
-- Tabela de alunos
CREATE TABLE IF NOT EXISTS Alunos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    matricula VARCHAR(20) UNIQUE NOT NULL
);


-- Tabela de equipes (até 3 integrantes por equipe)
CREATE TABLE IF NOT EXISTS Equipes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

-- Relacionamento entre Alunos e Equipes (máximo de 3 integrantes por equipe)
-- ... (resto do script)

-- Tabela Equipe_Alunos (sem a cláusula CHECK)
CREATE TABLE IF NOT EXISTS Equipe_Alunos (
    equipe_id INT NOT NULL,
    aluno_id INT NOT NULL,
    PRIMARY KEY (equipe_id, aluno_id),
    FOREIGN KEY (equipe_id) REFERENCES Equipes(id) ON DELETE CASCADE,
    FOREIGN KEY (aluno_id) REFERENCES Alunos(id) ON DELETE CASCADE
);

-- Triggers para validação de 3 integrantes
DELIMITER $$
CREATE TRIGGER before_insert_equipe_alunos
BEFORE INSERT ON Equipe_Alunos
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Equipe_Alunos WHERE equipe_id = NEW.equipe_id) >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Limite de 3 integrantes por equipe.';
    END IF;
END$$
DELIMITER ;


CREATE TABLE IF NOT EXISTS Questoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL
);
-- Populando a tabela com as 10 questões do projeto
INSERT INTO Questoes (titulo, descricao) VALUES
('Estados e Propriedades das Transações (ACID)', 'Verifique a atomicidade e a consistência de uma transação.'),
('Tipos de Escalonamento de Transações', 'Teste a execução concorrente de transações e analise a ordem dos commits.'),
('Conflito de Transações', 'Simule duas transações concorrentes e observe os conflitos gerados.'),
('Seriabilidade de Escalonamento', 'Analise um escalonamento e verifique se ele é serializável.'),
('Técnicas de Bloqueio de Transações', 'Teste locks em registros para evitar acessos simultâneos indesejados.'),
('Conversão de Bloqueios', 'Verifique a conversão de bloqueios compartilhados para exclusivos.'),
('Bloqueios em Duas Fases (2PL)', 'Observe como funciona a fase de crescimento e liberação de bloqueios.'),
('Deadlock e Starvation', 'Crie um deadlock intencional entre duas transações e veja como o banco reage.'),
('Protocolos Baseados em Timestamps', 'Teste a execução de transações usando timestamps para escalonamento.'),
('Protocolos Multiversão (MVCC)', 'Verifique como o banco gerencia múltiplas versões de um mesmo dado.');
START TRANSACTION;
INSERT IGNORE INTO Alunos (nome, email, matricula) 
VALUES ('Lola', 'lola@exemplo.com', '99999999');
ROLLBACK;

SELECT * FROM Alunos WHERE matricula = '99999999';


-- Tabela de tentativas de respostas dos alunos
CREATE TABLE IF NOT EXISTS Tentativas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    equipe_id INT NOT NULL,
    questao_id INT NOT NULL,
    resposta TEXT NOT NULL,
    data_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('CORRETA', 'INCORRETA', 'PENDENTE') DEFAULT 'PENDENTE',
    FOREIGN KEY (equipe_id) REFERENCES Equipes(id) ON DELETE CASCADE,
    FOREIGN KEY (questao_id) REFERENCES Questoes(id) ON DELETE CASCADE
);

-- Tabela para logs das transações realizadas nos testes das questões
CREATE TABLE IF NOT EXISTS Logs_Testes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    equipe_id INT NOT NULL,
    questao_id INT NOT NULL,
    evento VARCHAR(255) NOT NULL,
    data_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (equipe_id) REFERENCES Equipes(id) ON DELETE CASCADE,
    FOREIGN KEY (questao_id) REFERENCES Questoes(id) ON DELETE CASCADE
);

-- Exemplo de inserção de alunos
INSERT IGNORE INTO Alunos (nome, email, matricula) 
VALUES 
    ('Carlos Silva', 'carlos@email.com', '20241001'), 
    ('Ana Souza', 'ana@email.com', '20241002'), 
    ('Bruno Santos', 'bruno@email.com', '20241003'), 
    ('Mariana Lima', 'mariana@email.com', '20241004');
-- Criando equipes (exemplo)
INSERT INTO Equipes (nome) VALUES ('Equipe Alpha'), ('Equipe Beta');

-- Associando alunos às equipes (máximo de 3 por equipe)
INSERT IGNORE INTO Equipe_Alunos (equipe_id, aluno_id) 
VALUES 
    (1, 1),  -- Será ignorado (já existe)
    (1, 2), 
    (2, 3), 
    (2, 4);

-- Simulando uma tentativa de resposta de uma equipe para uma questão
INSERT INTO Tentativas (equipe_id, questao_id, resposta, status) VALUES
(1, 1, 'Executamos a transação e verificamos que o rollback funcionou corretamente.', 'CORRETA');

-- Log de uma transação realizada na questão
INSERT INTO Logs_Testes (equipe_id, questao_id, evento) VALUES
(1, 1, 'Equipe executou transação ACID e verificou rollback.');