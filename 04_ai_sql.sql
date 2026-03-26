-- ============================================================================
-- MEDIASET SNOWFLAKE WORKSHOP - CORTEX AI SQL
-- Modulo 4: Funzioni AI di Snowflake Cortex
-- Durata: 25 minuti
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE MEDIASET_LAB;
USE SCHEMA RAW;
USE WAREHOUSE MEDIASET_WH;

-- ============================================================================
-- SEZIONE 1: INTRODUZIONE A CORTEX AI FUNCTIONS
-- ============================================================================

-- Snowflake Cortex offre funzioni AI integrate che permettono di:
-- - Analizzare il sentiment di testi
-- - Classificare contenuti
-- - Riassumere testi lunghi
-- - Tradurre contenuti
-- - Estrarre informazioni
-- - Generare testo con LLM

-- Tutte le funzioni sono accessibili via SQL senza necessità di 
-- configurare infrastruttura ML

-- ============================================================================
-- SEZIONE 2: AI_SENTIMENT - Analisi del Sentiment
-- ============================================================================

-- Analizza il sentiment dei feedback social sui programmi
SELECT 
    f.feedback_id,
    f.programma_id,
    p.titolo,
    f.piattaforma,
    f.testo_feedback,
    SNOWFLAKE.CORTEX.SENTIMENT(f.testo_feedback) as sentiment_score
FROM FEEDBACK_SOCIAL f
JOIN PROGRAMMI_TV p ON f.programma_id = p.programma_id
ORDER BY sentiment_score DESC;

-- Calcola il sentiment medio per programma
SELECT 
    p.titolo,
    p.genere,
    COUNT(*) as num_feedback,
    AVG(SNOWFLAKE.CORTEX.SENTIMENT(f.testo_feedback)) as sentiment_medio,
    SUM(f.likes) as total_likes
FROM FEEDBACK_SOCIAL f
JOIN PROGRAMMI_TV p ON f.programma_id = p.programma_id
GROUP BY p.titolo, p.genere
ORDER BY sentiment_medio DESC;

-- Identifica i feedback più negativi per attenzione immediata
SELECT 
    f.feedback_id,
    p.titolo,
    f.testo_feedback,
    f.piattaforma,
    SNOWFLAKE.CORTEX.SENTIMENT(f.testo_feedback) as sentiment_score
FROM FEEDBACK_SOCIAL f
JOIN PROGRAMMI_TV p ON f.programma_id = p.programma_id
WHERE SNOWFLAKE.CORTEX.SENTIMENT(f.testo_feedback) < 0
ORDER BY sentiment_score ASC
LIMIT 5;

-- ============================================================================
-- SEZIONE 3: AI_CLASSIFY - Classificazione Contenuti
-- ============================================================================

-- Classifica i feedback in categorie predefinite
SELECT 
    f.feedback_id,
    f.testo_feedback,
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
        f.testo_feedback,
        ['Positivo Entusiasta', 'Positivo Moderato', 'Neutro', 'Critica Costruttiva', 'Negativo']
    ) as classificazione
FROM FEEDBACK_SOCIAL f
LIMIT 10;

-- Classifica le descrizioni dei programmi per target audience
SELECT 
    c.titolo,
    c.descrizione_breve,
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
        c.descrizione_completa,
        ['Famiglia', 'Giovani Adulti', 'Adulti', 'Tutti', 'Over 50']
    ) as target_suggerito
FROM CONTENUTI_DESCRIZIONI c;

-- Classifica i programmi per mood/tono
SELECT 
    c.titolo,
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
        c.descrizione_completa,
        ['Leggero e Divertente', 'Informativo', 'Drammatico', 'Emozionante', 'Investigativo']
    ) as mood
FROM CONTENUTI_DESCRIZIONI c;

-- ============================================================================
-- SEZIONE 4: AI_SUMMARIZE - Riassunti Automatici
-- ============================================================================

-- Genera riassunti brevi delle descrizioni dei programmi
SELECT 
    c.titolo,
    c.descrizione_completa,
    SNOWFLAKE.CORTEX.SUMMARIZE(c.descrizione_completa) as riassunto
FROM CONTENUTI_DESCRIZIONI c
WHERE LENGTH(c.descrizione_completa) > 200
LIMIT 5;

-- Riassumi tutti i feedback di un programma specifico
WITH feedback_aggregato AS (
    SELECT 
        p.titolo,
        LISTAGG(f.testo_feedback, ' | ') as tutti_feedback
    FROM FEEDBACK_SOCIAL f
    JOIN PROGRAMMI_TV p ON f.programma_id = p.programma_id
    WHERE p.titolo = 'Grande Fratello VIP'
    GROUP BY p.titolo
)
SELECT 
    titolo,
    SNOWFLAKE.CORTEX.SUMMARIZE(tutti_feedback) as sintesi_feedback
FROM feedback_aggregato;

-- ============================================================================
-- SEZIONE 5: AI_TRANSLATE - Traduzione
-- ============================================================================

-- Traduci le descrizioni in inglese per il mercato internazionale
SELECT 
    c.titolo,
    c.descrizione_breve as descrizione_italiano,
    SNOWFLAKE.CORTEX.TRANSLATE(c.descrizione_breve, 'it', 'en') as descrizione_inglese
FROM CONTENUTI_DESCRIZIONI c
LIMIT 5;

-- Traduci in spagnolo
SELECT 
    c.titolo,
    c.descrizione_breve as descrizione_italiano,
    SNOWFLAKE.CORTEX.TRANSLATE(c.descrizione_breve, 'it', 'es') as descrizione_spagnolo
FROM CONTENUTI_DESCRIZIONI c
LIMIT 5;

-- ============================================================================
-- SEZIONE 6: AI_COMPLETE - Generazione Testo con LLM
-- ============================================================================

-- Genera tagline promozionali per i programmi
SELECT 
    c.titolo,
    c.genere,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        'Genera una tagline promozionale accattivante in italiano (massimo 10 parole) per questo programma TV: ' || c.titolo || '. Genere: ' || c.genere || '. Descrizione: ' || c.descrizione_breve
    ) as tagline_generata
FROM CONTENUTI_DESCRIZIONI c
JOIN PROGRAMMI_TV p ON c.programma_id = p.programma_id
LIMIT 5;

-- Genera suggerimenti per migliorare programmi basandosi sul feedback
WITH feedback_negativo AS (
    SELECT 
        p.titolo,
        LISTAGG(f.testo_feedback, '; ') as feedback_list
    FROM FEEDBACK_SOCIAL f
    JOIN PROGRAMMI_TV p ON f.programma_id = p.programma_id
    WHERE SNOWFLAKE.CORTEX.SENTIMENT(f.testo_feedback) < 0
    GROUP BY p.titolo
)
SELECT 
    titolo,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        'Basandoti su questi feedback negativi degli spettatori, suggerisci 3 miglioramenti concreti per il programma "' || titolo || '". Feedback: ' || feedback_list
    ) as suggerimenti
FROM feedback_negativo
LIMIT 3;

-- ============================================================================
-- SEZIONE 7: AI_EXTRACT - Estrazione Informazioni
-- ============================================================================

-- Estrai informazioni strutturate dalle descrizioni
SELECT 
    c.titolo,
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
        c.descrizione_completa,
        'Chi è il conduttore del programma?'
    ) as conduttore_estratto
FROM CONTENUTI_DESCRIZIONI c
LIMIT 5;

-- Estrai l'anno di inizio
SELECT 
    c.titolo,
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
        c.descrizione_completa,
        'In che anno è iniziato questo programma?'
    ) as anno_inizio
FROM CONTENUTI_DESCRIZIONI c
LIMIT 5;

-- ============================================================================
-- SEZIONE 8: CREAZIONE TABELLA ARRICCHITA CON AI
-- ============================================================================

-- Crea una tabella con analisi AI pre-calcolate
CREATE OR REPLACE TABLE MEDIASET_LAB.ANALYTICS.FEEDBACK_ANALISI_AI AS
SELECT 
    f.feedback_id,
    f.programma_id,
    p.titolo,
    f.piattaforma,
    f.testo_feedback,
    f.likes,
    f.shares,
    f.data_feedback,
    SNOWFLAKE.CORTEX.SENTIMENT(f.testo_feedback) as sentiment_score,
    CASE 
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(f.testo_feedback) > 0.3 THEN 'Positivo'
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(f.testo_feedback) < -0.3 THEN 'Negativo'
        ELSE 'Neutro'
    END as sentiment_categoria
FROM FEEDBACK_SOCIAL f
JOIN PROGRAMMI_TV p ON f.programma_id = p.programma_id;

-- Verifica la tabella creata
SELECT * FROM MEDIASET_LAB.ANALYTICS.FEEDBACK_ANALISI_AI
ORDER BY sentiment_score DESC;

-- Report sentiment per programma
SELECT 
    titolo,
    COUNT(*) as num_feedback,
    SUM(CASE WHEN sentiment_categoria = 'Positivo' THEN 1 ELSE 0 END) as feedback_positivi,
    SUM(CASE WHEN sentiment_categoria = 'Negativo' THEN 1 ELSE 0 END) as feedback_negativi,
    SUM(CASE WHEN sentiment_categoria = 'Neutro' THEN 1 ELSE 0 END) as feedback_neutri,
    ROUND(AVG(sentiment_score), 3) as sentiment_medio
FROM MEDIASET_LAB.ANALYTICS.FEEDBACK_ANALISI_AI
GROUP BY titolo
ORDER BY sentiment_medio DESC;

-- ============================================================================
-- ESERCIZI MODULO 4
-- ============================================================================

-- ESERCIZIO 4.1: Usa AI_SENTIMENT per identificare trend di sentiment nel tempo
-- per un programma specifico
SELECT 
    DATE_TRUNC('day', data_feedback) as giorno,
    AVG(sentiment_score) as sentiment_medio_giorno
FROM MEDIASET_LAB.ANALYTICS.FEEDBACK_ANALISI_AI
WHERE titolo = 'Grande Fratello VIP'
GROUP BY DATE_TRUNC('day', data_feedback)
ORDER BY giorno;

-- ESERCIZIO 4.2: Genera descrizioni alternative per i programmi
-- usando AI_COMPLETE con stili diversi (formale, giovane, ironico)
SELECT 
    c.titolo,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        'Riscrivi questa descrizione in modo più giovane e social-friendly (usa emoji): ' || c.descrizione_breve
    ) as descrizione_giovane
FROM CONTENUTI_DESCRIZIONI c
LIMIT 3;

-- ESERCIZIO 4.3: Classifica i contratti pubblicitari per rischio
SELECT 
    c.inserzionista,
    c.budget_totale_eur,
    c.stato_contratto,
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
        'Contratto con ' || c.inserzionista || ' del settore ' || c.settore_merceologico || 
        ' per un budget di ' || c.budget_totale_eur || ' EUR, stato: ' || c.stato_contratto,
        ['Basso Rischio', 'Medio Rischio', 'Alto Rischio']
    ) as rischio_classificato
FROM CONTRATTI_PUBBLICITARI c;

-- ESERCIZIO 4.4: Crea un riassunto esecutivo giornaliero
-- combinando dati di ascolti e sentiment
WITH daily_summary AS (
    SELECT 
        'Ascolti totali: ' || SUM(telespettatori) || 
        ', Share medio: ' || ROUND(AVG(share_percentuale), 1) || '%' ||
        ', Regioni coperte: ' || COUNT(DISTINCT regione) as stats
    FROM ASCOLTI
    WHERE data_rilevazione = CURRENT_DATE()
)
SELECT 
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        'Genera un breve report esecutivo (3-4 frasi) per questi dati giornalieri TV: ' || stats
    ) as report_esecutivo
FROM daily_summary;
