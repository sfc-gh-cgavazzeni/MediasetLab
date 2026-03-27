-- ============================================================================
-- MEDIASET SNOWFLAKE WORKSHOP - SETUP
-- Modulo 1: Configurazione ambiente e caricamento dati da CSV
-- Durata: 40 minuti
-- ============================================================================

-- ============================================================================
-- SEZIONE 1: CREAZIONE DATABASE E SCHEMA
-- ============================================================================

-- Best Practice: Usa SYSADMIN per creare database e oggetti
USE ROLE SYSADMIN;

CREATE OR REPLACE DATABASE MEDIASET_LAB;

CREATE OR REPLACE SCHEMA MEDIASET_LAB.RAW;
CREATE OR REPLACE SCHEMA MEDIASET_LAB.ANALYTICS;
CREATE OR REPLACE SCHEMA MEDIASET_LAB.SECURITY;

-- ============================================================================
-- SEZIONE 2: CREAZIONE WAREHOUSE
-- ============================================================================

-- Best Practice: Usa SYSADMIN per creare warehouse
USE ROLE SYSADMIN;

CREATE OR REPLACE WAREHOUSE MEDIASET_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse per il laboratorio Mediaset';

-- ============================================================================
-- SEZIONE 3: CREAZIONE RUOLI E PERMESSI
-- ============================================================================

-- Best Practice: Usa SECURITYADMIN per creare e gestire ruoli
USE ROLE SECURITYADMIN;

CREATE OR REPLACE ROLE MEDIASET_ADMIN;
CREATE OR REPLACE ROLE MEDIASET_ANALYST;
CREATE OR REPLACE ROLE MEDIASET_MARKETING;
CREATE OR REPLACE ROLE MEDIASET_REGIONALE_NORD;
CREATE OR REPLACE ROLE MEDIASET_REGIONALE_SUD;

-- BEST PRACTICE: Tutti i ruoli custom devono riportare a SYSADMIN
-- Questo garantisce che SYSADMIN possa gestire tutti gli oggetti creati da questi ruoli
GRANT ROLE MEDIASET_ADMIN TO ROLE SYSADMIN;
GRANT ROLE MEDIASET_ANALYST TO ROLE SYSADMIN;
GRANT ROLE MEDIASET_MARKETING TO ROLE SYSADMIN;
GRANT ROLE MEDIASET_REGIONALE_NORD TO ROLE SYSADMIN;
GRANT ROLE MEDIASET_REGIONALE_SUD TO ROLE SYSADMIN;

-- Gerarchia interna dei ruoli Mediaset
GRANT ROLE MEDIASET_ANALYST TO ROLE MEDIASET_ADMIN;
GRANT ROLE MEDIASET_MARKETING TO ROLE MEDIASET_ADMIN;
GRANT ROLE MEDIASET_REGIONALE_NORD TO ROLE MEDIASET_ANALYST;
GRANT ROLE MEDIASET_REGIONALE_SUD TO ROLE MEDIASET_ANALYST;

-- Torna a SYSADMIN per assegnare i permessi sugli oggetti
USE ROLE SYSADMIN;

GRANT USAGE ON DATABASE MEDIASET_LAB TO ROLE MEDIASET_ADMIN;
GRANT USAGE ON DATABASE MEDIASET_LAB TO ROLE MEDIASET_ANALYST;
GRANT USAGE ON DATABASE MEDIASET_LAB TO ROLE MEDIASET_MARKETING;
GRANT USAGE ON DATABASE MEDIASET_LAB TO ROLE MEDIASET_REGIONALE_NORD;
GRANT USAGE ON DATABASE MEDIASET_LAB TO ROLE MEDIASET_REGIONALE_SUD;

GRANT USAGE ON ALL SCHEMAS IN DATABASE MEDIASET_LAB TO ROLE MEDIASET_ADMIN;
GRANT USAGE ON ALL SCHEMAS IN DATABASE MEDIASET_LAB TO ROLE MEDIASET_ANALYST;
GRANT USAGE ON ALL SCHEMAS IN DATABASE MEDIASET_LAB TO ROLE MEDIASET_MARKETING;
GRANT USAGE ON ALL SCHEMAS IN DATABASE MEDIASET_LAB TO ROLE MEDIASET_REGIONALE_NORD;
GRANT USAGE ON ALL SCHEMAS IN DATABASE MEDIASET_LAB TO ROLE MEDIASET_REGIONALE_SUD;

GRANT USAGE ON WAREHOUSE MEDIASET_WH TO ROLE MEDIASET_ADMIN;
GRANT USAGE ON WAREHOUSE MEDIASET_WH TO ROLE MEDIASET_ANALYST;
GRANT USAGE ON WAREHOUSE MEDIASET_WH TO ROLE MEDIASET_MARKETING;
GRANT USAGE ON WAREHOUSE MEDIASET_WH TO ROLE MEDIASET_REGIONALE_NORD;
GRANT USAGE ON WAREHOUSE MEDIASET_WH TO ROLE MEDIASET_REGIONALE_SUD;

GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE MEDIASET_LAB TO ROLE MEDIASET_ADMIN;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MEDIASET_LAB.RAW TO ROLE MEDIASET_ANALYST;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MEDIASET_LAB.ANALYTICS TO ROLE MEDIASET_ANALYST;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MEDIASET_LAB.RAW TO ROLE MEDIASET_MARKETING;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MEDIASET_LAB.ANALYTICS TO ROLE MEDIASET_MARKETING;

-- ============================================================================
-- SEZIONE 4: CREAZIONE TABELLE
-- ============================================================================

USE SCHEMA MEDIASET_LAB.RAW;

CREATE OR REPLACE TABLE PROGRAMMI_TV (
    programma_id INT,
    titolo VARCHAR(200),
    genere VARCHAR(50),
    canale VARCHAR(50),
    durata_minuti INT,
    anno_prima_messa_in_onda INT,
    produzione VARCHAR(100),
    target_eta VARCHAR(50),
    costo_episodio_eur DECIMAL(12,2),
    rating_contenuto VARCHAR(10)
);

CREATE OR REPLACE TABLE PALINSESTO (
    palinsesto_id INT,
    programma_id INT,
    data_trasmissione DATE,
    ora_inizio TIME,
    ora_fine TIME,
    canale VARCHAR(50),
    tipo_trasmissione VARCHAR(50),
    stagione INT,
    episodio INT
);

CREATE OR REPLACE TABLE ASCOLTI (
    ascolto_id INT,
    palinsesto_id INT,
    programma_id INT,
    data_rilevazione DATE,
    fascia_oraria VARCHAR(50),
    regione VARCHAR(50),
    telespettatori INT,
    share_percentuale DECIMAL(5,2),
    target_commerciale VARCHAR(50),
    dispositivo VARCHAR(50)
);

CREATE OR REPLACE TABLE ABBONATI (
    abbonato_id INT,
    nome VARCHAR(100),
    cognome VARCHAR(100),
    email VARCHAR(200),
    telefono VARCHAR(20),
    citta VARCHAR(100),
    regione VARCHAR(50),
    cap VARCHAR(10),
    data_iscrizione DATE,
    tipo_abbonamento VARCHAR(50),
    importo_mensile DECIMAL(8,2),
    stato_abbonamento VARCHAR(20),
    canali_preferiti VARCHAR(500)
);

CREATE OR REPLACE TABLE CONTENUTI_DESCRIZIONI (
    contenuto_id INT,
    programma_id INT,
    titolo VARCHAR(200),
    descrizione_breve VARCHAR(500),
    descrizione_completa TEXT,
    parole_chiave VARCHAR(500),
    cast_principale VARCHAR(500),
    regista VARCHAR(200),
    anno_produzione INT,
    paese_origine VARCHAR(100),
    lingua_originale VARCHAR(50),
    sottotitoli_disponibili VARCHAR(200)
);

CREATE OR REPLACE TABLE CONTRATTI_PUBBLICITARI (
    contratto_id INT,
    inserzionista VARCHAR(200),
    agenzia VARCHAR(200),
    data_inizio DATE,
    data_fine DATE,
    budget_totale_eur DECIMAL(15,2),
    canale_target VARCHAR(100),
    fascia_oraria_target VARCHAR(50),
    tipo_campagna VARCHAR(100),
    settore_merceologico VARCHAR(100),
    referente_nome VARCHAR(100),
    referente_email VARCHAR(200),
    stato_contratto VARCHAR(50)
);

CREATE OR REPLACE TABLE FEEDBACK_SOCIAL (
    feedback_id INT,
    programma_id INT,
    data_feedback TIMESTAMP,
    piattaforma VARCHAR(50),
    testo_feedback TEXT,
    username VARCHAR(100),
    likes INT,
    shares INT
);

-- ============================================================================
-- SEZIONE 5: CARICAMENTO DATI DA FILE CSV (via Snowsight)
-- ============================================================================

-- I dati per le tabelle sono forniti come file CSV nella cartella "data/".
-- Per caricare i dati, segui questi passaggi per OGNI tabella:
--
-- ISTRUZIONI PASSO-PASSO:
--
-- 1. Nel menu laterale di Snowsight, clicca su "Data" > "Databases"
-- 2. Naviga fino allo schema: MEDIASET_LAB > RAW
-- 3. Clicca sulla tabella da popolare (es. PROGRAMMI_TV)
-- 4. In alto a destra, clicca sul pulsante "Load Data"
-- 5. Seleziona il warehouse MEDIASET_WH
-- 6. Clicca su "Browse" e seleziona il file CSV corrispondente dalla cartella data/
-- 7. Nelle opzioni del File Format:
--    - File Type: CSV
--    - Header: seleziona "First line contains header"
--    - Field delimiter: virgola (,)
--    - Field optionally enclosed by: doppio apice (")
-- 8. Clicca su "Load" per avviare il caricamento
-- 9. Verifica che il numero di righe caricate corrisponda a quello atteso
--
-- ORDINE DI CARICAMENTO E RIGHE ATTESE:
--
-- | #  | Tabella                 | File CSV                      | Righe |
-- |----|-------------------------|-------------------------------|-------|
-- | 1  | PROGRAMMI_TV            | data/PROGRAMMI_TV.csv         |    20 |
-- | 2  | PALINSESTO              | data/PALINSESTO.csv           |   600 |
-- | 3  | ASCOLTI                 | data/ASCOLTI.csv              |  5000 |
-- | 4  | ABBONATI                | data/ABBONATI.csv             |    20 |
-- | 5  | CONTENUTI_DESCRIZIONI   | data/CONTENUTI_DESCRIZIONI.csv|    20 |
-- | 6  | CONTRATTI_PUBBLICITARI  | data/CONTRATTI_PUBBLICITARI.csv|   15 |
-- | 7  | FEEDBACK_SOCIAL         | data/FEEDBACK_SOCIAL.csv      |    20 |
--
-- NOTA: Carica le tabelle nell'ordine indicato sopra.
--       PROGRAMMI_TV deve essere caricata per prima perché altre tabelle
--       (PALINSESTO, ASCOLTI, CONTENUTI_DESCRIZIONI, FEEDBACK_SOCIAL)
--       contengono riferimenti al campo programma_id.

-- ============================================================================
-- SEZIONE 5b: VERIFICA CARICAMENTO DATI
-- ============================================================================

-- Dopo aver caricato tutti i CSV, esegui queste query per verificare
-- che i dati siano stati importati correttamente:

SELECT 'PROGRAMMI_TV' as tabella, COUNT(*) as righe FROM MEDIASET_LAB.RAW.PROGRAMMI_TV
UNION ALL
SELECT 'PALINSESTO', COUNT(*) FROM MEDIASET_LAB.RAW.PALINSESTO
UNION ALL
SELECT 'ASCOLTI', COUNT(*) FROM MEDIASET_LAB.RAW.ASCOLTI
UNION ALL
SELECT 'ABBONATI', COUNT(*) FROM MEDIASET_LAB.RAW.ABBONATI
UNION ALL
SELECT 'CONTENUTI_DESCRIZIONI', COUNT(*) FROM MEDIASET_LAB.RAW.CONTENUTI_DESCRIZIONI
UNION ALL
SELECT 'CONTRATTI_PUBBLICITARI', COUNT(*) FROM MEDIASET_LAB.RAW.CONTRATTI_PUBBLICITARI
UNION ALL
SELECT 'FEEDBACK_SOCIAL', COUNT(*) FROM MEDIASET_LAB.RAW.FEEDBACK_SOCIAL
ORDER BY tabella;

-- Risultato atteso:
-- ABBONATI                 20
-- ASCOLTI                5000
-- CONTENUTI_DESCRIZIONI    20
-- CONTRATTI_PUBBLICITARI   15
-- FEEDBACK_SOCIAL          20
-- PALINSESTO              600
-- PROGRAMMI_TV             20

-- Verifica un campione di dati per ogni tabella
SELECT * FROM MEDIASET_LAB.RAW.PROGRAMMI_TV LIMIT 3;
SELECT * FROM MEDIASET_LAB.RAW.PALINSESTO LIMIT 3;
SELECT * FROM MEDIASET_LAB.RAW.ASCOLTI LIMIT 3;
SELECT * FROM MEDIASET_LAB.RAW.ABBONATI LIMIT 3;
SELECT * FROM MEDIASET_LAB.RAW.CONTENUTI_DESCRIZIONI LIMIT 3;
SELECT * FROM MEDIASET_LAB.RAW.CONTRATTI_PUBBLICITARI LIMIT 3;
SELECT * FROM MEDIASET_LAB.RAW.FEEDBACK_SOCIAL LIMIT 3;

-- ============================================================================
-- SEZIONE 5c: ESEMPIO - CARICAMENTO DATI DA STAGE S3 PUBBLICO
-- ============================================================================

-- Oltre al caricamento manuale via Snowsight (Sezione 5), Snowflake permette
-- di caricare dati direttamente da bucket S3 pubblici utilizzando uno STAGE esterno.
-- Questo approccio è ideale per automatizzare l'ingestion di dati e per lavorare
-- con dataset di grandi dimensioni senza doverli prima scaricare in locale.
--
-- In questo esempio utilizziamo il dataset Citibike Trips, ospitato in un bucket
-- S3 pubblico di Snowflake (s3://snowflake-workshop-lab/citibike-trips-csv/).
-- Il bucket è pubblicamente accessibile e non richiede credenziali AWS.

USE ROLE SYSADMIN;
USE SCHEMA MEDIASET_LAB.RAW;
USE WAREHOUSE MEDIASET_WH;

-- Passo 1: Creare un file format per i CSV compressi (gzip)
-- I file nel bucket sono CSV senza riga di intestazione, compressi con gzip.
CREATE OR REPLACE FILE FORMAT MEDIASET_LAB.RAW.CSV_GZIP_FORMAT
    TYPE = 'CSV'
    COMPRESSION = 'GZIP'
    FIELD_DELIMITER = ','
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 0;

-- Passo 2: Creare uno stage esterno che punta al bucket S3 pubblico
-- Non servono credenziali perché il bucket è ad accesso pubblico.
CREATE OR REPLACE STAGE MEDIASET_LAB.RAW.CITIBIKE_STAGE
    URL = 's3://snowflake-workshop-lab/citibike-trips-csv/'
    FILE_FORMAT = MEDIASET_LAB.RAW.CSV_GZIP_FORMAT;

-- Passo 3: Verificare che lo stage sia raggiungibile e i file siano visibili
LIST @MEDIASET_LAB.RAW.CITIBIKE_STAGE;

-- Passo 4: Creare la tabella di destinazione con lo schema del dataset
CREATE OR REPLACE TABLE MEDIASET_LAB.RAW.CITIBIKE_TRIPS (
    TRIP_ID             INT,
    STARTTIME           TIMESTAMP,
    STOPTIME            TIMESTAMP,
    TRIPDURATION_MIN    INT,
    START_STATION_ID    INT,
    END_STATION_ID      INT,
    BIKEID              VARCHAR(20),
    BIKE_TYPE           VARCHAR(20),
    USER_ID             INT,
    USER_NAME           VARCHAR(100),
    BIRTH_DATE          DATE,
    GENDER              VARCHAR(10),
    USER_TYPE           VARCHAR(50),
    PAYMENT_METHOD      VARCHAR(20),
    PAYMENT_PROVIDER    VARCHAR(20)
);

-- Passo 5: Caricare i dati dallo stage alla tabella con COPY INTO
-- Limitiamo il caricamento a un singolo file per velocizzare l'esempio.
COPY INTO MEDIASET_LAB.RAW.CITIBIKE_TRIPS
    FROM @MEDIASET_LAB.RAW.CITIBIKE_STAGE
    PATTERN = '.*data_0_1_0.csv.gz'
    ON_ERROR = 'CONTINUE';

-- Passo 6: Verificare il caricamento
SELECT COUNT(*) AS righe_caricate FROM MEDIASET_LAB.RAW.CITIBIKE_TRIPS;
SELECT * FROM MEDIASET_LAB.RAW.CITIBIKE_TRIPS LIMIT 5;

-- ============================================================================
-- SEZIONE 6: GRANT FINALI SULLE TABELLE
-- ============================================================================

GRANT SELECT ON ALL TABLES IN SCHEMA MEDIASET_LAB.RAW TO ROLE MEDIASET_ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA MEDIASET_LAB.RAW TO ROLE MEDIASET_MARKETING;
GRANT SELECT ON ALL TABLES IN SCHEMA MEDIASET_LAB.RAW TO ROLE MEDIASET_REGIONALE_NORD;
GRANT SELECT ON ALL TABLES IN SCHEMA MEDIASET_LAB.RAW TO ROLE MEDIASET_REGIONALE_SUD;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA MEDIASET_LAB.RAW TO ROLE MEDIASET_ADMIN;

-- ============================================================================
-- ESERCIZI MODULO 1
-- ============================================================================

-- ESERCIZIO 1.1: Verifica la struttura del database
SHOW DATABASES LIKE 'MEDIASET%';
SHOW SCHEMAS IN DATABASE MEDIASET_LAB;
SHOW TABLES IN SCHEMA MEDIASET_LAB.RAW;

-- ESERCIZIO 1.2: Query di base sui programmi
SELECT * FROM MEDIASET_LAB.RAW.PROGRAMMI_TV ORDER BY costo_episodio_eur DESC LIMIT 5;

-- ESERCIZIO 1.3: Analisi degli ascolti per regione
SELECT 
    regione,
    COUNT(*) as num_rilevazioni,
    AVG(telespettatori) as media_telespettatori,
    AVG(share_percentuale) as share_medio
FROM MEDIASET_LAB.RAW.ASCOLTI
GROUP BY regione
ORDER BY share_medio DESC;

-- ESERCIZIO 1.4: Join tra programmi e ascolti
SELECT 
    p.titolo,
    p.genere,
    p.canale,
    AVG(a.share_percentuale) as share_medio,
    SUM(a.telespettatori) as telespettatori_totali
FROM MEDIASET_LAB.RAW.PROGRAMMI_TV p
JOIN MEDIASET_LAB.RAW.ASCOLTI a ON p.programma_id = a.programma_id
GROUP BY p.titolo, p.genere, p.canale
ORDER BY share_medio DESC
LIMIT 10;

-- ESERCIZIO 1.5: Verifica dei ruoli creati
SHOW ROLES LIKE 'MEDIASET%';

-- ESERCIZIO 1.6: Elasticità del Warehouse
-- Snowflake permette di ridimensionare un warehouse in pochi secondi,
-- senza interruzioni per le query in corso. Prova a scalare da XSMALL a MEDIUM
-- e osserva il tempo di esecuzione del comando.

ALTER WAREHOUSE MEDIASET_WH SET WAREHOUSE_SIZE = 'MEDIUM';

-- NOTA: Osserva il tempo di esecuzione nell'output della query.
-- Il ridimensionamento è quasi istantaneo — questa è una delle caratteristiche
-- chiave dell'architettura cloud-native di Snowflake.

-- Torna alla size precedente per risparmiare crediti
ALTER WAREHOUSE MEDIASET_WH SET WAREHOUSE_SIZE = 'XSMALL';

-- BEST PRACTICE: Usa la size minima necessaria per il carico di lavoro.
-- Scala verso l'alto solo quando servono prestazioni maggiori,
-- e ricorda sempre di tornare alla size originale al termine.
