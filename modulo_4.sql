-- =============================================================
-- MODULO 4: Data Pipelines - Dynamic Tables, Streams & Tasks (35 min)
-- =============================================================
-- Le Dynamic Tables sono tabelle che si aggiornano automaticamente
-- quando cambiano i dati sorgente. Definisci la trasformazione SQL
-- una volta e Snowflake gestisce il refresh incrementale.
-- Gli Streams catturano le modifiche (CDC) su una tabella, mentre
-- i Tasks permettono di schedulare operazioni SQL. Insieme, offrono
-- pipeline ETL declarative e event-driven.
-- =============================================================

-- =============================================================
-- Step 4.1: Prima Dynamic Table - Ascolti Giornalieri
-- =============================================================

USE ROLE ACCOUNTADMIN;
USE SCHEMA MEDIASET_LAB.ANALYTICS;

CREATE OR REPLACE DYNAMIC TABLE ASCOLTI_GIORNALIERI
    TARGET_LAG = '1 hour'
    WAREHOUSE = MEDIASET_WH
AS
SELECT
    a.data_rilevazione,
    p.programma_id,
    p.titolo,
    p.genere,
    p.canale,
    SUM(a.telespettatori) as telespettatori_totali,
    AVG(a.share_percentuale) as share_medio
FROM MEDIASET_LAB.RAW.ASCOLTI a
JOIN MEDIASET_LAB.RAW.PROGRAMMI_TV p ON a.programma_id = p.programma_id
GROUP BY a.data_rilevazione, p.programma_id, p.titolo, p.genere, p.canale;

-- =============================================================
-- Step 4.2: Dynamic Table a Cascata - Top Settimanali
-- =============================================================

CREATE OR REPLACE DYNAMIC TABLE TOP_PROGRAMMI_SETTIMANA
    TARGET_LAG = '1 hour'
    WAREHOUSE = MEDIASET_WH
AS
WITH ranked AS (
    SELECT
        DATE_TRUNC('week', data_rilevazione) as settimana,
        titolo,
        genere,
        AVG(share_medio) as share_medio_settimana,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('week', data_rilevazione)
            ORDER BY AVG(share_medio) DESC
        ) as rank
    FROM ASCOLTI_GIORNALIERI
    GROUP BY DATE_TRUNC('week', data_rilevazione), titolo, genere
)
SELECT * FROM ranked WHERE rank <= 10;

-- =============================================================
-- Step 4.3: Verifica e Monitoraggio
-- =============================================================

-- Visualizza lo stato
SHOW DYNAMIC TABLES IN SCHEMA MEDIASET_LAB.ANALYTICS;

-- Query sulla dynamic table
SELECT * FROM TOP_PROGRAMMI_SETTIMANA
ORDER BY settimana DESC, rank;

-- =============================================================
-- Step 4.4: Simulazione Aggiornamento
-- =============================================================

-- Inserisci nuovi dati
INSERT INTO MEDIASET_LAB.RAW.ASCOLTI VALUES
(99999, 1, 2, CURRENT_DATE(), 'Prime Time', 'Lombardia', 3500000, 28.5, 'Adulti 25-54', 'Smart TV');

-- Forza refresh (opzionale per demo)
ALTER DYNAMIC TABLE ASCOLTI_GIORNALIERI REFRESH;

-- Verifica aggiornamento
SELECT * FROM ASCOLTI_GIORNALIERI WHERE data_rilevazione = CURRENT_DATE();

-- =============================================================
-- Esercizio Pratico 4
-- =============================================================
-- Crea una Dynamic Table che calcoli i KPI pubblicitari
-- aggregati per settore merceologico.

-- =============================================================
-- Streams & Tasks: Pipeline Event-Driven
-- =============================================================
-- Gli Streams tracciano le modifiche (INSERT, UPDATE, DELETE) su
-- una tabella sorgente tramite Change Data Capture (CDC).
-- I Tasks eseguono istruzioni SQL su base schedulata o quando
-- uno stream contiene nuovi dati. Combinati, permettono di
-- costruire pipeline reattive senza orchestrazione esterna.

-- =============================================================
-- Step 4.5: Creazione di uno Stream sulla Tabella ASCOLTI
-- =============================================================

USE ROLE ACCOUNTADMIN;
USE SCHEMA MEDIASET_LAB.RAW;

-- Crea uno stream per catturare le modifiche sulla tabella ASCOLTI
CREATE OR REPLACE STREAM ASCOLTI_STREAM ON TABLE ASCOLTI
    APPEND_ONLY = TRUE;

-- Verifica: lo stream e vuoto (nessuna modifica ancora)
SELECT * FROM ASCOLTI_STREAM;

-- Nota: APPEND_ONLY = TRUE cattura solo gli INSERT,
-- ideale per dati di tipo log/eventi come gli ascolti TV.

-- =============================================================
-- Step 4.6: Tabella Target e Task per Processare lo Stream
-- =============================================================

USE SCHEMA MEDIASET_LAB.ANALYTICS;

-- Crea una tabella target per i nuovi ascolti processati
CREATE OR REPLACE TABLE NUOVI_ASCOLTI_LOG (
    data_elaborazione TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    programma_id NUMBER,
    data_rilevazione DATE,
    regione VARCHAR(50),
    telespettatori NUMBER,
    share_percentuale FLOAT,
    num_record_processati NUMBER
);

-- Crea un task che consuma lo stream e scrive nella tabella target
CREATE OR REPLACE TASK PROCESSA_NUOVI_ASCOLTI
    WAREHOUSE = MEDIASET_WH
    SCHEDULE = '5 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('MEDIASET_LAB.RAW.ASCOLTI_STREAM')
AS
INSERT INTO MEDIASET_LAB.ANALYTICS.NUOVI_ASCOLTI_LOG (
    programma_id, data_rilevazione, regione,
    telespettatori, share_percentuale, num_record_processati
)
SELECT
    programma_id,
    data_rilevazione,
    regione,
    SUM(telespettatori),
    AVG(share_percentuale),
    COUNT(*)
FROM MEDIASET_LAB.RAW.ASCOLTI_STREAM
GROUP BY programma_id, data_rilevazione, regione;

-- Attiva il task
ALTER TASK PROCESSA_NUOVI_ASCOLTI RESUME;

-- Verifica stato del task
SHOW TASKS IN SCHEMA MEDIASET_LAB.ANALYTICS;

-- Nota: La clausola WHEN SYSTEM$STREAM_HAS_DATA(...) fa si che
-- il task si esegua solo quando ci sono nuovi dati nello stream,
-- risparmiando risorse.

-- =============================================================
-- Step 4.7: Test della Pipeline Stream + Task
-- =============================================================

-- Inserisci nuovi dati nella tabella sorgente
INSERT INTO MEDIASET_LAB.RAW.ASCOLTI VALUES
(99801, 3, 5, CURRENT_DATE(), 'Access Prime Time', 'Lombardia', 2100000, 19.3, 'Adulti 25-54', 'Smart TV'),
(99802, 3, 5, CURRENT_DATE(), 'Access Prime Time', 'Lazio', 1500000, 16.8, 'Adulti 25-54', 'TV Tradizionale');

-- Verifica che lo stream ha catturato le modifiche
SELECT * FROM MEDIASET_LAB.RAW.ASCOLTI_STREAM;

-- Esegui il task manualmente (senza aspettare lo schedule)
EXECUTE TASK PROCESSA_NUOVI_ASCOLTI;

-- Verifica i risultati nella tabella target
SELECT * FROM MEDIASET_LAB.ANALYTICS.NUOVI_ASCOLTI_LOG
ORDER BY data_elaborazione DESC;

-- Lo stream e ora vuoto (i dati sono stati consumati)
SELECT * FROM MEDIASET_LAB.RAW.ASCOLTI_STREAM;

-- =============================================================
-- Step 4.8: Pulizia Tasks
-- =============================================================

-- Sospendi il task quando non serve piu (best practice)
ALTER TASK PROCESSA_NUOVI_ASCOLTI SUSPEND;

-- =============================================================
-- Esercizio Pratico 5
-- =============================================================
-- Crea uno stream sulla tabella FEEDBACK_SOCIAL e un task che,
-- quando arrivano nuovi feedback, inserisca un riepilogo aggregato
-- per sentiment in una nuova tabella ANALYTICS.FEEDBACK_RIEPILOGO.
