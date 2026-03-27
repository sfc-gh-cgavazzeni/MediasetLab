-- =============================================================
-- MODULO 3: Row & Column Level Security (30 min)
-- =============================================================
-- Le Masking Policy nascondono o offuscano dati sensibili (PII)
-- a livello di colonna in base al ruolo dell'utente.
-- Le Row Access Policy filtrano automaticamente le righe
-- visibili, garantendo che ogni utente veda solo i dati di
-- sua competenza senza modificare le query.
-- =============================================================

-- =============================================================
-- Step 3.1: Tag-Based Masking Policy per Email
-- =============================================================
-- I Tag in Snowflake sono metadati che si associano a oggetti
-- e colonne per classificarli. Sono fondamentali sia per la
-- governance (identificare dati sensibili come PII, PHI, PCI)
-- sia per il cost allocation (tracciare l'utilizzo delle risorse
-- per business unit o progetto tramite i tag sui warehouse).
-- Associando una masking policy a un tag, ogni colonna taggata
-- viene automaticamente protetta.

USE ROLE ACCOUNTADMIN;
USE SCHEMA MEDIASET_LAB.SECURITY;

-- Passo 1: Creare un tag per classificare le colonne contenenti email
CREATE OR REPLACE TAG MEDIASET_LAB.SECURITY.PII_TYPE
    ALLOWED_VALUES 'EMAIL', 'TELEFONO', 'NOME', 'INDIRIZZO'
    COMMENT = 'Classifica il tipo di dato personale (PII) contenuto nella colonna';

-- Passo 2: Creare la masking policy per email
CREATE OR REPLACE MASKING POLICY email_mask AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') THEN val
        WHEN CURRENT_ROLE() = 'MEDIASET_MARKETING' THEN
            REGEXP_REPLACE(val, '(.{2})(.*)(@.*)', '\\1***\\3')
        ELSE '***RISERVATO***'
    END;

-- Passo 3: Associare la masking policy al tag
-- Ogni colonna che ricevera il tag PII_TYPE = 'EMAIL' sara automaticamente mascherata
ALTER TAG MEDIASET_LAB.SECURITY.PII_TYPE
    SET MASKING POLICY email_mask;

-- Passo 4: Assegnare il tag alla colonna email della tabella ABBONATI
ALTER TABLE MEDIASET_LAB.RAW.ABBONATI
    MODIFY COLUMN email SET TAG MEDIASET_LAB.SECURITY.PII_TYPE = 'EMAIL';

-- Vantaggi del Tag-Based Masking:
-- - Scalabilita: basta assegnare il tag a nuove colonne email
-- - Governance centralizzata: tutti i dati PII sono catalogati tramite i tag
-- - Cost allocation: i tag sui warehouse permettono di attribuire i costi

-- =============================================================
-- Step 3.2: Verifica del Tag e della Policy
-- =============================================================

-- Verifica quali tag sono assegnati alla colonna
SELECT * FROM TABLE(INFORMATION_SCHEMA.TAG_REFERENCES(
    'MEDIASET_LAB.RAW.ABBONATI.EMAIL', 'COLUMN'
));

-- Verifica le masking policy attive
SHOW MASKING POLICIES IN SCHEMA MEDIASET_LAB.SECURITY;

-- =============================================================
-- Step 3.3: Test con Ruoli Diversi
-- =============================================================

-- Test come ADMIN (vede tutto)
USE ROLE MEDIASET_ADMIN;
SELECT nome, cognome, email FROM MEDIASET_LAB.RAW.ABBONATI LIMIT 5;

-- Test come MARKETING (vede parzialmente)
USE ROLE MEDIASET_MARKETING;
SELECT nome, cognome, email FROM MEDIASET_LAB.RAW.ABBONATI LIMIT 5;

-- Test come ANALYST (vede mascherato)
USE ROLE MEDIASET_ANALYST;
SELECT nome, cognome, email FROM MEDIASET_LAB.RAW.ABBONATI LIMIT 5;

-- =============================================================
-- Step 3.4: Row Access Policy
-- =============================================================

USE ROLE ACCOUNTADMIN;

-- Crea mapping ruolo-regione
CREATE OR REPLACE TABLE MEDIASET_LAB.SECURITY.ROLE_REGION_MAPPING (
    role_name VARCHAR(100),
    regione VARCHAR(50)
);

INSERT INTO MEDIASET_LAB.SECURITY.ROLE_REGION_MAPPING VALUES
('MEDIASET_REGIONALE_NORD', 'Lombardia'),
('MEDIASET_REGIONALE_NORD', 'Piemonte'),
('MEDIASET_REGIONALE_NORD', 'Veneto'),
('MEDIASET_REGIONALE_SUD', 'Campania'),
('MEDIASET_REGIONALE_SUD', 'Sicilia'),
('MEDIASET_REGIONALE_SUD', 'Puglia');

-- Crea la policy
CREATE OR REPLACE ROW ACCESS POLICY region_access_policy
AS (regione_col VARCHAR) RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN', 'MEDIASET_ANALYST') THEN TRUE
        WHEN CURRENT_ROLE() = 'MEDIASET_MARKETING' THEN TRUE
        WHEN EXISTS (
            SELECT 1 FROM MEDIASET_LAB.SECURITY.ROLE_REGION_MAPPING
            WHERE role_name = CURRENT_ROLE() AND regione = regione_col
        ) THEN TRUE
        ELSE FALSE
    END;

-- Applica la policy
ALTER TABLE MEDIASET_LAB.RAW.ASCOLTI
    ADD ROW ACCESS POLICY region_access_policy ON (regione);

-- =============================================================
-- Step 3.5: Test Row Access Policy
-- =============================================================

-- Come REGIONALE_NORD vedo solo regioni del nord
USE ROLE MEDIASET_REGIONALE_NORD;
SELECT DISTINCT regione FROM MEDIASET_LAB.RAW.ASCOLTI;

-- Come REGIONALE_SUD vedo solo regioni del sud
USE ROLE MEDIASET_REGIONALE_SUD;
SELECT DISTINCT regione FROM MEDIASET_LAB.RAW.ASCOLTI;

-- =============================================================
-- Step 3.6: Aggregation Policy
-- =============================================================
-- Le Aggregation Policy impediscono che una query restituisca
-- risultati basati su un numero troppo piccolo di record,
-- proteggendo contro la re-identificazione di individui.
-- Sono utili quando si condividono dati aggregati con ruoli
-- che non devono poter isolare singoli record.

USE ROLE ACCOUNTADMIN;
USE SCHEMA MEDIASET_LAB.SECURITY;

-- Creare una aggregation policy che richiede almeno 5 record per gruppo
-- Se una query restituisce un gruppo con meno di 5 righe, il risultato viene bloccato
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

-- Test della Aggregation Policy:

-- Come ANALYST, le query aggregate funzionano normalmente
USE ROLE MEDIASET_ANALYST;
SELECT regione, COUNT(*) as num_abbonati, AVG(importo_mensile) as media_importo
FROM MEDIASET_LAB.RAW.ABBONATI
GROUP BY regione;

-- Ma una query senza aggregazione o con gruppi troppo piccoli viene bloccata
-- Questa query fallira perche tenta di accedere a righe individuali:
-- SELECT * FROM MEDIASET_LAB.RAW.ABBONATI LIMIT 5;

-- Come ADMIN, nessuna restrizione
USE ROLE MEDIASET_ADMIN;
SELECT * FROM MEDIASET_LAB.RAW.ABBONATI LIMIT 5;

-- Nota: Le aggregation policy sono particolarmente utili in scenari
-- di data sharing, dove si vuole garantire che i consumatori possano
-- solo analizzare dati aggregati senza mai accedere a record individuali.

-- =============================================================
-- Esercizio Pratico 3
-- =============================================================
-- Crea una masking policy per il campo telefono che mostri
-- solo le prime 6 cifre ai ruoli non admin.
