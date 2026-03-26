# Workshop Snowflake per Mediaset
## Guida per i Partecipanti

---

## Informazioni Workshop

| | |
|---|---|
| **Durata** | 3.5 ore |
| **Livello** | Introduttivo/Intermedio |
| **Prerequisiti** | Account Snowflake attivo, conoscenze base SQL |
| **Settore** | TV Broadcasting |

---

## Agenda

| Orario | Modulo | Durata |
|--------|--------|--------|
| 00:00 - 00:40 | Modulo 1: Setup e Basi Snowflake | 40 min |
| 00:40 - 01:15 | Modulo 2: Row & Column Level Security | 35 min |
| 01:15 - 01:45 | Modulo 3: Data Pipelines (Dynamic Tables) | 30 min |
| 01:45 - 02:00 | **Pausa** | 15 min |
| 02:00 - 02:25 | Modulo 4: Cortex AI SQL Functions | 25 min |
| 02:25 - 03:05 | Modulo 5: Semantic Views & Cortex Analyst | 40 min |
| 03:05 - 03:30 | Modulo 6: Cortex Search & Snowflake Intelligence | 25 min |

---

## Modulo 1: Setup e Basi Snowflake (40 min)

> **Snowflake** è una piattaforma dati cloud-native che separa storage e compute. I **Database** organizzano i dati in **Schema**, mentre i **Warehouse** forniscono risorse di calcolo elastiche on-demand. I **Ruoli** controllano l'accesso seguendo il principio del least privilege.

### Obiettivi di Apprendimento
- Creare e configurare database, schema e warehouse
- Comprendere il modello di ruoli e permessi
- Eseguire query SQL di base
- Caricare e interrogare dati

### Istruzioni Passo-Passo

#### Step 1.1: Accesso a Snowflake
1. Apri il browser e vai all'URL del tuo account Snowflake
2. Effettua il login con le credenziali fornite
3. Seleziona **Worksheets** dal menu laterale

#### Step 1.2: Creazione Database e Schema
```sql
-- Usa SYSADMIN per creare oggetti (best practice)
USE ROLE SYSADMIN;

-- Crea il database per il workshop
CREATE OR REPLACE DATABASE MEDIASET_LAB;

-- Crea gli schema necessari
CREATE OR REPLACE SCHEMA MEDIASET_LAB.RAW;
CREATE OR REPLACE SCHEMA MEDIASET_LAB.ANALYTICS;
CREATE OR REPLACE SCHEMA MEDIASET_LAB.SECURITY;
```

**Verifica:** Esegui `SHOW SCHEMAS IN DATABASE MEDIASET_LAB;`

#### Step 1.3: Creazione Warehouse
```sql
-- Usa SYSADMIN per creare warehouse (best practice)
USE ROLE SYSADMIN;

CREATE OR REPLACE WAREHOUSE MEDIASET_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;
```

**Nota:** Il warehouse si attiverà automaticamente alla prima query.

#### Step 1.4: Creazione Ruoli
```sql
-- Usa SECURITYADMIN per gestire ruoli (best practice)
USE ROLE SECURITYADMIN;

-- Crea i ruoli custom
CREATE OR REPLACE ROLE MEDIASET_ADMIN;
CREATE OR REPLACE ROLE MEDIASET_ANALYST;
CREATE OR REPLACE ROLE MEDIASET_MARKETING;
CREATE OR REPLACE ROLE MEDIASET_REGIONALE_NORD;
CREATE OR REPLACE ROLE MEDIASET_REGIONALE_SUD;

-- BEST PRACTICE: I ruoli custom devono riportare a SYSADMIN
-- Questo garantisce che SYSADMIN possa gestire tutti gli oggetti
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
```

**Best Practice:** Tutti i ruoli custom devono essere assegnati a SYSADMIN per mantenere la gerarchia standard di Snowflake.

#### Step 1.5: Caricamento Dati
Esegui lo script completo `01_setup.sql` per caricare tutti i dati sintetici.

#### Step 1.6: Query di Verifica
```sql
-- Verifica le tabelle create
SHOW TABLES IN SCHEMA MEDIASET_LAB.RAW;

-- Query sui programmi TV
SELECT titolo, genere, canale, costo_episodio_eur
FROM MEDIASET_LAB.RAW.PROGRAMMI_TV
ORDER BY costo_episodio_eur DESC
LIMIT 5;

-- Analisi ascolti per regione
SELECT 
    regione,
    AVG(share_percentuale) as share_medio,
    SUM(telespettatori) as telespettatori_totali
FROM MEDIASET_LAB.RAW.ASCOLTI
GROUP BY regione
ORDER BY share_medio DESC;
```

### Esercizio Pratico 1
Scrivi una query che mostri i top 5 programmi per share medio, includendo genere e canale.

---

## Modulo 2: Row & Column Level Security (35 min)

> Le **Masking Policy** nascondono o offuscano dati sensibili (PII) a livello di colonna in base al ruolo dell'utente. Le **Row Access Policy** filtrano automaticamente le righe visibili, garantendo che ogni utente veda solo i dati di sua competenza senza modificare le query.

### Obiettivi di Apprendimento
- Implementare masking policy per proteggere dati sensibili
- Creare row access policy per filtrare dati per ruolo
- Testare le policy con ruoli diversi

### Istruzioni Passo-Passo

#### Step 2.1: Creazione Masking Policy per Email
```sql
USE SCHEMA MEDIASET_LAB.SECURITY;

CREATE OR REPLACE MASKING POLICY email_mask AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN', 'ACCOUNTADMIN') THEN val
        WHEN CURRENT_ROLE() = 'MEDIASET_MARKETING' THEN 
            REGEXP_REPLACE(val, '(.{2})(.*)(@.*)', '\\1***\\3')
        ELSE '***RISERVATO***'
    END;
```

#### Step 2.2: Applicazione della Policy
```sql
ALTER TABLE MEDIASET_LAB.RAW.ABBONATI 
    MODIFY COLUMN email SET MASKING POLICY email_mask;
```

#### Step 2.3: Test con Ruoli Diversi
```sql
-- Test come ADMIN (vede tutto)
USE ROLE MEDIASET_ADMIN;
SELECT nome, cognome, email FROM MEDIASET_LAB.RAW.ABBONATI LIMIT 5;

-- Test come MARKETING (vede parzialmente)
USE ROLE MEDIASET_MARKETING;
SELECT nome, cognome, email FROM MEDIASET_LAB.RAW.ABBONATI LIMIT 5;

-- Test come ANALYST (vede mascherato)
USE ROLE MEDIASET_ANALYST;
SELECT nome, cognome, email FROM MEDIASET_LAB.RAW.ABBONATI LIMIT 5;
```

#### Step 2.4: Row Access Policy
```sql
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
        WHEN EXISTS (
            SELECT 1 FROM MEDIASET_LAB.SECURITY.ROLE_REGION_MAPPING 
            WHERE role_name = CURRENT_ROLE() AND regione = regione_col
        ) THEN TRUE
        ELSE FALSE
    END;

-- Applica la policy
ALTER TABLE MEDIASET_LAB.RAW.ASCOLTI 
    ADD ROW ACCESS POLICY region_access_policy ON (regione);
```

#### Step 2.5: Test Row Access Policy
```sql
-- Come REGIONALE_NORD vedo solo regioni del nord
USE ROLE MEDIASET_REGIONALE_NORD;
SELECT DISTINCT regione FROM MEDIASET_LAB.RAW.ASCOLTI;

-- Come REGIONALE_SUD vedo solo regioni del sud
USE ROLE MEDIASET_REGIONALE_SUD;
SELECT DISTINCT regione FROM MEDIASET_LAB.RAW.ASCOLTI;
```

### Esercizio Pratico 2
Crea una masking policy per il campo `telefono` che mostri solo le prime 6 cifre ai ruoli non admin.

---

## Modulo 3: Data Pipelines con Dynamic Tables (30 min)

> Le **Dynamic Tables** sono tabelle che si aggiornano automaticamente quando cambiano i dati sorgente. Definisci la trasformazione SQL una volta e Snowflake gestisce il refresh incrementale. Ideali per pipeline ETL declarative senza orchestrazione esterna.

### Obiettivi di Apprendimento
- Comprendere il concetto di Dynamic Tables
- Creare pipeline di trasformazione dati automatiche
- Monitorare lo stato delle Dynamic Tables

### Istruzioni Passo-Passo

#### Step 3.1: Prima Dynamic Table - Ascolti Giornalieri
```sql
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
```

#### Step 3.2: Dynamic Table a Cascata - Top Settimanali
```sql
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
```

#### Step 3.3: Verifica e Monitoraggio
```sql
-- Visualizza lo stato
SHOW DYNAMIC TABLES IN SCHEMA MEDIASET_LAB.ANALYTICS;

-- Query sulla dynamic table
SELECT * FROM TOP_PROGRAMMI_SETTIMANA 
ORDER BY settimana DESC, rank;
```

#### Step 3.4: Simulazione Aggiornamento
```sql
-- Inserisci nuovi dati
INSERT INTO MEDIASET_LAB.RAW.ASCOLTI VALUES
(99999, 1, 2, CURRENT_DATE(), 'Prime Time', 'Lombardia', 3500000, 28.5, 'Adulti', 'Smart TV');

-- Forza refresh (opzionale per demo)
ALTER DYNAMIC TABLE ASCOLTI_GIORNALIERI REFRESH;

-- Verifica aggiornamento
SELECT * FROM ASCOLTI_GIORNALIERI WHERE data_rilevazione = CURRENT_DATE();
```

### Esercizio Pratico 3
Crea una Dynamic Table che calcoli i KPI pubblicitari aggregati per settore merceologico.

---

## Modulo 4: Cortex AI SQL Functions (25 min)

> **Cortex AI Functions** sono funzioni SQL native che integrano modelli LLM direttamente nelle query. Analizza sentiment, classifica testi, genera riassunti, traduci contenuti e crea testo con AI—tutto senza uscire da SQL e senza infrastruttura ML da gestire.

### Obiettivi di Apprendimento
- Utilizzare funzioni AI integrate in SQL
- Analizzare sentiment di testi
- Classificare e riassumere contenuti
- Generare testo con LLM

### Istruzioni Passo-Passo

#### Step 4.1: Analisi Sentiment
```sql
USE SCHEMA MEDIASET_LAB.RAW;

-- Sentiment dei feedback social
SELECT 
    f.testo_feedback,
    p.titolo,
    SNOWFLAKE.CORTEX.SENTIMENT(f.testo_feedback) as sentiment
FROM FEEDBACK_SOCIAL f
JOIN PROGRAMMI_TV p ON f.programma_id = p.programma_id
ORDER BY sentiment DESC;
```

#### Step 4.2: Classificazione Contenuti
```sql
-- Classifica feedback per categoria
SELECT 
    testo_feedback,
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
        testo_feedback,
        ['Positivo', 'Negativo', 'Neutro', 'Critica Costruttiva']
    ) as categoria
FROM FEEDBACK_SOCIAL
LIMIT 10;
```

#### Step 4.3: Riassunto Automatico
```sql
-- Riassumi descrizioni programmi
SELECT 
    titolo,
    SNOWFLAKE.CORTEX.SUMMARIZE(descrizione_completa) as riassunto
FROM CONTENUTI_DESCRIZIONI
WHERE LENGTH(descrizione_completa) > 200
LIMIT 5;
```

#### Step 4.4: Traduzione
```sql
-- Traduci in inglese
SELECT 
    titolo,
    descrizione_breve,
    SNOWFLAKE.CORTEX.TRANSLATE(descrizione_breve, 'it', 'en') as english
FROM CONTENUTI_DESCRIZIONI
LIMIT 3;
```

#### Step 4.5: Generazione Testo con LLM
```sql
-- Genera tagline promozionali
SELECT 
    titolo,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        'Genera una tagline accattivante in italiano per: ' || titolo
    ) as tagline
FROM CONTENUTI_DESCRIZIONI
LIMIT 3;
```

### Esercizio Pratico 4
Crea una query che identifichi i feedback negativi e generi suggerimenti di miglioramento usando AI_COMPLETE.

---

## Modulo 5: Semantic Views & Cortex Analyst (40 min)

> Le **Semantic Views** definiscono metriche e dimensioni di business in modo centralizzato, garantendo definizioni consistenti. **Cortex Analyst** usa queste definizioni per tradurre domande in linguaggio naturale in SQL corretto, permettendo a utenti non tecnici di interrogare i dati.

### Obiettivi di Apprendimento
- Creare Semantic Views per definire metriche di business
- Configurare dimensioni e facts
- Utilizzare Cortex Analyst per query in linguaggio naturale

### Istruzioni Passo-Passo

#### Step 5.1: Creazione Semantic View
```sql
USE SCHEMA MEDIASET_LAB.ANALYTICS;

CREATE OR REPLACE SEMANTIC VIEW SV_ANALISI_ASCOLTI
AS SEMANTIC MODEL
  TABLES (
    PROGRAMMI AS (
      SELECT programma_id, titolo, genere, canale, costo_episodio_eur
      FROM MEDIASET_LAB.RAW.PROGRAMMI_TV
      PRIMARY KEY (programma_id)
      FACTS (costo_episodio_eur SYNONYMS ('costo', 'budget'))
      DIMENSIONS (
        titolo SYNONYMS ('nome programma', 'show'),
        genere SYNONYMS ('tipo', 'categoria'),
        canale SYNONYMS ('rete', 'emittente')
      )
    ),
    ASCOLTI AS (
      SELECT ascolto_id, programma_id, data_rilevazione, regione, 
             telespettatori, share_percentuale, fascia_oraria
      FROM MEDIASET_LAB.RAW.ASCOLTI
      PRIMARY KEY (ascolto_id)
      FACTS (
        telespettatori SYNONYMS ('spettatori', 'audience'),
        share_percentuale SYNONYMS ('share', 'quota')
      )
      DIMENSIONS (
        data_rilevazione SYNONYMS ('data', 'giorno'),
        regione SYNONYMS ('area', 'territorio'),
        fascia_oraria SYNONYMS ('orario', 'slot')
      )
    )
  )
  RELATIONSHIPS (
    ASCOLTI (programma_id) REFERENCES PROGRAMMI (programma_id)
  )
  METRICS (
    TELESPETTATORI_TOTALI AS (
      SUM(ASCOLTI.telespettatori) 
      SYNONYMS ('audience totale', 'spettatori totali')
    ),
    SHARE_MEDIO AS (
      AVG(ASCOLTI.share_percentuale) 
      SYNONYMS ('share medio', 'media share')
    )
  );
```

#### Step 5.2: Query sulla Semantic View
```sql
-- Query usando le metriche definite
SELECT 
    PROGRAMMI.titolo,
    PROGRAMMI.genere,
    TELESPETTATORI_TOTALI,
    SHARE_MEDIO
FROM SEMANTIC VIEW SV_ANALISI_ASCOLTI
GROUP BY PROGRAMMI.titolo, PROGRAMMI.genere
ORDER BY SHARE_MEDIO DESC
LIMIT 10;
```

#### Step 5.3: Cortex Analyst (via Snowsight)
1. Vai su **AI & ML** > **Cortex Analyst**
2. Seleziona la Semantic View `SV_ANALISI_ASCOLTI`
3. Prova queste domande:
   - "Qual è il programma con lo share più alto?"
   - "Mostrami gli ascolti per regione"
   - "Top 5 programmi in prime time"
   - "Confronta gli ascolti di Canale 5 e Italia 1"

### Esercizio Pratico 5
Crea una Semantic View per l'analisi commerciale con metriche su budget pubblicitario e numero contratti.

---

## Modulo 6: Cortex Search & Snowflake Intelligence (25 min)

> **Cortex Search** abilita ricerche semantiche sui dati testuali: trova contenuti per significato, non solo keyword. **Snowflake Intelligence** è l'assistente AI integrato che risponde a domande sui tuoi dati in linguaggio naturale, combinando Cortex Analyst e Search.

### Obiettivi di Apprendimento
- Creare servizi di ricerca semantica
- Eseguire query in linguaggio naturale
- Esplorare Snowflake Intelligence

### Istruzioni Passo-Passo

#### Step 6.1: Creazione Cortex Search Service
```sql
USE SCHEMA MEDIASET_LAB.RAW;

-- Crea vista con testo ricercabile
CREATE OR REPLACE VIEW V_CONTENUTI_RICERCABILI AS
SELECT 
    c.contenuto_id,
    c.titolo,
    p.genere,
    p.canale,
    c.descrizione_completa,
    CONCAT(c.titolo, ' ', c.descrizione_completa, ' ', c.parole_chiave) as testo_ricercabile
FROM CONTENUTI_DESCRIZIONI c
JOIN PROGRAMMI_TV p ON c.programma_id = p.programma_id;

-- Crea il servizio di ricerca
CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_PROGRAMMI
  ON testo_ricercabile
  ATTRIBUTES titolo, genere, canale
  WAREHOUSE = MEDIASET_WH
  TARGET_LAG = '1 hour'
AS (SELECT * FROM V_CONTENUTI_RICERCABILI);
```

#### Step 6.2: Ricerche Semantiche
```sql
-- Cerca programmi per famiglie
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "programmi divertenti per famiglie",
        "columns": ["titolo", "genere", "canale"],
        "limit": 5
    }'
);

-- Cerca reality show
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{
        "query": "reality show amore coppie",
        "columns": ["titolo", "genere"],
        "limit": 5
    }'
);
```

#### Step 6.3: Snowflake Intelligence
1. Vai su **AI & ML** > **Snowflake Intelligence**
2. Prova domande come:
   - "Mostrami i programmi con il budget più alto"
   - "Quali sono i trend di ascolto per fascia oraria?"
   - "Confronta le performance dei diversi canali"

### Esercizio Pratico 6
Crea un Cortex Search Service sui feedback social e cerca i commenti relativi a specifici conduttori.

---

## Riepilogo e Best Practices

### Cosa Abbiamo Imparato
1. **Snowflake Basics**: Database, Schema, Warehouse, Ruoli
2. **Security**: Masking Policy, Row Access Policy
3. **Pipelines**: Dynamic Tables per ETL automatico
4. **AI SQL**: Sentiment, Classification, Summarization, Translation
5. **Semantic Views**: Metriche di business, Cortex Analyst
6. **Search**: Ricerca semantica con Cortex Search

### Best Practices
- Usa ruoli specifici per ogni tipo di utente
- Implementa masking su tutti i dati sensibili (PII)
- Preferisci Dynamic Tables per trasformazioni ricorrenti
- Definisci metriche consistenti nelle Semantic Views
- Sfrutta le AI functions per arricchire i dati

### Risorse Utili
- [Documentazione Snowflake](https://docs.snowflake.com)
- [Snowflake Community](https://community.snowflake.com)
- [Cortex AI Functions](https://docs.snowflake.com/en/user-guide/snowflake-cortex)
- [Semantic Views](https://docs.snowflake.com/en/user-guide/views-semantic)

---

## Cleanup (Opzionale)

Se desideri rimuovere tutti gli oggetti creati:

```sql
USE ROLE ACCOUNTADMIN;

-- Rimuovi il database (elimina tutto)
DROP DATABASE IF EXISTS MEDIASET_LAB;

-- Rimuovi i ruoli
DROP ROLE IF EXISTS MEDIASET_ADMIN;
DROP ROLE IF EXISTS MEDIASET_ANALYST;
DROP ROLE IF EXISTS MEDIASET_MARKETING;
DROP ROLE IF EXISTS MEDIASET_REGIONALE_NORD;
DROP ROLE IF EXISTS MEDIASET_REGIONALE_SUD;

-- Rimuovi il warehouse
DROP WAREHOUSE IF EXISTS MEDIASET_WH;
```

---

**Grazie per aver partecipato al workshop!**

Per domande o supporto: [inserire contatto]
