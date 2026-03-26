-- ============================================================================
-- MEDIASET SNOWFLAKE WORKSHOP - CORTEX SEARCH
-- Modulo 6: Ricerca Semantica con Cortex Search
-- Durata: 25 minuti
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE MEDIASET_LAB;
USE WAREHOUSE MEDIASET_WH;

-- ============================================================================
-- SEZIONE 1: INTRODUZIONE A CORTEX SEARCH
-- ============================================================================

-- Cortex Search permette di:
-- - Effettuare ricerche semantiche (non solo keyword match)
-- - Trovare contenuti simili per significato
-- - Implementare funzionalità di ricerca avanzata nelle applicazioni
-- - Supportare RAG (Retrieval Augmented Generation) per AI apps

-- ============================================================================
-- SEZIONE 2: PREPARAZIONE DATI PER CORTEX SEARCH
-- ============================================================================

-- Creiamo una vista che combina tutte le informazioni dei programmi
-- in un unico campo di testo ricercabile
CREATE OR REPLACE VIEW MEDIASET_LAB.RAW.V_CONTENUTI_RICERCABILI AS
SELECT 
    c.contenuto_id,
    c.programma_id,
    c.titolo,
    p.genere,
    p.canale,
    c.descrizione_breve,
    c.descrizione_completa,
    c.parole_chiave,
    c.cast_principale,
    c.regista,
    c.anno_produzione,
    c.paese_origine,
    -- Campo combinato per ricerca full-text
    CONCAT(
        'Titolo: ', c.titolo, '. ',
        'Genere: ', p.genere, '. ',
        'Canale: ', p.canale, '. ',
        'Descrizione: ', c.descrizione_completa, ' ',
        'Cast: ', COALESCE(c.cast_principale, ''), '. ',
        'Parole chiave: ', COALESCE(c.parole_chiave, ''), '. ',
        'Regista: ', COALESCE(c.regista, '')
    ) as testo_ricercabile
FROM MEDIASET_LAB.RAW.CONTENUTI_DESCRIZIONI c
JOIN MEDIASET_LAB.RAW.PROGRAMMI_TV p ON c.programma_id = p.programma_id;

-- Verifica la vista
SELECT * FROM MEDIASET_LAB.RAW.V_CONTENUTI_RICERCABILI LIMIT 5;

-- ============================================================================
-- SEZIONE 3: CREAZIONE CORTEX SEARCH SERVICE
-- ============================================================================

-- Crea il servizio di ricerca sui contenuti dei programmi
CREATE OR REPLACE CORTEX SEARCH SERVICE MEDIASET_LAB.RAW.SEARCH_PROGRAMMI
  ON testo_ricercabile
  ATTRIBUTES titolo, genere, canale, cast_principale
  WAREHOUSE = MEDIASET_WH
  TARGET_LAG = '1 hour'
  AS (
    SELECT 
        contenuto_id,
        programma_id,
        titolo,
        genere,
        canale,
        descrizione_breve,
        cast_principale,
        testo_ricercabile
    FROM MEDIASET_LAB.RAW.V_CONTENUTI_RICERCABILI
  );

-- Crea un secondo servizio per la ricerca nei feedback social
CREATE OR REPLACE CORTEX SEARCH SERVICE MEDIASET_LAB.RAW.SEARCH_FEEDBACK
  ON testo_feedback
  ATTRIBUTES piattaforma, programma_id
  WAREHOUSE = MEDIASET_WH
  TARGET_LAG = '1 hour'
  AS (
    SELECT 
        f.feedback_id,
        f.programma_id,
        p.titolo as programma_titolo,
        f.piattaforma,
        f.testo_feedback,
        f.data_feedback,
        f.likes,
        f.shares
    FROM MEDIASET_LAB.RAW.FEEDBACK_SOCIAL f
    JOIN MEDIASET_LAB.RAW.PROGRAMMI_TV p ON f.programma_id = p.programma_id
  );

-- ============================================================================
-- SEZIONE 4: VERIFICA CORTEX SEARCH SERVICES
-- ============================================================================

-- Mostra i servizi di ricerca creati
SHOW CORTEX SEARCH SERVICES IN SCHEMA MEDIASET_LAB.RAW;

-- Descrivi il servizio
DESCRIBE CORTEX SEARCH SERVICE MEDIASET_LAB.RAW.SEARCH_PROGRAMMI;

-- ============================================================================
-- SEZIONE 5: ESECUZIONE RICERCHE SEMANTICHE
-- ============================================================================

-- Ricerca 1: Trova programmi di intrattenimento leggero per famiglie
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "programmi divertenti per tutta la famiglia con risate e intrattenimento leggero",
        "columns": ["titolo", "genere", "canale", "descrizione_breve"],
        "limit": 5
    }'
);

-- Ricerca 2: Trova reality show con dinamiche sentimentali
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "reality show con coppie amore tradimenti tentazioni",
        "columns": ["titolo", "genere", "descrizione_breve"],
        "limit": 5
    }'
);

-- Ricerca 3: Trova programmi di informazione e attualità
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "notizie attualità informazione giornalismo inchieste",
        "columns": ["titolo", "genere", "canale", "descrizione_breve"],
        "limit": 5
    }'
);

-- Ricerca 4: Trova talent show musicali
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "musica canto talento giovani artisti cantanti",
        "columns": ["titolo", "genere", "cast_principale"],
        "limit": 5
    }'
);

-- Ricerca 5: Trova programmi condotti da Maria De Filippi
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "Maria De Filippi conduttrice",
        "columns": ["titolo", "cast_principale", "descrizione_breve"],
        "limit": 5
    }'
);

-- ============================================================================
-- SEZIONE 6: RICERCA NEI FEEDBACK SOCIAL
-- ============================================================================

-- Ricerca feedback positivi sull'intrattenimento
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_FEEDBACK',
    '{
        "query": "fantastico bello divertente emozionante mi piace",
        "columns": ["programma_titolo", "piattaforma", "testo_feedback", "likes"],
        "limit": 5
    }'
);

-- Ricerca feedback critici
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_FEEDBACK',
    '{
        "query": "noioso deludente peggio non mi piace brutto",
        "columns": ["programma_titolo", "piattaforma", "testo_feedback"],
        "limit": 5
    }'
);

-- Ricerca feedback su specifici aspetti
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_FEEDBACK',
    '{
        "query": "conduttore presentatore bravissimo professionale",
        "columns": ["programma_titolo", "testo_feedback", "likes"],
        "limit": 5
    }'
);

-- ============================================================================
-- SEZIONE 7: UTILIZZO CON FILTRI
-- ============================================================================

-- Ricerca con filtro per genere
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "spettacolo serale entertainment",
        "columns": ["titolo", "genere", "canale", "descrizione_breve"],
        "filter": {"@eq": {"genere": "Reality"}},
        "limit": 5
    }'
);

-- Ricerca con filtro per canale
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "quiz giochi premi concorrenti",
        "columns": ["titolo", "genere", "descrizione_breve"],
        "filter": {"@eq": {"canale": "Canale 5"}},
        "limit": 5
    }'
);

-- ============================================================================
-- SEZIONE 8: GRANT PERMISSIONS
-- ============================================================================

GRANT USAGE ON CORTEX SEARCH SERVICE MEDIASET_LAB.RAW.SEARCH_PROGRAMMI TO ROLE MEDIASET_ANALYST;
GRANT USAGE ON CORTEX SEARCH SERVICE MEDIASET_LAB.RAW.SEARCH_PROGRAMMI TO ROLE MEDIASET_MARKETING;
GRANT USAGE ON CORTEX SEARCH SERVICE MEDIASET_LAB.RAW.SEARCH_FEEDBACK TO ROLE MEDIASET_ANALYST;
GRANT USAGE ON CORTEX SEARCH SERVICE MEDIASET_LAB.RAW.SEARCH_FEEDBACK TO ROLE MEDIASET_MARKETING;

-- ============================================================================
-- SEZIONE 9: CASO D'USO - SISTEMA DI RACCOMANDAZIONE
-- ============================================================================

-- Esempio: Dato un programma, trova programmi simili
-- Step 1: Ottieni la descrizione del programma di partenza
SET programma_riferimento = (
    SELECT descrizione_completa 
    FROM MEDIASET_LAB.RAW.CONTENUTI_DESCRIZIONI 
    WHERE titolo = 'Grande Fratello VIP'
);

-- Step 2: Cerca programmi simili
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "reality show convivenza casa personaggi famosi celebrity eliminazione",
        "columns": ["titolo", "genere", "descrizione_breve"],
        "limit": 5
    }'
);

-- ============================================================================
-- ESERCIZI MODULO 6
-- ============================================================================

-- ESERCIZIO 6.1: Crea una ricerca per trovare programmi adatti a un target giovane
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "giovani adolescenti ragazzi social trend moderno",
        "columns": ["titolo", "genere", "canale", "descrizione_breve"],
        "limit": 5
    }'
);

-- ESERCIZIO 6.2: Cerca feedback che menzionano specifici conduttori
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_FEEDBACK',
    '{
        "query": "Gerry Scotti simpatico bravo conduttore",
        "columns": ["programma_titolo", "testo_feedback", "piattaforma"],
        "limit": 5
    }'
);

-- ESERCIZIO 6.3: Implementa una ricerca per trovare programmi 
-- che trattano temi di attualità sociale
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "attualità sociale denuncia problemi italiani cronaca investigativo",
        "columns": ["titolo", "genere", "descrizione_breve"],
        "limit": 5
    }'
);

-- ESERCIZIO 6.4: Combina Cortex Search con AI Functions
-- Trova feedback negativi e genera suggerimenti
WITH feedback_negativi AS (
    SELECT 
        f.programma_id,
        p.titolo,
        f.testo_feedback
    FROM MEDIASET_LAB.RAW.FEEDBACK_SOCIAL f
    JOIN MEDIASET_LAB.RAW.PROGRAMMI_TV p ON f.programma_id = p.programma_id
    WHERE SNOWFLAKE.CORTEX.SENTIMENT(f.testo_feedback) < -0.2
    LIMIT 3
)
SELECT 
    titolo,
    testo_feedback,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        'Basandoti su questo feedback negativo, suggerisci un miglioramento: ' || testo_feedback
    ) as suggerimento
FROM feedback_negativi;
