CREATE TABLE IF NOT EXISTS TesteTO (
    id INT PRIMARY KEY,
    valor INT,
    read_ts INT DEFAULT 0,
    write_ts INT DEFAULT 0
);

INSERT INTO TesteTO (id, valor) VALUES (1, 100);
-- Transação T1 (TS=100)
SET @ts1 = 100;
START TRANSACTION;

-- T1 lê o valor e atualiza read_ts
SELECT valor FROM TesteTO WHERE id = 1;
UPDATE TesteTO SET read_ts = GREATEST(read_ts, @ts1) WHERE id = 1;

-- Simular processamento...
DO SLEEP(2);

-- T1 tenta escrever (TS=100 vs write_ts=0)
UPDATE TesteTO 
SET valor = 200, write_ts = @ts1 
WHERE id = 1 AND write_ts < @ts1;

COMMIT;
-- Transação T2 (TS=200) - Executar em outra sessão
SET @ts2 = 200;
START TRANSACTION;

-- T2 lê o valor e atualiza read_ts
SELECT valor FROM TesteTO WHERE id = 1;
UPDATE TesteTO SET read_ts = GREATEST(read_ts, @ts2) WHERE id = 1;

-- Simular processamento...
DO SLEEP(1);

-- T2 tenta escrever (TS=200 vs write_ts=100)
UPDATE TesteTO 
SET valor = 300, write_ts = @ts2 
WHERE id = 1 AND write_ts < @ts2;

COMMIT;