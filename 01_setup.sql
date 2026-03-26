-- ============================================================================
-- MEDIASET SNOWFLAKE WORKSHOP - SETUP
-- Modulo 1: Configurazione ambiente e dati sintetici
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
-- SEZIONE 5: INSERIMENTO DATI SINTETICI
-- ============================================================================

INSERT INTO PROGRAMMI_TV VALUES
(1, 'Italia in Diretta', 'Informazione', 'Canale 5', 120, 2018, 'Mediaset', '25-54', 85000.00, 'TV-G'),
(2, 'Grande Fratello VIP', 'Reality', 'Canale 5', 180, 2016, 'Endemol Shine Italy', '18-49', 250000.00, 'TV-14'),
(3, 'Striscia la Notizia', 'Satira', 'Canale 5', 30, 1988, 'Mediaset', '18-65', 120000.00, 'TV-G'),
(4, 'TGCOM24', 'News', 'TGCom24', 30, 2011, 'Mediaset', '25-65', 45000.00, 'TV-G'),
(5, 'Le Iene', 'Inchiesta', 'Italia 1', 150, 1997, 'Mediaset', '18-45', 180000.00, 'TV-14'),
(6, 'Verissimo', 'Talk Show', 'Canale 5', 120, 1996, 'Mediaset', '25-54', 95000.00, 'TV-G'),
(7, 'Amici di Maria De Filippi', 'Talent', 'Canale 5', 150, 2001, 'Fascino PGT', '15-45', 200000.00, 'TV-G'),
(8, 'Uomini e Donne', 'Dating', 'Canale 5', 90, 1996, 'Fascino PGT', '18-54', 75000.00, 'TV-G'),
(9, 'Chi Vuol Essere Milionario', 'Quiz', 'Canale 5', 90, 2000, 'Endemol', '25-65', 110000.00, 'TV-G'),
(10, 'Forum', 'Legal Show', 'Rete 4', 90, 1985, 'Corima', '35-65', 55000.00, 'TV-G'),
(11, 'Caduta Libera', 'Quiz', 'Canale 5', 60, 2015, 'Endemol', '18-65', 85000.00, 'TV-G'),
(12, 'Mattino Cinque', 'Informazione', 'Canale 5', 180, 2008, 'Videonews', '25-65', 65000.00, 'TV-G'),
(13, 'Pomeriggio Cinque', 'Infotainment', 'Canale 5', 120, 2008, 'Videonews', '25-65', 70000.00, 'TV-G'),
(14, 'Quarta Repubblica', 'Talk Politico', 'Rete 4', 150, 2018, 'Videonews', '35-65', 90000.00, 'TV-G'),
(15, 'Colorado', 'Comico', 'Italia 1', 120, 2003, 'Mediaset', '15-45', 130000.00, 'TV-G'),
(16, 'Tu Si Que Vales', 'Talent', 'Canale 5', 180, 2014, 'Fascino PGT', '15-65', 220000.00, 'TV-G'),
(17, 'Avanti un Altro', 'Quiz', 'Canale 5', 60, 2011, 'SDL', '18-65', 75000.00, 'TV-G'),
(18, 'La Pupa e il Secchione', 'Reality', 'Italia 1', 120, 2006, 'Endemol', '18-35', 140000.00, 'TV-14'),
(19, 'Temptation Island', 'Reality', 'Canale 5', 120, 2014, 'Fascino PGT', '18-45', 160000.00, 'TV-14'),
(20, 'Paperissima Sprint', 'Comico', 'Canale 5', 30, 1990, 'Mediaset', '6-65', 35000.00, 'TV-G');

INSERT INTO PALINSESTO 
SELECT 
    ROW_NUMBER() OVER (ORDER BY p.programma_id, d.data_trasmissione),
    p.programma_id,
    d.data_trasmissione,
    CASE 
        WHEN p.genere IN ('News', 'Informazione') THEN '07:00:00'::TIME
        WHEN p.genere IN ('Quiz', 'Dating') THEN '18:30:00'::TIME
        WHEN p.genere IN ('Reality', 'Talent', 'Talk Show') THEN '21:30:00'::TIME
        WHEN p.genere = 'Satira' THEN '20:30:00'::TIME
        ELSE '14:00:00'::TIME
    END as ora_inizio,
    CASE 
        WHEN p.genere IN ('News', 'Informazione') THEN '09:00:00'::TIME
        WHEN p.genere IN ('Quiz', 'Dating') THEN '20:00:00'::TIME
        WHEN p.genere IN ('Reality', 'Talent', 'Talk Show') THEN '00:00:00'::TIME
        WHEN p.genere = 'Satira' THEN '21:00:00'::TIME
        ELSE '16:00:00'::TIME
    END as ora_fine,
    p.canale,
    CASE WHEN MOD(d.seq, 7) = 0 THEN 'Prima TV' ELSE 'Replica' END,
    2024,
    MOD(d.seq, 24) + 1
FROM PROGRAMMI_TV p
CROSS JOIN (
    SELECT DATEADD(day, seq4(), '2024-01-01'::DATE) as data_trasmissione, seq4() as seq
    FROM TABLE(GENERATOR(ROWCOUNT => 90))
) d
WHERE MOD(d.seq + p.programma_id, 3) = 0;

INSERT INTO ASCOLTI
SELECT
    ROW_NUMBER() OVER (ORDER BY pal.palinsesto_id, reg.regione),
    pal.palinsesto_id,
    pal.programma_id,
    pal.data_trasmissione,
    CASE 
        WHEN HOUR(pal.ora_inizio) < 12 THEN 'Mattina'
        WHEN HOUR(pal.ora_inizio) < 18 THEN 'Pomeriggio'
        WHEN HOUR(pal.ora_inizio) < 21 THEN 'Access Prime Time'
        ELSE 'Prime Time'
    END,
    reg.regione,
    UNIFORM(50000, 2000000, RANDOM()) as telespettatori,
    UNIFORM(5.0, 35.0, RANDOM())::DECIMAL(5,2) as share_percentuale,
    CASE MOD(ABS(HASH(pal.palinsesto_id || reg.regione)), 4)
        WHEN 0 THEN 'Responsabili Acquisto'
        WHEN 1 THEN 'Adulti 25-54'
        WHEN 2 THEN 'Giovani 15-34'
        ELSE 'Tutti'
    END,
    CASE MOD(ABS(HASH(reg.regione)), 3)
        WHEN 0 THEN 'TV Tradizionale'
        WHEN 1 THEN 'Smart TV'
        ELSE 'Streaming'
    END
FROM PALINSESTO pal
CROSS JOIN (
    SELECT column1 as regione FROM VALUES 
    ('Lombardia'), ('Lazio'), ('Campania'), ('Sicilia'), ('Veneto'),
    ('Piemonte'), ('Emilia-Romagna'), ('Puglia'), ('Toscana'), ('Calabria')
) reg
WHERE pal.palinsesto_id <= 500;

INSERT INTO ABBONATI VALUES
(1, 'Marco', 'Rossi', 'marco.rossi@email.it', '+39 02 1234567', 'Milano', 'Lombardia', '20121', '2022-03-15', 'Premium Plus', 19.99, 'Attivo', 'Canale 5, Italia 1'),
(2, 'Giulia', 'Bianchi', 'giulia.bianchi@email.it', '+39 06 2345678', 'Roma', 'Lazio', '00185', '2021-07-22', 'Premium', 14.99, 'Attivo', 'Canale 5, Rete 4'),
(3, 'Alessandro', 'Ferrari', 'a.ferrari@email.it', '+39 081 3456789', 'Napoli', 'Campania', '80121', '2023-01-10', 'Base', 9.99, 'Attivo', 'Canale 5'),
(4, 'Francesca', 'Romano', 'f.romano@email.it', '+39 011 4567890', 'Torino', 'Piemonte', '10121', '2022-11-05', 'Premium Plus', 19.99, 'Attivo', 'Italia 1, Canale 5'),
(5, 'Luca', 'Colombo', 'luca.colombo@email.it', '+39 051 5678901', 'Bologna', 'Emilia-Romagna', '40121', '2020-09-18', 'Premium', 14.99, 'Sospeso', 'Rete 4'),
(6, 'Sofia', 'Ricci', 'sofia.ricci@email.it', '+39 055 6789012', 'Firenze', 'Toscana', '50121', '2023-04-30', 'Base', 9.99, 'Attivo', 'Canale 5'),
(7, 'Matteo', 'Marino', 'matteo.marino@email.it', '+39 091 7890123', 'Palermo', 'Sicilia', '90121', '2021-12-01', 'Premium Plus', 19.99, 'Attivo', 'Canale 5, Italia 1, Rete 4'),
(8, 'Elena', 'Greco', 'elena.greco@email.it', '+39 010 8901234', 'Genova', 'Liguria', '16121', '2022-06-15', 'Premium', 14.99, 'Attivo', 'Italia 1'),
(9, 'Andrea', 'Bruno', 'andrea.bruno@email.it', '+39 041 9012345', 'Venezia', 'Veneto', '30121', '2023-02-28', 'Base', 9.99, 'Cancellato', 'Canale 5'),
(10, 'Chiara', 'Fontana', 'chiara.fontana@email.it', '+39 080 0123456', 'Bari', 'Puglia', '70121', '2021-08-10', 'Premium Plus', 19.99, 'Attivo', 'Canale 5, Rete 4'),
(11, 'Giuseppe', 'Conti', 'g.conti@email.it', '+39 095 1234560', 'Catania', 'Sicilia', '95121', '2022-05-20', 'Premium', 14.99, 'Attivo', 'Italia 1'),
(12, 'Valentina', 'De Luca', 'v.deluca@email.it', '+39 079 2345601', 'Sassari', 'Sardegna', '07100', '2023-03-12', 'Base', 9.99, 'Attivo', 'Canale 5'),
(13, 'Davide', 'Mancini', 'd.mancini@email.it', '+39 0965 345612', 'Reggio Calabria', 'Calabria', '89121', '2020-11-30', 'Premium Plus', 19.99, 'Sospeso', 'Canale 5, Italia 1'),
(14, 'Martina', 'Barbieri', 'm.barbieri@email.it', '+39 0432 456123', 'Udine', 'Friuli-Venezia Giulia', '33100', '2022-09-08', 'Premium', 14.99, 'Attivo', 'Rete 4'),
(15, 'Simone', 'Galli', 's.galli@email.it', '+39 0461 567234', 'Trento', 'Trentino-Alto Adige', '38121', '2023-07-01', 'Base', 9.99, 'Attivo', 'Canale 5'),
(16, 'Federica', 'Costa', 'f.costa@email.it', '+39 0185 678345', 'La Spezia', 'Liguria', '19121', '2021-04-25', 'Premium Plus', 19.99, 'Attivo', 'Canale 5, Italia 1'),
(17, 'Lorenzo', 'Giordano', 'l.giordano@email.it', '+39 0984 789456', 'Cosenza', 'Calabria', '87100', '2022-02-14', 'Premium', 14.99, 'Cancellato', 'Italia 1'),
(18, 'Alessia', 'Rizzo', 'a.rizzo@email.it', '+39 0831 890567', 'Brindisi', 'Puglia', '72100', '2023-06-18', 'Base', 9.99, 'Attivo', 'Canale 5'),
(19, 'Pietro', 'Lombardi', 'p.lombardi@email.it', '+39 0382 901678', 'Pavia', 'Lombardia', '27100', '2020-08-05', 'Premium Plus', 19.99, 'Attivo', 'Canale 5, Rete 4'),
(20, 'Sara', 'Moretti', 's.moretti@email.it', '+39 0721 012789', 'Pesaro', 'Marche', '61121', '2022-12-20', 'Premium', 14.99, 'Attivo', 'Italia 1');

INSERT INTO CONTENUTI_DESCRIZIONI VALUES
(1, 1, 'Italia in Diretta', 'Programma di informazione e attualità', 'Italia in Diretta è il programma di informazione di Canale 5 che ogni giorno racconta l''attualità italiana attraverso collegamenti in diretta, interviste esclusive e approfondimenti. Condotto da giornalisti esperti, il programma affronta temi di cronaca, politica, costume e società con un linguaggio accessibile a tutti.', 'attualità, informazione, cronaca, italia, diretta', 'Alberto Matano, Lorella Cuccarini', 'Staff Mediaset', 2018, 'Italia', 'Italiano', 'Italiano'),
(2, 2, 'Grande Fratello VIP', 'Reality show con personaggi famosi', 'Il Grande Fratello VIP è la versione celebrity del celebre format televisivo. Personaggi famosi del mondo dello spettacolo, della musica e dello sport convivono in una casa monitorata 24 ore su 24. Intrighi, amori, litigi e alleanze si susseguono in un mix esplosivo di emozioni e colpi di scena che tiene incollati milioni di telespettatori.', 'reality, vip, celebrity, casa, diretta, eliminazione', 'Alfonso Signorini', 'Endemol', 2016, 'Italia', 'Italiano', 'Italiano, Inglese'),
(3, 3, 'Striscia la Notizia', 'Telegiornale satirico', 'Striscia la Notizia è il TG satirico più longevo della televisione italiana. Con ironia e graffiante satira, il programma denuncia sprechi, truffe e malcostume italiano. Le celebri inchieste dei suoi inviati hanno fatto storia, smascherando situazioni al limite della legalità sempre con il sorriso.', 'satira, tg, inchiesta, velina, gabibbo', 'Ezio Greggio, Enzo Iacchetti', 'Antonio Ricci', 1988, 'Italia', 'Italiano', 'Italiano'),
(4, 4, 'TGCOM24', 'Canale all-news 24 ore', 'TGCOM24 è il canale all-news di Mediaset che fornisce informazione continua 24 ore su 24. Breaking news, approfondimenti, interviste e collegamenti in diretta dai luoghi delle notizie. Un punto di riferimento per chi vuole essere sempre aggiornato su politica, economia, sport e spettacolo.', 'news, breaking, 24ore, informazione, diretta', 'Staff TGCOM', 'Mediaset', 2011, 'Italia', 'Italiano', 'Italiano'),
(5, 5, 'Le Iene', 'Programma di inchieste e intrattenimento', 'Le Iene è il programma cult di Italia 1 che mescola inchieste giornalistiche, scherzi alle celebrità e servizi di denuncia. Gli inviati in giacca e cravatta nera sono diventati un''icona della televisione italiana, portando alla luce scandali e storie che hanno fatto discutere l''opinione pubblica.', 'inchiesta, scherzi, denuncia, iene, servizi', 'Nicola Savino, Alessia Marcuzzi', 'Davide Parenti', 1997, 'Italia', 'Italiano', 'Italiano'),
(6, 6, 'Verissimo', 'Talk show del sabato pomeriggio', 'Verissimo è il talk show condotto da Silvia Toffanin che ogni weekend accoglie celebrità, artisti e personaggi del momento per interviste esclusive e toccanti. Storie di vita, successi, amori e difficoltà raccontate in un''atmosfera intima che emoziona il pubblico da oltre 25 anni.', 'talk show, interviste, celebrity, emozioni, weekend', 'Silvia Toffanin', 'Mediaset', 1996, 'Italia', 'Italiano', 'Italiano'),
(7, 7, 'Amici di Maria De Filippi', 'Talent show musicale e di danza', 'Amici è il talent show più longevo d''Italia, una vera e propria scuola di spettacolo che ha lanciato artisti come Emma, Alessandra Amoroso e molti altri. Giovani talenti si sfidano in prove di canto e ballo sotto la guida di professori esperti, in un percorso di crescita artistica e personale.', 'talent, musica, danza, scuola, giovani, sfide', 'Maria De Filippi', 'Fascino PGT', 2001, 'Italia', 'Italiano', 'Italiano'),
(8, 8, 'Uomini e Donne', 'Dating show', 'Uomini e Donne è il dating show di Maria De Filippi dove tronisti e corteggiatori cercano l''anima gemella. Tra esterne romantiche, discussioni accese e colpi di scena, il programma racconta la ricerca dell''amore in tutte le sue sfumature, dal trono classico a quello over.', 'dating, amore, tronista, corteggiatore, scelta', 'Maria De Filippi', 'Fascino PGT', 1996, 'Italia', 'Italiano', 'Italiano'),
(9, 9, 'Chi Vuol Essere Milionario', 'Quiz show', 'Chi Vuol Essere Milionario è il quiz show che ha fatto la storia della televisione mondiale. I concorrenti devono rispondere a 15 domande di cultura generale di difficoltà crescente per vincere il montepremi finale. Tensione, emozione e colpi di scena in ogni puntata.', 'quiz, cultura, domande, milionario, gerry scotti', 'Gerry Scotti', 'Endemol', 2000, 'Italia', 'Italiano', 'Italiano'),
(10, 10, 'Forum', 'Programma di casi legali', 'Forum è il programma che simula un tribunale televisivo dove attori interpretano casi ispirati a situazioni reali. Questioni di diritto civile e familiare vengono dibattute davanti a veri giudici, offrendo al pubblico informazione legale in modo accessibile e coinvolgente.', 'tribunale, legge, casi, giudice, diritto', 'Barbara Palombelli', 'Corima', 1985, 'Italia', 'Italiano', 'Italiano'),
(11, 11, 'Caduta Libera', 'Game show', 'Caduta Libera è il game show condotto da Gerry Scotti dove i concorrenti devono rispondere correttamente per non precipitare dalla botola. Quiz, cultura generale e velocità di riflessi in un format adrenalinico che tiene incollati allo schermo grandi e piccini.', 'quiz, botola, gerry scotti, game show', 'Gerry Scotti', 'Endemol', 2015, 'Italia', 'Italiano', 'Italiano'),
(12, 12, 'Mattino Cinque', 'Programma mattutino di informazione', 'Mattino Cinque è il contenitore mattutino di Canale 5 che accompagna gli italiani nella prima parte della giornata. Attualità, cronaca, gossip e rubriche di servizio si alternano in un mix informativo e leggero condotto con professionalità e simpatia.', 'mattina, informazione, attualità, gossip', 'Federica Panicucci, Francesco Vecchi', 'Videonews', 2008, 'Italia', 'Italiano', 'Italiano'),
(13, 13, 'Pomeriggio Cinque', 'Contenitore pomeridiano', 'Pomeriggio Cinque è il programma che intrattiene il pubblico nelle ore pomeridiane con un mix di cronaca, attualità e gossip. Barbara d''Urso ha reso il format un appuntamento imperdibile per milioni di telespettatori, trattando i temi caldi del momento con il suo stile inconfondibile.', 'pomeriggio, cronaca, gossip, attualità', 'Myrta Merlino', 'Videonews', 2008, 'Italia', 'Italiano', 'Italiano'),
(14, 14, 'Quarta Repubblica', 'Talk show politico', 'Quarta Repubblica è il talk show di approfondimento politico ed economico di Rete 4. Nicola Porro conduce dibattiti accesi tra esponenti politici, giornalisti e opinionisti sui temi più controversi dell''attualità italiana e internazionale.', 'politica, economia, dibattito, approfondimento', 'Nicola Porro', 'Videonews', 2018, 'Italia', 'Italiano', 'Italiano'),
(15, 15, 'Colorado', 'Programma comico', 'Colorado è lo show comico di Italia 1 che ha lanciato generazioni di comici italiani. Dal palco del teatro, i migliori talenti della risata si esibiscono in sketch, monologhi e gag esilaranti che fanno ridere tutta la famiglia.', 'comicità, sketch, risate, teatro, cabaret', 'Paolo Ruffini, Belen Rodriguez', 'Mediaset', 2003, 'Italia', 'Italiano', 'Italiano'),
(16, 16, 'Tu Si Que Vales', 'Talent show varietà', 'Tu Si Que Vales è il talent show che celebra ogni forma di talento. Cantanti, ballerini, acrobati, maghi e performer di ogni tipo si esibiscono davanti alla giuria per conquistare il pubblico e vincere il ricco montepremi finale.', 'talent, varietà, esibizioni, giuria, talento', 'Maria De Filippi, Gerry Scotti, Rudy Zerbi, Teo Mammucari', 'Fascino PGT', 2014, 'Italia', 'Italiano', 'Italiano'),
(17, 17, 'Avanti un Altro', 'Quiz show comico', 'Avanti un Altro è il quiz show più pazzo della televisione italiana. Paolo Bonolis guida i concorrenti attraverso domande surreali, personaggi bizzarri e situazioni esilaranti nel tentativo di conquistare il montepremi finale.', 'quiz, comicità, paolo bonolis, gioco', 'Paolo Bonolis, Luca Laurenti', 'SDL', 2011, 'Italia', 'Italiano', 'Italiano'),
(18, 18, 'La Pupa e il Secchione', 'Reality show', 'La Pupa e il Secchione è il reality che mette insieme ragazze belle ma poco istruite con ragazzi intelligenti ma impacciati. Un esperimento sociale divertente dove i concorrenti devono imparare gli uni dagli altri, creando coppie improbabili ma vincenti.', 'reality, pupe, secchioni, coppie, sfide', 'Andrea Pucci', 'Endemol', 2006, 'Italia', 'Italiano', 'Italiano'),
(19, 19, 'Temptation Island', 'Reality sentimentale', 'Temptation Island mette alla prova l''amore di coppie non sposate in un resort paradisiaco. Separati e circondati da tentatori e tentatrici single, i fidanzati devono resistere alle tentazioni per uscire insieme dal programma più forti di prima.', 'reality, coppie, tentazione, amore, isola', 'Filippo Bisciglia', 'Fascino PGT', 2014, 'Italia', 'Italiano', 'Italiano'),
(20, 20, 'Paperissima Sprint', 'Programma di video divertenti', 'Paperissima Sprint raccoglie i video amatoriali più divertenti inviati dai telespettatori. Cadute, papere, animali buffi e situazioni esilaranti commentate con ironia per un appuntamento leggero adatto a tutta la famiglia.', 'video, papere, divertente, famiglia', 'Vittorio Brumotti', 'Mediaset', 1990, 'Italia', 'Italiano', 'Italiano');

INSERT INTO CONTRATTI_PUBBLICITARI VALUES
(1, 'Barilla S.p.A.', 'WPP Italia', '2024-01-01', '2024-12-31', 2500000.00, 'Canale 5', 'Prime Time', 'Brand Awareness', 'Alimentare', 'Giovanni Rana', 'g.rana@barilla.it', 'Attivo'),
(2, 'FIAT Automobiles', 'Publicis Italy', '2024-02-01', '2024-07-31', 3200000.00, 'Tutti i canali', 'Access Prime Time', 'Lancio Prodotto', 'Automotive', 'Laura Verdi', 'l.verdi@fiat.it', 'Attivo'),
(3, 'TIM S.p.A.', 'Havas Media', '2024-01-15', '2024-06-30', 1800000.00, 'Italia 1', 'Prime Time', 'Promozione', 'Telecomunicazioni', 'Marco Blu', 'm.blu@tim.it', 'Completato'),
(4, 'Ferrero S.p.A.', 'OMD Italy', '2024-03-01', '2024-12-31', 4500000.00, 'Canale 5', 'Pomeriggio', 'Brand Awareness', 'Alimentare', 'Anna Nocciola', 'a.nocciola@ferrero.it', 'Attivo'),
(5, 'Vodafone Italia', 'Mindshare', '2024-04-01', '2024-09-30', 2100000.00, 'Rete 4', 'Mattina', 'Promozione', 'Telecomunicazioni', 'Paolo Rosso', 'p.rosso@vodafone.it', 'Attivo'),
(6, 'Esselunga', 'Dentsu Italy', '2024-01-01', '2024-12-31', 1500000.00, 'Canale 5', 'Access Prime Time', 'Retail', 'GDO', 'Lucia Spesa', 'l.spesa@esselunga.it', 'Attivo'),
(7, 'Enel S.p.A.', 'GroupM', '2024-05-01', '2024-10-31', 1900000.00, 'TGCom24', 'Tutto il giorno', 'Corporate', 'Energia', 'Roberto Verde', 'r.verde@enel.it', 'Attivo'),
(8, 'Luxottica', 'Starcom', '2024-06-01', '2024-08-31', 2800000.00, 'Canale 5', 'Prime Time', 'Lancio Prodotto', 'Moda', 'Silvia Occhiali', 's.occhiali@luxottica.it', 'Pianificato'),
(9, 'Generali Assicurazioni', 'Zenith', '2024-02-15', '2024-11-30', 1600000.00, 'Rete 4', 'Prime Time', 'Brand Awareness', 'Assicurazioni', 'Franco Polizza', 'f.polizza@generali.it', 'Attivo'),
(10, 'Lavazza', 'Wavemaker', '2024-01-01', '2024-12-31', 2200000.00, 'Italia 1', 'Mattina', 'Brand Awareness', 'Alimentare', 'Carla Caffe', 'c.caffe@lavazza.it', 'Attivo'),
(11, 'Intesa Sanpaolo', 'PHD Italy', '2024-03-15', '2024-09-15', 1400000.00, 'Canale 5', 'Access Prime Time', 'Corporate', 'Bancario', 'Antonio Banca', 'a.banca@intesasanpaolo.it', 'Attivo'),
(12, 'Wind Tre', 'MediaCom', '2024-04-01', '2024-12-31', 2700000.00, 'Italia 1', 'Prime Time', 'Promozione', 'Telecomunicazioni', 'Giulia Mobile', 'g.mobile@windtre.it', 'Attivo'),
(13, 'Prada S.p.A.', 'Initiative', '2024-09-01', '2024-12-31', 3500000.00, 'Canale 5', 'Prime Time', 'Fashion Week', 'Moda', 'Valentina Moda', 'v.moda@prada.it', 'Pianificato'),
(14, 'Poste Italiane', 'Carat', '2024-01-01', '2024-06-30', 1100000.00, 'Rete 4', 'Pomeriggio', 'Servizi', 'Servizi Pubblici', 'Mario Posta', 'm.posta@poste.it', 'Completato'),
(15, 'Sky Italia', 'Blue 449', '2024-02-01', '2024-05-31', 900000.00, 'Italia 1', 'Prime Time', 'Abbonamenti', 'Media', 'Chiara Satellite', 'c.satellite@sky.it', 'Completato');

INSERT INTO FEEDBACK_SOCIAL VALUES
(1, 2, '2024-03-15 21:45:00', 'Twitter', 'Il Grande Fratello VIP quest anno è fantastico! Non mi perdo una puntata, Alfonso conduce benissimo!', '@GFVIPfan1', 245, 32),
(2, 2, '2024-03-15 22:10:00', 'Instagram', 'Ma che puntata noiosa stasera... mi aspettavo più colpi di scena', '@reality_lover', 89, 5),
(3, 3, '2024-03-16 21:05:00', 'Twitter', 'Striscia la Notizia sempre sul pezzo! Il servizio di stasera era da applausi', '@satira_italia', 567, 123),
(4, 7, '2024-03-17 15:30:00', 'Facebook', 'Amici è il programma che guardo da quando ero ragazzina, Maria è una garanzia di qualità', 'Maria F.', 1023, 89),
(5, 7, '2024-03-17 16:00:00', 'Twitter', 'Il serale di Amici è iniziato col botto! Che talenti quest anno', '@amici_fan_club', 2341, 456),
(6, 5, '2024-03-18 23:30:00', 'Instagram', 'Le Iene hanno fatto un servizio pazzesco stasera, giornalismo vero!', '@inchieste_tv', 890, 234),
(7, 5, '2024-03-18 23:45:00', 'Twitter', 'Lo scherzo delle Iene mi ha fatto morire dal ridere, povero VIP!', '@tvtrash_it', 456, 78),
(8, 6, '2024-03-19 17:20:00', 'Facebook', 'Verissimo emozione pura, ho pianto per tutta l intervista', 'Giuliana R.', 678, 45),
(9, 16, '2024-03-20 22:00:00', 'Twitter', 'Tu Si Que Vales è spettacolo puro! L esibizione dell acrobata era incredibile', '@talent_show_it', 1567, 312),
(10, 16, '2024-03-20 22:30:00', 'Instagram', 'Gerry Scotti e Maria De Filippi sono una coppia televisiva perfetta', '@tvitaliana', 2890, 567),
(11, 9, '2024-03-21 21:15:00', 'Twitter', 'Chi Vuol Essere Milionario mi tiene col fiato sospeso ogni volta, Gerry è il migliore!', '@quiz_lover', 345, 56),
(12, 19, '2024-03-22 22:45:00', 'Instagram', 'Temptation Island mi sta rovinando la vita sentimentale, non mi fido più di nessuno LOL', '@reality_addicted', 1234, 234),
(13, 19, '2024-03-22 23:00:00', 'Twitter', 'Ma questa coppia di Temptation si deve lasciare subito, che comportamento orribile!', '@gossip_tv', 890, 167),
(14, 8, '2024-03-23 14:45:00', 'Facebook', 'Uomini e Donne non è più quello di una volta, troppe litigate inutili', 'Roberto M.', 234, 12),
(15, 8, '2024-03-23 15:00:00', 'Twitter', 'La scelta del tronista è stata super romantica, ho pianto!', '@uomini_donne_fan', 3456, 789),
(16, 1, '2024-03-24 09:30:00', 'Twitter', 'Italia in Diretta ottimo servizio sulla sanità, finalmente informazione seria', '@news_watcher', 567, 89),
(17, 4, '2024-03-24 12:00:00', 'Twitter', 'TGCOM24 è la mia fonte di notizie preferita, sempre aggiornati', '@breaking_news_it', 234, 45),
(18, 14, '2024-03-25 23:30:00', 'Facebook', 'Quarta Repubblica dibattito acceso stasera, Porro non le manda a dire!', 'Antonio B.', 456, 67),
(19, 15, '2024-03-26 22:15:00', 'Instagram', 'Colorado mi ha fatto ridere tantissimo, i nuovi comici sono bravissimi', '@comedy_italia', 789, 123),
(20, 11, '2024-03-27 19:30:00', 'Twitter', 'Caduta Libera è diventato il mio appuntamento fisso, adoro Gerry Scotti!', '@quiz_champion', 567, 98);

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
