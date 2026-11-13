-- Isola um microsserviço dentro da instância RDS compartilhada: um usuário próprio, dono dos
-- seus bancos, e ninguém mais (PUBLIC) consegue conectar neles. Idempotente.
-- Variáveis psql: role, password, dbs (nomes separados por vírgula).

SELECT format('CREATE ROLE %I LOGIN', :'role')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'role') \gexec

ALTER ROLE :"role" PASSWORD :'password';

-- O usuário master do RDS não é superusuário: precisa ser membro do role para criar bancos em nome dele.
GRANT :"role" TO CURRENT_USER;

SELECT format('CREATE DATABASE %I OWNER %I', d, :'role')
FROM unnest(string_to_array(:'dbs', ',')) AS d
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = d) \gexec

-- Cobre o banco que o próprio RDS cria (db_name), que nasce com o master como dono.
SELECT format('ALTER DATABASE %I OWNER TO %I', d, :'role')
FROM unnest(string_to_array(:'dbs', ',')) AS d \gexec

SELECT format('REVOKE CONNECT ON DATABASE %I FROM PUBLIC', d)
FROM unnest(string_to_array(:'dbs', ',')) AS d \gexec
