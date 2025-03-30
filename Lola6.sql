SET GLOBAL innodb_lock_wait_timeout = 5; -- Timeout de 5 segundos

CREATE TABLE IF NOT EXISTS Contas (
    id INT PRIMARY KEY,
    saldo DECIMAL(10,2)
);

-- Inserir dados de exemplo
INSERT INTO Contas (id, saldo) VALUES (1, 1000.00), (2, 2000.00);

-- Sessão 1 (T1)
START TRANSACTION;
UPDATE Contas SET saldo = saldo - 100 WHERE id = 1; -- Bloqueia linha 1 (X lock)
DO SLEEP(10);  -- Espera 10 segundos para dar tempo de a T2 agir

UPDATE Contas SET saldo = saldo + 100 WHERE id = 2; -- Tenta bloquear linha 2, que T2 já está bloqueando
-- Não COMMIT ainda, mantendo o bloqueio

-- Sessão 2 (T2) - Executar após T1 começar
START TRANSACTION;
UPDATE Contas SET saldo = saldo - 200 WHERE id = 2; -- Bloqueia linha 2 (X lock)
DO SLEEP(10);  -- Espera 10 segundos

UPDATE Contas SET saldo = saldo + 200 WHERE id = 1; -- Tenta bloquear linha 1, que T1 já está bloqueando
-- Não COMMIT ainda, mantendo o bloqueio

-- Sessão 1 - Agora tenta atualizar a linha 2, mas T2 bloqueia a linha
-- Sessão 2 - Agora tenta atualizar a linha 1, mas T1 bloqueia a linha
