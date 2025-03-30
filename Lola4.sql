-- Criar banco de dados e tabelas
CREATE DATABASE IF NOT EXISTS BancoTeste;
USE BancoTeste;

-- Tabela de clientes
CREATE TABLE IF NOT EXISTS Clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    data_nascimento DATE NOT NULL,
    endereco TEXT
);

-- Tabela de agências bancárias
CREATE TABLE IF NOT EXISTS Agencias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    endereco TEXT NOT NULL
);

-- Tabela de contas bancárias
CREATE TABLE IF NOT EXISTS Contas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    agencia_id INT NOT NULL,
    tipo ENUM('CORRENTE', 'POUPANCA') NOT NULL,
    saldo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status ENUM('ATIVA', 'BLOQUEADA', 'ENCERRADA') DEFAULT 'ATIVA',
    FOREIGN KEY (cliente_id) REFERENCES Clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (agencia_id) REFERENCES Agencias(id) ON DELETE CASCADE
);

-- Tabela de transações
CREATE TABLE IF NOT EXISTS Transacoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    conta_origem INT NOT NULL,
    conta_destino INT DEFAULT NULL,
    tipo ENUM('DEPOSITO', 'SAQUE', 'TRANSFERENCIA', 'PAGAMENTO') NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    data_transacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('PENDENTE', 'CONFIRMADA', 'CANCELADA') DEFAULT 'PENDENTE',
    FOREIGN KEY (conta_origem) REFERENCES Contas(id) ON DELETE CASCADE,
    FOREIGN KEY (conta_destino) REFERENCES Contas(id) ON DELETE CASCADE
);

-- Tabela de logs de transações
CREATE TABLE IF NOT EXISTS Logs_Transacoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transacao_id INT NOT NULL,
    evento VARCHAR(255) NOT NULL,
    data_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transacao_id) REFERENCES Transacoes(id) ON DELETE CASCADE
);

-- Populando tabelas (com tratamento para evitar duplicatas)
INSERT IGNORE INTO Clientes (nome, cpf, data_nascimento, endereco) VALUES
('Alice Silva', '111.222.333-44', '1985-07-15', 'Rua A, 123'),
('Bruno Costa', '222.333.444-55', '1990-08-20', 'Rua B, 456'),
('Carla Souza', '333.444.555-66', '1995-09-25', 'Rua C, 789');

INSERT IGNORE INTO Agencias (nome, endereco) VALUES
('Agência Centro', 'Av. Principal, 1000'),
('Agência Sul', 'Rua Secundária, 200');

INSERT IGNORE INTO Contas (cliente_id, agencia_id, tipo, saldo) VALUES
(1, 1, 'CORRENTE', 1000.00),
(2, 1, 'POUPANCA', 1500.00),
(3, 2, 'CORRENTE', 2000.00);
 -- Transação 1: Bloqueio Exclusivo (X) para modificar o saldo
START TRANSACTION;
SELECT saldo FROM Contas WHERE id = 1 FOR UPDATE; -- Bloqueio X na linha
UPDATE Contas SET saldo = saldo - 100 WHERE id = 1;
COMMIT;

-- Transação 2: Bloqueio Compartilhado (S) para ler o saldo
START TRANSACTION;
SELECT saldo FROM Contas WHERE id = 1 LOCK IN SHARE MODE; -- Bloqueio S
COMMIT;