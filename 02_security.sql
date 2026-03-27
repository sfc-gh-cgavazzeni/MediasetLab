-- ============================================================================
-- MEDIASET SNOWFLAKE WORKSHOP - SECURITY
-- Modulo 3: Row-Level Security e Column-Level Masking
-- Durata: 30 minuti
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE MEDIASET_LAB;
USE SCHEMA SECURITY;
USE WAREHOUSE MEDIASET_WH;

-- ============================================================================
-- SEZIONE 1: TAG-BASED COLUMN MASKING
-- ============================================================================

-- I Tag in Snowflake sono metadati che si associano a oggetti e colonne.
-- Sono fondamentali sia per la GOVERNANCE (identificare dati sensibili come PII,
-- PHI, PCI) sia per il COST ALLOCATION (tracciare l'utilizzo delle risorse per
-- business unit o progetto tramite tag sui warehouse).
-- Associando una masking policy a un tag, ogni colonna taggata viene
-- automaticamente protetta — senza doverla configurare una per una.

-- Passo 1: Creare un tag per classificare le colonne contenenti PII
CREATE OR REPLACE TAG MEDIASET_LAB.SECURITY.PII_TYPE
    ALLOWED_VALUES = 'EMAIL', 'TELEFONO', 'NOME', 'INDIRIZZO'
    COMMENT = 'Classifica il tipo di dato personale (PII) contenuto nella colonna';

-- Passo 2: Creare le masking policy
CREATE OR REPLACE MASKING POLICY email_mask AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') THEN val
        WHEN CURRENT_ROLE() = 'MEDIASET_MARKETING' THEN 
            REGEXP_REPLACE(val, '(.{2})(.*)(@.*)', '\\1***\\3')
        ELSE '***RISERVATO***'
    END;

CREATE OR REPLACE MASKING POLICY telefono_mask AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') THEN val
        WHEN CURRENT_ROLE() = 'MEDIASET_MARKETING' THEN 
            CONCAT(LEFT(val, 6), ' *** ***')
        ELSE '***-***-****'
    END;

CREATE OR REPLACE MASKING POLICY importo_mask AS (val DECIMAL(8,2)) RETURNS DECIMAL(8,2) ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') THEN val
        WHEN CURRENT_ROLE() = 'MEDIASET_ANALYST' THEN 
            ROUND(val / 10, 2) * 10
        ELSE NULL
    END;

-- Passo 3: Associare le masking policy al tag PII_TYPE
-- Ogni colonna che riceverà il tag sarà automaticamente mascherata
ALTER TAG MEDIASET_LAB.SECURITY.PII_TYPE
    SET MASKING POLICY email_mask;

-- Passo 4: Assegnare il tag alle colonne della tabella ABBONATI
ALTER TABLE MEDIASET_LAB.RAW.ABBONATI
    MODIFY COLUMN email SET TAG MEDIASET_LAB.SECURITY.PII_TYPE = 'EMAIL';

-- Per telefono e importo, applichiamo direttamente (tipi diversi dal tag STRING)
ALTER TABLE MEDIASET_LAB.RAW.ABBONATI 
    MODIFY COLUMN telefono SET MASKING POLICY telefono_mask;

ALTER TABLE MEDIASET_LAB.RAW.ABBONATI 
    MODIFY COLUMN importo_mensile SET MASKING POLICY importo_mask;

-- Verifica quali tag sono assegnati
SELECT * FROM TABLE(INFORMATION_SCHEMA.TAG_REFERENCES(
    'MEDIASET_LAB.RAW.ABBONATI.EMAIL', 'COLUMN'
));

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
-- SEZIONE 3b: AGGREGATION POLICY
-- ============================================================================

-- Le Aggregation Policy impediscono che una query restituisca risultati basati
-- su un numero troppo piccolo di record, proteggendo contro la re-identificazione
-- di individui. Utili in scenari di data sharing dove i consumatori devono poter
-- analizzare solo dati aggregati, senza accedere a record individuali.

USE ROLE ACCOUNTADMIN;
USE SCHEMA MEDIASET_LAB.SECURITY;

-- Creare una aggregation policy che richiede almeno 5 record per gruppo
CREATE OR REPLACE AGGREGATION POLICY min_aggregation_policy
    AS () RETURNS AGGREGATION_CONSTRAINT ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') 
            THEN NO_AGGREGATION_CONSTRAINT()
        ELSE AGGREGATION_CONSTRAINT(MIN_GROUP_SIZE => 5)
    END;

-- Applicare la policy alla tabella ABBONATI
ALTER TABLE MEDIASET_LAB.RAW.ABBONATI
    SET AGGREGATION POLICY min_aggregation_policy;

-- Test: Come ANALYST, le query aggregate funzionano normalmente
USE ROLE MEDIASET_ANALYST;
SELECT regione, COUNT(*) as num_abbonati, AVG(importo_mensile) as media_importo
FROM MEDIASET_LAB.RAW.ABBONATI
GROUP BY regione;

-- Test: Come ADMIN, nessuna restrizione (anche query non aggregate)
USE ROLE MEDIASET_ADMIN;
SELECT * FROM MEDIASET_LAB.RAW.ABBONATI LIMIT 5;

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
