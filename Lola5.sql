CREATE TABLE IF NOT EXISTS TesteLock (
    id INT PRIMARY KEY,
    valor INT
);

INSERT IGNORE INTO TesteLock (id, valor) VALUES (1, 100);
-- Sessão 1
START TRANSACTION;
SELECT valor FROM TesteLock WHERE id = 1 LOCK IN SHARE MODE; -- Bloqueio S
-- Suponha que, após lógica condicional, precise modificar:
SELECT valor FROM TesteLock WHERE id = 1 FOR UPDATE; -- Tenta converter para X
UPDATE TesteLock SET valor = 200 WHERE id = 1;
COMMIT;
-- Sessão 2 (executada simultaneamente)
START TRANSACTION;
SELECT valor FROM TesteLock WHERE id = 1 LOCK IN SHARE MODE; -- Bloqueado até a Sessão 1 liberar o X
COMMIT;