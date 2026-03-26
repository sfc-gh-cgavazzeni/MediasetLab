-- ============================================================================
-- MEDIASET SNOWFLAKE WORKSHOP - SECURITY
-- Modulo 2: Row-Level Security e Column-Level Masking
-- Durata: 35 minuti
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE MEDIASET_LAB;
USE SCHEMA SECURITY;
USE WAREHOUSE MEDIASET_WH;

-- ============================================================================
-- SEZIONE 1: COLUMN-LEVEL MASKING (Data Masking)
-- ============================================================================

-- Creiamo una masking policy per nascondere l'email agli utenti non autorizzati
CREATE OR REPLACE MASKING POLICY email_mask AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') THEN val
        WHEN CURRENT_ROLE() = 'MEDIASET_MARKETING' THEN 
            REGEXP_REPLACE(val, '(.{2})(.*)(@.*)', '\\1***\\3')
        ELSE '***RISERVATO***'
    END;

-- Creiamo una masking policy per il numero di telefono
CREATE OR REPLACE MASKING POLICY telefono_mask AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') THEN val
        WHEN CURRENT_ROLE() = 'MEDIASET_MARKETING' THEN 
            CONCAT(LEFT(val, 6), ' *** ***')
        ELSE '***-***-****'
    END;

-- Creiamo una masking policy per importi finanziari
CREATE OR REPLACE MASKING POLICY importo_mask AS (val DECIMAL(8,2)) RETURNS DECIMAL(8,2) ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') THEN val
        WHEN CURRENT_ROLE() = 'MEDIASET_ANALYST' THEN 
            ROUND(val / 10, 2) * 10
        ELSE NULL
    END;

-- Applichiamo le masking policy alla tabella ABBONATI
ALTER TABLE MEDIASET_LAB.RAW.ABBONATI 
    MODIFY COLUMN email SET MASKING POLICY email_mask;

ALTER TABLE MEDIASET_LAB.RAW.ABBONATI 
    MODIFY COLUMN telefono SET MASKING POLICY telefono_mask;

ALTER TABLE MEDIASET_LAB.RAW.ABBONATI 
    MODIFY COLUMN importo_mensile SET MASKING POLICY importo_mask;

-- ============================================================================
-- SEZIONE 2: ROW ACCESS POLICY (Row-Level Security)
-- ============================================================================

-- Creiamo una tabella di mapping per definire quali regioni può vedere ogni ruolo
CREATE OR REPLACE TABLE MEDIASET_LAB.SECURITY.ROLE_REGION_MAPPING (
    role_name VARCHAR(100),
    regione VARCHAR(50)
);

INSERT INTO MEDIASET_LAB.SECURITY.ROLE_REGION_MAPPING VALUES
('MEDIASET_REGIONALE_NORD', 'Lombardia'),
('MEDIASET_REGIONALE_NORD', 'Piemonte'),
('MEDIASET_REGIONALE_NORD', 'Veneto'),
('MEDIASET_REGIONALE_NORD', 'Emilia-Romagna'),
('MEDIASET_REGIONALE_NORD', 'Liguria'),
('MEDIASET_REGIONALE_NORD', 'Friuli-Venezia Giulia'),
('MEDIASET_REGIONALE_NORD', 'Trentino-Alto Adige'),
('MEDIASET_REGIONALE_SUD', 'Campania'),
('MEDIASET_REGIONALE_SUD', 'Sicilia'),
('MEDIASET_REGIONALE_SUD', 'Puglia'),
('MEDIASET_REGIONALE_SUD', 'Calabria'),
('MEDIASET_REGIONALE_SUD', 'Sardegna'),
('MEDIASET_REGIONALE_SUD', 'Basilicata'),
('MEDIASET_REGIONALE_SUD', 'Molise'),
('MEDIASET_REGIONALE_SUD', 'Abruzzo');

GRANT SELECT ON TABLE MEDIASET_LAB.SECURITY.ROLE_REGION_MAPPING TO ROLE MEDIASET_REGIONALE_NORD;
GRANT SELECT ON TABLE MEDIASET_LAB.SECURITY.ROLE_REGION_MAPPING TO ROLE MEDIASET_REGIONALE_SUD;

-- Creiamo la Row Access Policy per filtrare i dati per regione
CREATE OR REPLACE ROW ACCESS POLICY region_access_policy AS (regione_col VARCHAR) RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN', 'MEDIASET_ANALYST') THEN TRUE
        WHEN CURRENT_ROLE() = 'MEDIASET_MARKETING' THEN TRUE
        WHEN EXISTS (
            SELECT 1 
            FROM MEDIASET_LAB.SECURITY.ROLE_REGION_MAPPING 
            WHERE role_name = CURRENT_ROLE() 
            AND regione = regione_col
        ) THEN TRUE
        ELSE FALSE
    END;

-- Applichiamo la Row Access Policy alla tabella ASCOLTI
ALTER TABLE MEDIASET_LAB.RAW.ASCOLTI 
    ADD ROW ACCESS POLICY region_access_policy ON (regione);

-- Applichiamo la Row Access Policy anche alla tabella ABBONATI
ALTER TABLE MEDIASET_LAB.RAW.ABBONATI 
    ADD ROW ACCESS POLICY region_access_policy ON (regione);

-- ============================================================================
-- SEZIONE 3: TEST DELLE POLICY
-- ============================================================================

-- Test 1: Verifica masking con ruolo ADMIN
USE ROLE MEDIASET_ADMIN;
SELECT abbonato_id, nome, cognome, email, telefono, importo_mensile, regione
FROM MEDIASET_LAB.RAW.ABBONATI
LIMIT 5;

-- Test 2: Verifica masking con ruolo MARKETING
USE ROLE MEDIASET_MARKETING;
SELECT abbonato_id, nome, cognome, email, telefono, importo_mensile, regione
FROM MEDIASET_LAB.RAW.ABBONATI
LIMIT 5;

-- Test 3: Verifica masking con ruolo ANALYST
USE ROLE MEDIASET_ANALYST;
SELECT abbonato_id, nome, cognome, email, telefono, importo_mensile, regione
FROM MEDIASET_LAB.RAW.ABBONATI
LIMIT 5;

-- Test 4: Verifica Row Access Policy con ruolo REGIONALE_NORD
USE ROLE MEDIASET_REGIONALE_NORD;
SELECT regione, COUNT(*) as num_rilevazioni
FROM MEDIASET_LAB.RAW.ASCOLTI
GROUP BY regione;

-- Test 5: Verifica Row Access Policy con ruolo REGIONALE_SUD
USE ROLE MEDIASET_REGIONALE_SUD;
SELECT regione, COUNT(*) as num_rilevazioni
FROM MEDIASET_LAB.RAW.ASCOLTI
GROUP BY regione;

-- Test 6: Verifica che ANALYST vede tutte le regioni
USE ROLE MEDIASET_ANALYST;
SELECT regione, COUNT(*) as num_rilevazioni
FROM MEDIASET_LAB.RAW.ASCOLTI
GROUP BY regione
ORDER BY regione;

-- ============================================================================
-- SEZIONE 4: GESTIONE AVANZATA DELLE POLICY
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Visualizza tutte le masking policy
SHOW MASKING POLICIES IN SCHEMA MEDIASET_LAB.SECURITY;

-- Visualizza tutte le row access policy
SHOW ROW ACCESS POLICIES IN SCHEMA MEDIASET_LAB.SECURITY;

-- Visualizza quali colonne hanno masking policy applicate
SELECT * FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
    POLICY_NAME => 'MEDIASET_LAB.SECURITY.EMAIL_MASK'
));

-- ============================================================================
-- ESERCIZI MODULO 2
-- ============================================================================

-- ESERCIZIO 2.1: Crea una nuova masking policy per il campo 'cognome'
-- che mostri solo l'iniziale seguita da asterischi per i ruoli non admin
-- Esempio: 'Rossi' -> 'R****'

-- Soluzione:
CREATE OR REPLACE MASKING POLICY cognome_mask AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') THEN val
        ELSE CONCAT(LEFT(val, 1), REPEAT('*', LENGTH(val) - 1))
    END;

-- ESERCIZIO 2.2: Testa la policy con diversi ruoli
-- (Prova ad applicarla e poi rimuoverla)

-- Per applicare:
-- ALTER TABLE MEDIASET_LAB.RAW.ABBONATI 
--     MODIFY COLUMN cognome SET MASKING POLICY cognome_mask;

-- Per rimuovere:
-- ALTER TABLE MEDIASET_LAB.RAW.ABBONATI 
--     MODIFY COLUMN cognome UNSET MASKING POLICY;

-- ESERCIZIO 2.3: Verifica l'impatto delle policy sulle performance
-- Esegui la stessa query con e senza policy e confronta i tempi
USE ROLE MEDIASET_ANALYST;
SELECT COUNT(*), AVG(importo_mensile) 
FROM MEDIASET_LAB.RAW.ABBONATI;

-- ESERCIZIO 2.4: Crea una row access policy basata sul tipo di abbonamento
-- Solo gli admin possono vedere gli abbonati "Premium Plus"

-- Soluzione:
CREATE OR REPLACE ROW ACCESS POLICY premium_access_policy AS (tipo_abb VARCHAR) RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') THEN TRUE
        WHEN tipo_abb = 'Premium Plus' THEN FALSE
        ELSE TRUE
    END;

-- Nota: Per applicarla, dovresti prima rimuovere altre policy sulla stessa tabella
-- o creare una nuova tabella di test
