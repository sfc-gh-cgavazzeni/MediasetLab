-- ============================================================================
-- MEDIASET SNOWFLAKE WORKSHOP - SEMANTIC VIEWS & CORTEX ANALYST
-- Modulo 5: Semantic Views e Query in Linguaggio Naturale
-- Durata: 40 minuti
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE MEDIASET_LAB;
USE WAREHOUSE MEDIASET_WH;

-- ============================================================================
-- SEZIONE 1: INTRODUZIONE ALLE SEMANTIC VIEWS
-- ============================================================================

-- Le Semantic Views permettono di:
-- - Definire concetti di business in modo chiaro e consistente
-- - Creare metriche e dimensioni riutilizzabili
-- - Abilitare query in linguaggio naturale con Cortex Analyst
-- - Garantire definizioni uniformi in tutta l'organizzazione

-- ============================================================================
-- SEZIONE 2: CREAZIONE SEMANTIC VIEW PER ANALISI ASCOLTI
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_ASCOLTI
AS SEMANTIC MODEL
  TABLES (
    -- Tabella logica: Programmi TV
    PROGRAMMI AS (
      SELECT 
        programma_id,
        titolo,
        genere,
        canale,
        durata_minuti,
        anno_prima_messa_in_onda,
        produzione,
        target_eta,
        costo_episodio_eur,
        rating_contenuto
      FROM MEDIASET_LAB.RAW.PROGRAMMI_TV
      
      PRIMARY KEY (programma_id)
      
      FACTS (
        durata_minuti SYNONYMS ('durata', 'lunghezza episodio', 'minuti'),
        costo_episodio_eur SYNONYMS ('costo', 'costo produzione', 'budget episodio')
      )
      
      DIMENSIONS (
        programma_id SYNONYMS ('id programma', 'codice programma'),
        titolo SYNONYMS ('nome programma', 'show', 'trasmissione'),
        genere SYNONYMS ('tipo', 'categoria', 'format'),
        canale SYNONYMS ('rete', 'emittente', 'network'),
        anno_prima_messa_in_onda SYNONYMS ('anno inizio', 'anno lancio', 'debutto'),
        produzione SYNONYMS ('casa di produzione', 'produttore'),
        target_eta SYNONYMS ('pubblico target', 'fascia età', 'target'),
        rating_contenuto SYNONYMS ('classificazione', 'rating')
      )
    ),
    
    -- Tabella logica: Ascolti
    ASCOLTI AS (
      SELECT 
        ascolto_id,
        palinsesto_id,
        programma_id,
        data_rilevazione,
        fascia_oraria,
        regione,
        telespettatori,
        share_percentuale,
        target_commerciale,
        dispositivo
      FROM MEDIASET_LAB.RAW.ASCOLTI
      
      PRIMARY KEY (ascolto_id)
      
      FACTS (
        telespettatori SYNONYMS ('spettatori', 'audience', 'viewers', 'pubblico'),
        share_percentuale SYNONYMS ('share', 'quota di mercato', 'percentuale share')
      )
      
      DIMENSIONS (
        ascolto_id SYNONYMS ('id ascolto', 'rilevazione id'),
        data_rilevazione SYNONYMS ('data', 'giorno', 'quando'),
        fascia_oraria SYNONYMS ('orario', 'slot', 'momento giornata'),
        regione SYNONYMS ('area geografica', 'territorio', 'zona'),
        target_commerciale SYNONYMS ('target pubblicitario', 'segmento'),
        dispositivo SYNONYMS ('device', 'mezzo', 'piattaforma visione')
      )
    ),
    
    -- Tabella logica: Palinsesto
    PALINSESTO AS (
      SELECT 
        palinsesto_id,
        programma_id,
        data_trasmissione,
        ora_inizio,
        ora_fine,
        canale,
        tipo_trasmissione,
        stagione,
        episodio
      FROM MEDIASET_LAB.RAW.PALINSESTO
      
      PRIMARY KEY (palinsesto_id)
      
      FACTS (
        stagione SYNONYMS ('season', 'annata'),
        episodio SYNONYMS ('puntata', 'episode')
      )
      
      DIMENSIONS (
        palinsesto_id SYNONYMS ('id palinsesto', 'slot id'),
        data_trasmissione SYNONYMS ('data messa in onda', 'data programmazione'),
        ora_inizio SYNONYMS ('inizio', 'orario inizio', 'start'),
        ora_fine SYNONYMS ('fine', 'orario fine', 'end'),
        tipo_trasmissione SYNONYMS ('tipo', 'prima tv', 'replica')
      )
    )
  )
  
  RELATIONSHIPS (
    ASCOLTI (programma_id) REFERENCES PROGRAMMI (programma_id),
    ASCOLTI (palinsesto_id) REFERENCES PALINSESTO (palinsesto_id),
    PALINSESTO (programma_id) REFERENCES PROGRAMMI (programma_id)
  )
  
  METRICS (
    -- Metriche di base
    TELESPETTATORI_TOTALI AS (
      SUM(ASCOLTI.telespettatori)
      SYNONYMS ('audience totale', 'spettatori totali', 'total viewers')
    ),
    
    SHARE_MEDIO AS (
      AVG(ASCOLTI.share_percentuale)
      SYNONYMS ('share medio', 'media share', 'average share')
    ),
    
    SHARE_MASSIMO AS (
      MAX(ASCOLTI.share_percentuale)
      SYNONYMS ('share più alto', 'picco share', 'max share')
    ),
    
    NUM_TRASMISSIONI AS (
      COUNT(DISTINCT PALINSESTO.palinsesto_id)
      SYNONYMS ('numero puntate', 'trasmissioni totali', 'episodi trasmessi')
    ),
    
    NUM_PROGRAMMI AS (
      COUNT(DISTINCT PROGRAMMI.programma_id)
      SYNONYMS ('numero programmi', 'totale show', 'programmi distinti')
    ),
    
    -- Metriche calcolate
    MEDIA_TELESPETTATORI AS (
      AVG(ASCOLTI.telespettatori)
      SYNONYMS ('media spettatori', 'audience media', 'spettatori medi')
    ),
    
    COSTO_MEDIO_PROGRAMMA AS (
      AVG(PROGRAMMI.costo_episodio_eur)
      SYNONYMS ('costo medio', 'budget medio', 'investimento medio')
    ),
    
    COSTO_PER_SPETTATORE AS (
      SUM(PROGRAMMI.costo_episodio_eur) / NULLIF(SUM(ASCOLTI.telespettatori), 0)
      SYNONYMS ('costo per viewer', 'CPV', 'costo unitario')
    )
  );

-- Verifica la creazione
DESCRIBE SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_ASCOLTI;

-- ============================================================================
-- SEZIONE 3: SEMANTIC VIEW PER ANALISI COMMERCIALE
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_COMMERCIALE
AS SEMANTIC MODEL
  TABLES (
    CONTRATTI AS (
      SELECT 
        contratto_id,
        inserzionista,
        agenzia,
        data_inizio,
        data_fine,
        budget_totale_eur,
        canale_target,
        fascia_oraria_target,
        tipo_campagna,
        settore_merceologico,
        stato_contratto
      FROM MEDIASET_LAB.RAW.CONTRATTI_PUBBLICITARI
      
      PRIMARY KEY (contratto_id)
      
      FACTS (
        budget_totale_eur SYNONYMS ('budget', 'investimento', 'spesa pubblicitaria', 'valore contratto')
      )
      
      DIMENSIONS (
        contratto_id SYNONYMS ('id contratto', 'numero contratto'),
        inserzionista SYNONYMS ('cliente', 'advertiser', 'azienda'),
        agenzia SYNONYMS ('media agency', 'centro media'),
        data_inizio SYNONYMS ('inizio campagna', 'start date'),
        data_fine SYNONYMS ('fine campagna', 'end date'),
        canale_target SYNONYMS ('canale', 'rete'),
        fascia_oraria_target SYNONYMS ('fascia oraria', 'slot orario'),
        tipo_campagna SYNONYMS ('tipo', 'obiettivo campagna'),
        settore_merceologico SYNONYMS ('settore', 'industry', 'categoria merceologica'),
        stato_contratto SYNONYMS ('stato', 'status')
      )
    ),
    
    ABBONATI AS (
      SELECT 
        abbonato_id,
        citta,
        regione,
        data_iscrizione,
        tipo_abbonamento,
        importo_mensile,
        stato_abbonamento
      FROM MEDIASET_LAB.RAW.ABBONATI
      
      PRIMARY KEY (abbonato_id)
      
      FACTS (
        importo_mensile SYNONYMS ('canone', 'abbonamento mensile', 'fee mensile')
      )
      
      DIMENSIONS (
        abbonato_id SYNONYMS ('id abbonato', 'cliente id'),
        citta SYNONYMS ('città', 'comune'),
        regione SYNONYMS ('area', 'territorio'),
        data_iscrizione SYNONYMS ('data registrazione', 'data attivazione'),
        tipo_abbonamento SYNONYMS ('piano', 'pacchetto', 'tipo piano'),
        stato_abbonamento SYNONYMS ('stato', 'status abbonamento')
      )
    )
  )
  
  METRICS (
    BUDGET_PUBBLICITARIO_TOTALE AS (
      SUM(CONTRATTI.budget_totale_eur)
      SYNONYMS ('fatturato pubblicitario', 'revenue advertising', 'ricavi pubblicità')
    ),
    
    BUDGET_MEDIO_CONTRATTO AS (
      AVG(CONTRATTI.budget_totale_eur)
      SYNONYMS ('valore medio contratto', 'average deal size')
    ),
    
    NUM_CONTRATTI AS (
      COUNT(DISTINCT CONTRATTI.contratto_id)
      SYNONYMS ('numero contratti', 'deals totali', 'contratti attivi')
    ),
    
    NUM_INSERZIONISTI AS (
      COUNT(DISTINCT CONTRATTI.inserzionista)
      SYNONYMS ('numero clienti', 'advertisers', 'inserzionisti unici')
    ),
    
    NUM_ABBONATI AS (
      COUNT(DISTINCT ABBONATI.abbonato_id)
      SYNONYMS ('numero abbonati', 'subscriber count', 'clienti premium')
    ),
    
    RICAVO_ABBONAMENTI_MENSILE AS (
      SUM(ABBONATI.importo_mensile)
      SYNONYMS ('ricavi abbonamenti', 'MRR', 'monthly recurring revenue')
    ),
    
    ARPU AS (
      SUM(ABBONATI.importo_mensile) / NULLIF(COUNT(DISTINCT ABBONATI.abbonato_id), 0)
      SYNONYMS ('ricavo medio per utente', 'average revenue per user')
    )
  );

-- ============================================================================
-- SEZIONE 4: GRANT PERMISSIONS
-- ============================================================================

GRANT USAGE ON SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_ASCOLTI TO ROLE MEDIASET_ANALYST;
GRANT USAGE ON SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_COMMERCIALE TO ROLE MEDIASET_ANALYST;
GRANT USAGE ON SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_ASCOLTI TO ROLE MEDIASET_MARKETING;
GRANT USAGE ON SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_COMMERCIALE TO ROLE MEDIASET_MARKETING;

-- ============================================================================
-- SEZIONE 5: QUERY SULLA SEMANTIC VIEW
-- ============================================================================

-- Query standard SQL sulle semantic views
SELECT 
    PROGRAMMI.titolo,
    PROGRAMMI.genere,
    TELESPETTATORI_TOTALI,
    SHARE_MEDIO
FROM SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_ASCOLTI
GROUP BY PROGRAMMI.titolo, PROGRAMMI.genere
ORDER BY SHARE_MEDIO DESC
LIMIT 10;

-- Query con filtri
SELECT 
    ASCOLTI.regione,
    TELESPETTATORI_TOTALI,
    SHARE_MEDIO,
    NUM_PROGRAMMI
FROM SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_ASCOLTI
WHERE ASCOLTI.fascia_oraria = 'Prime Time'
GROUP BY ASCOLTI.regione
ORDER BY TELESPETTATORI_TOTALI DESC;

-- Query sui dati commerciali
SELECT 
    CONTRATTI.settore_merceologico,
    BUDGET_PUBBLICITARIO_TOTALE,
    NUM_CONTRATTI,
    BUDGET_MEDIO_CONTRATTO
FROM SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_COMMERCIALE
GROUP BY CONTRATTI.settore_merceologico
ORDER BY BUDGET_PUBBLICITARIO_TOTALE DESC;

-- ============================================================================
-- SEZIONE 6: CORTEX ANALYST - QUERY IN LINGUAGGIO NATURALE
-- ============================================================================

-- Per usare Cortex Analyst con le Semantic Views, si utilizza la REST API
-- o l'interfaccia Snowsight. Ecco alcuni esempi di domande:

-- ESEMPI DI DOMANDE IN LINGUAGGIO NATURALE:
-- 
-- 1. "Qual è il programma con lo share più alto?"
-- 2. "Quanti telespettatori ha avuto il Grande Fratello VIP?"
-- 3. "Mostrami i top 5 programmi per audience nel prime time"
-- 4. "Qual è lo share medio per genere di programma?"
-- 5. "Quanto budget pubblicitario abbiamo dal settore alimentare?"
-- 6. "Quanti abbonati attivi abbiamo in Lombardia?"
-- 7. "Qual è l'ARPU per tipo di abbonamento?"
-- 8. "Confronta gli ascolti tra Canale 5 e Italia 1"
-- 9. "Trend degli ascolti settimanali per i reality show"
-- 10. "Top inserzionisti per budget investito"

-- ============================================================================
-- SEZIONE 7: VISUALIZZA METADATA SEMANTIC VIEWS
-- ============================================================================

-- Mostra tutte le semantic views
SHOW SEMANTIC VIEWS IN SCHEMA MEDIASET_LAB.ANALYTICS;

-- Mostra le dimensioni definite
SHOW SEMANTIC DIMENSIONS IN SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_ASCOLTI;

-- Mostra le metriche definite
SHOW SEMANTIC METRICS IN SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_ANALISI_ASCOLTI;

-- ============================================================================
-- ESERCIZI MODULO 5
-- ============================================================================

-- ESERCIZIO 5.1: Aggiungi una nuova metrica alla semantic view
-- Calcola il "Reach" come numero di regioni uniche raggiunte

-- ESERCIZIO 5.2: Crea una semantic view per l'analisi dei feedback social
-- includendo metriche come engagement (likes + shares) e numero feedback

-- Soluzione Esercizio 5.2:
CREATE OR REPLACE SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_SOCIAL_ENGAGEMENT
AS SEMANTIC MODEL
  TABLES (
    FEEDBACK AS (
      SELECT 
        feedback_id,
        programma_id,
        data_feedback,
        piattaforma,
        testo_feedback,
        likes,
        shares
      FROM MEDIASET_LAB.RAW.FEEDBACK_SOCIAL
      
      PRIMARY KEY (feedback_id)
      
      FACTS (
        likes SYNONYMS ('mi piace', 'like', 'apprezzamenti'),
        shares SYNONYMS ('condivisioni', 'share social', 'repost')
      )
      
      DIMENSIONS (
        feedback_id,
        programma_id,
        data_feedback SYNONYMS ('data', 'quando'),
        piattaforma SYNONYMS ('social', 'network', 'canale social')
      )
    )
  )
  
  METRICS (
    TOTAL_LIKES AS (
      SUM(FEEDBACK.likes)
      SYNONYMS ('like totali', 'apprezzamenti totali')
    ),
    
    TOTAL_SHARES AS (
      SUM(FEEDBACK.shares)
      SYNONYMS ('condivisioni totali', 'share totali')
    ),
    
    ENGAGEMENT_TOTALE AS (
      SUM(FEEDBACK.likes) + SUM(FEEDBACK.shares)
      SYNONYMS ('engagement', 'interazioni totali', 'coinvolgimento')
    ),
    
    NUM_FEEDBACK AS (
      COUNT(DISTINCT FEEDBACK.feedback_id)
      SYNONYMS ('numero feedback', 'commenti totali', 'recensioni')
    ),
    
    ENGAGEMENT_MEDIO AS (
      (SUM(FEEDBACK.likes) + SUM(FEEDBACK.shares)) / NULLIF(COUNT(DISTINCT FEEDBACK.feedback_id), 0)
      SYNONYMS ('engagement medio', 'interazioni medie per post')
    )
  );

-- ESERCIZIO 5.3: Usa la semantic view per rispondere a queste domande:
-- a) Quale piattaforma ha il maggior engagement?
SELECT 
    FEEDBACK.piattaforma,
    ENGAGEMENT_TOTALE,
    NUM_FEEDBACK,
    ENGAGEMENT_MEDIO
FROM SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_SOCIAL_ENGAGEMENT
GROUP BY FEEDBACK.piattaforma
ORDER BY ENGAGEMENT_TOTALE DESC;

-- b) Qual è il trend giornaliero dell'engagement?
SELECT 
    DATE_TRUNC('day', FEEDBACK.data_feedback) as giorno,
    ENGAGEMENT_TOTALE,
    NUM_FEEDBACK
FROM SEMANTIC VIEW MEDIASET_LAB.ANALYTICS.SV_SOCIAL_ENGAGEMENT
GROUP BY DATE_TRUNC('day', FEEDBACK.data_feedback)
ORDER BY giorno;
