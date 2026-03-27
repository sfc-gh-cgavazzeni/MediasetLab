-- =============================================================
-- MODULO 2: Zero Copy Cloning e Time Travel (20 min)
-- =============================================================
-- Il Zero Copy Cloning crea una copia istantanea di tabelle,
-- schema o database senza duplicare i dati fisici.
-- Il Time Travel permette di accedere ai dati storici (fino a
-- 90 giorni) per recuperare dati cancellati, confrontare
-- versioni e fare audit.
-- =============================================================

-- =============================================================
-- Step 2.1: Zero Copy Clone di una Tabella
-- =============================================================

USE ROLE SYSADMIN;
USE SCHEMA MEDIASET_LAB.RAW;

-- Clona la tabella PROGRAMMI_TV (istantaneo, zero storage aggiuntivo)
CREATE OR REPLACE TABLE PROGRAMMI_TV_CLONE CLONE PROGRAMMI_TV;

-- Verifica: il clone contiene gli stessi dati
SELECT COUNT(*) as righe_originale FROM PROGRAMMI_TV;
SELECT COUNT(*) as righe_clone FROM PROGRAMMI_TV_CLONE;

-- Nota: Il clone e un oggetto indipendente.
-- Le modifiche al clone NON influenzano l'originale e viceversa.

-- =============================================================
-- Step 2.2: Modifica Indipendente del Clone
-- =============================================================

-- Modifica il clone: aggiorna un record
UPDATE PROGRAMMI_TV_CLONE
SET costo_episodio_eur = 999999
WHERE titolo = 'Grande Fratello VIP';

-- Verifica: il clone e stato modificato
SELECT titolo, costo_episodio_eur
FROM PROGRAMMI_TV_CLONE
WHERE titolo = 'Grande Fratello VIP';

-- Verifica: l'originale e rimasto invariato
SELECT titolo, costo_episodio_eur
FROM PROGRAMMI_TV
WHERE titolo = 'Grande Fratello VIP';

-- =============================================================
-- Step 2.3: Time Travel - Recupero Dati Cancellati
-- =============================================================

-- Salva il conteggio attuale
SELECT COUNT(*) as righe_prima FROM PROGRAMMI_TV;

-- Cancella alcuni record
DELETE FROM PROGRAMMI_TV WHERE genere = 'Reality';

-- Verifica la cancellazione
SELECT COUNT(*) as righe_dopo FROM PROGRAMMI_TV;

-- Time Travel: vedi i dati com'erano 1 minuto fa
SELECT COUNT(*) as righe_nel_passato
FROM PROGRAMMI_TV AT (OFFSET => -60);

-- Ripristina i dati cancellati usando Time Travel
INSERT INTO PROGRAMMI_TV
SELECT * FROM PROGRAMMI_TV AT (OFFSET => -60)
WHERE genere = 'Reality';

-- Verifica il ripristino
SELECT COUNT(*) as righe_ripristinate FROM PROGRAMMI_TV;

-- =============================================================
-- Step 2.4: UNDROP - Ripristino di una Tabella Eliminata
-- =============================================================

-- Elimina la tabella clone
DROP TABLE PROGRAMMI_TV_CLONE;

-- Prova a interrogarla (errore!)
-- SELECT * FROM PROGRAMMI_TV_CLONE;

-- Ripristina con UNDROP
UNDROP TABLE PROGRAMMI_TV_CLONE;

-- Verifica: la tabella e tornata
SELECT COUNT(*) FROM PROGRAMMI_TV_CLONE;

-- Pulizia: elimina definitivamente il clone
DROP TABLE PROGRAMMI_TV_CLONE;

-- =============================================================
-- Esercizio Pratico 2
-- =============================================================
-- Clona l'intero schema RAW in un nuovo schema RAW_BACKUP
-- usando CREATE SCHEMA RAW_BACKUP CLONE RAW
-- e verifica che tutte le tabelle siano presenti.
