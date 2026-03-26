-- ============================================================================
-- MEDIASET SNOWFLAKE WORKSHOP - DATA PIPELINES
-- Modulo 4: Dynamic Tables, Streams & Tasks per pipeline di dati
-- Durata: 35 minuti
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE MEDIASET_LAB;
USE WAREHOUSE MEDIASET_WH;

-- ============================================================================
-- SEZIONE 1: INTRODUZIONE ALLE DYNAMIC TABLES
-- ============================================================================

-- Le Dynamic Tables sono tabelle che si aggiornano automaticamente
-- quando i dati sottostanti cambiano. Ideali per:
-- - Aggregazioni in tempo reale
-- - Trasformazioni ETL incrementali
-- - Materializzazione di query complesse

-- ============================================================================
-- SEZIONE 2: CREAZIONE DYNAMIC TABLES PER ANALYTICS
-- ============================================================================

-- Dynamic Table 1: Ascolti giornalieri aggregati per programma
CREATE OR REPLACE DYNAMIC TABLE MEDIASET_LAB.ANALYTICS.ASCOLTI_GIORNALIERI
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
    AVG(a.share_percentuale) as share_medio,
    COUNT(DISTINCT a.regione) as regioni_coperte,
    MAX(a.share_percentuale) as share_massimo,
    MIN(a.share_percentuale) as share_minimo
FROM MEDIASET_LAB.RAW.ASCOLTI a
JOIN MEDIASET_LAB.RAW.PROGRAMMI_TV p ON a.programma_id = p.programma_id
GROUP BY 
    a.data_rilevazione,
    p.programma_id,
    p.titolo,
    p.genere,
    p.canale;

-- Dynamic Table 2: Top 10 programmi settimanali
CREATE OR REPLACE DYNAMIC TABLE MEDIASET_LAB.ANALYTICS.TOP_PROGRAMMI_SETTIMANA
    TARGET_LAG = '1 hour'
    WAREHOUSE = MEDIASET_WH
    AS
WITH weekly_stats AS (
    SELECT 
        DATE_TRUNC('week', data_rilevazione) as settimana,
        programma_id,
        titolo,
        genere,
        canale,
        AVG(share_medio) as share_medio_settimana,
        SUM(telespettatori_totali) as telespettatori_settimana
    FROM MEDIASET_LAB.ANALYTICS.ASCOLTI_GIORNALIERI
    GROUP BY 
        DATE_TRUNC('week', data_rilevazione),
        programma_id,
        titolo,
        genere,
        canale
),
ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY settimana ORDER BY share_medio_settimana DESC) as rank
    FROM weekly_stats
)
SELECT 
    settimana,
    rank as posizione,
    programma_id,
    titolo,
    genere,
    canale,
    ROUND(share_medio_settimana, 2) as share_medio,
    telespettatori_settimana
FROM ranked
WHERE rank <= 10;

-- Dynamic Table 3: Performance per fascia oraria
CREATE OR REPLACE DYNAMIC TABLE MEDIASET_LAB.ANALYTICS.PERFORMANCE_FASCIA_ORARIA
    TARGET_LAG = '1 hour'
    WAREHOUSE = MEDIASET_WH
    AS
SELECT 
    a.fascia_oraria,
    p.genere,
    COUNT(DISTINCT p.programma_id) as num_programmi,
    AVG(a.share_percentuale) as share_medio,
    SUM(a.telespettatori) as telespettatori_totali,
    ROUND(AVG(a.telespettatori), 0) as media_telespettatori_per_rilevazione
FROM MEDIASET_LAB.RAW.ASCOLTI a
JOIN MEDIASET_LAB.RAW.PROGRAMMI_TV p ON a.programma_id = p.programma_id
GROUP BY a.fascia_oraria, p.genere;

-- Dynamic Table 4: KPI Pubblicitari
CREATE OR REPLACE DYNAMIC TABLE MEDIASET_LAB.ANALYTICS.KPI_PUBBLICITARI
    TARGET_LAG = '1 hour'
    WAREHOUSE = MEDIASET_WH
    AS
SELECT 
    c.canale_target as canale,
    c.settore_merceologico,
    COUNT(DISTINCT c.contratto_id) as num_contratti,
    SUM(c.budget_totale_eur) as budget_totale,
    AVG(c.budget_totale_eur) as budget_medio_contratto,
    SUM(CASE WHEN c.stato_contratto = 'Attivo' THEN c.budget_totale_eur ELSE 0 END) as budget_attivo,
    SUM(CASE WHEN c.stato_contratto = 'Completato' THEN c.budget_totale_eur ELSE 0 END) as budget_completato,
    SUM(CASE WHEN c.stato_contratto = 'Pianificato' THEN c.budget_totale_eur ELSE 0 END) as budget_pianificato
FROM MEDIASET_LAB.RAW.CONTRATTI_PUBBLICITARI c
GROUP BY c.canale_target, c.settore_merceologico;

-- Dynamic Table 5: Analisi abbonati per regione
CREATE OR REPLACE DYNAMIC TABLE MEDIASET_LAB.ANALYTICS.ABBONATI_PER_REGIONE
    TARGET_LAG = '1 hour'
    WAREHOUSE = MEDIASET_WH
    AS
SELECT 
    regione,
    tipo_abbonamento,
    COUNT(*) as num_abbonati,
    SUM(importo_mensile) as ricavo_mensile_totale,
    AVG(importo_mensile) as ricavo_medio_abbonato,
    SUM(CASE WHEN stato_abbonamento = 'Attivo' THEN 1 ELSE 0 END) as abbonati_attivi,
    SUM(CASE WHEN stato_abbonamento = 'Sospeso' THEN 1 ELSE 0 END) as abbonati_sospesi,
    SUM(CASE WHEN stato_abbonamento = 'Cancellato' THEN 1 ELSE 0 END) as abbonati_cancellati,
    MIN(data_iscrizione) as prima_iscrizione,
    MAX(data_iscrizione) as ultima_iscrizione
FROM MEDIASET_LAB.RAW.ABBONATI
GROUP BY regione, tipo_abbonamento;

-- ============================================================================
-- SEZIONE 3: MONITORAGGIO DYNAMIC TABLES
-- ============================================================================

-- Visualizza lo stato delle dynamic tables
SHOW DYNAMIC TABLES IN SCHEMA MEDIASET_LAB.ANALYTICS;

-- Verifica il refresh delle dynamic tables
SELECT 
    name,
    schema_name,
    target_lag,
    refresh_mode,
    scheduling_state
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES())
WHERE schema_name = 'ANALYTICS';

-- ============================================================================
-- SEZIONE 4: QUERY SULLE DYNAMIC TABLES
-- ============================================================================

-- Query 1: Programmi con share medio > 15% questa settimana
SELECT * 
FROM MEDIASET_LAB.ANALYTICS.TOP_PROGRAMMI_SETTIMANA
WHERE share_medio > 15
ORDER BY settimana DESC, posizione;

-- Query 2: Performance per fascia oraria e genere
SELECT 
    fascia_oraria,
    genere,
    share_medio,
    telespettatori_totali
FROM MEDIASET_LAB.ANALYTICS.PERFORMANCE_FASCIA_ORARIA
ORDER BY fascia_oraria, share_medio DESC;

-- Query 3: Budget pubblicitario per canale
SELECT 
    canale,
    SUM(budget_totale) as budget_totale,
    SUM(budget_attivo) as budget_attivo
FROM MEDIASET_LAB.ANALYTICS.KPI_PUBBLICITARI
GROUP BY canale
ORDER BY budget_totale DESC;

-- Query 4: Trend giornaliero di un programma specifico
SELECT 
    data_rilevazione,
    titolo,
    share_medio,
    telespettatori_totali
FROM MEDIASET_LAB.ANALYTICS.ASCOLTI_GIORNALIERI
WHERE titolo = 'Grande Fratello VIP'
ORDER BY data_rilevazione;

-- ============================================================================
-- SEZIONE 5: SIMULAZIONE AGGIORNAMENTO DATI
-- ============================================================================

-- Inseriamo nuovi dati per vedere l'aggiornamento delle dynamic tables
INSERT INTO MEDIASET_LAB.RAW.ASCOLTI VALUES
(99901, 1, 2, CURRENT_DATE(), 'Prime Time', 'Lombardia', 3500000, 28.5, 'Adulti 25-54', 'Smart TV'),
(99902, 1, 2, CURRENT_DATE(), 'Prime Time', 'Lazio', 2800000, 25.2, 'Adulti 25-54', 'TV Tradizionale'),
(99903, 1, 7, CURRENT_DATE(), 'Prime Time', 'Campania', 1900000, 22.1, 'Giovani 15-34', 'Streaming');

-- Forza il refresh immediato (opzionale, per demo)
ALTER DYNAMIC TABLE MEDIASET_LAB.ANALYTICS.ASCOLTI_GIORNALIERI REFRESH;

-- Verifica che i nuovi dati siano stati processati
SELECT * 
FROM MEDIASET_LAB.ANALYTICS.ASCOLTI_GIORNALIERI
WHERE data_rilevazione = CURRENT_DATE()
ORDER BY share_medio DESC;

-- ============================================================================
-- SEZIONE 6: GRANTS SULLE DYNAMIC TABLES
-- ============================================================================

GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA MEDIASET_LAB.ANALYTICS TO ROLE MEDIASET_ANALYST;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA MEDIASET_LAB.ANALYTICS TO ROLE MEDIASET_MARKETING;

-- ============================================================================
-- ESERCIZI MODULO 3
-- ============================================================================

-- ESERCIZIO 3.1: Crea una dynamic table che calcoli il confronto
-- tra share del giorno corrente e media storica per ogni programma

-- Soluzione:
CREATE OR REPLACE DYNAMIC TABLE MEDIASET_LAB.ANALYTICS.CONFRONTO_SHARE_STORICO
    TARGET_LAG = '1 hour'
    WAREHOUSE = MEDIASET_WH
    AS
WITH storico AS (
    SELECT 
        programma_id,
        AVG(share_medio) as share_storico
    FROM MEDIASET_LAB.ANALYTICS.ASCOLTI_GIORNALIERI
    GROUP BY programma_id
),
oggi AS (
    SELECT 
        programma_id,
        titolo,
        share_medio as share_oggi
    FROM MEDIASET_LAB.ANALYTICS.ASCOLTI_GIORNALIERI
    WHERE data_rilevazione = CURRENT_DATE()
)
SELECT 
    o.programma_id,
    o.titolo,
    o.share_oggi,
    s.share_storico,
    ROUND(o.share_oggi - s.share_storico, 2) as differenza,
    ROUND((o.share_oggi - s.share_storico) / s.share_storico * 100, 1) as variazione_percentuale
FROM oggi o
JOIN storico s ON o.programma_id = s.programma_id;

-- ESERCIZIO 3.2: Modifica il target_lag di una dynamic table
-- ALTER DYNAMIC TABLE MEDIASET_LAB.ANALYTICS.ASCOLTI_GIORNALIERI SET TARGET_LAG = '30 minutes';

-- ESERCIZIO 3.3: Crea una pipeline a cascata (dynamic table che dipende da altra dynamic table)
-- La TOP_PROGRAMMI_SETTIMANA già dipende da ASCOLTI_GIORNALIERI - osserva come
-- un aggiornamento della prima si propaga alla seconda

-- ESERCIZIO 3.4: Verifica lo storico dei refresh
SELECT *
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY())
WHERE name LIKE 'ASCOLTI%'
ORDER BY refresh_start_time DESC
LIMIT 10;
