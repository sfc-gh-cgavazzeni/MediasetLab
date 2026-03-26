#!/usr/bin/env python3
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.colors import HexColor
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, ListFlowable, ListItem, Preformatted
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import os

SF_BLUE = HexColor('#29B5E8')
DK2 = HexColor('#11567F')
TEAL = HexColor('#71D3DC')
ORANGE = HexColor('#FF9F36')
DK1 = HexColor('#262626')
BODY_GREY = HexColor('#5B5B5B')
LIGHT_BG = HexColor('#F5F5F5')
WHITE = HexColor('#FFFFFF')

output_path = os.path.expanduser("~/Downloads/Mediaset_Workshop_Student_Guide.pdf")
doc = SimpleDocTemplate(output_path, pagesize=A4, leftMargin=2*cm, rightMargin=2*cm, topMargin=2*cm, bottomMargin=2*cm)

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='CoverTitle', fontSize=28, textColor=DK2, alignment=TA_CENTER, spaceAfter=20, fontName='Helvetica-Bold'))
styles.add(ParagraphStyle(name='CoverSubtitle', fontSize=16, textColor=BODY_GREY, alignment=TA_CENTER, spaceAfter=40))
styles.add(ParagraphStyle(name='ModuleTitle', fontSize=20, textColor=WHITE, backColor=DK2, alignment=TA_CENTER, spaceAfter=20, spaceBefore=30, fontName='Helvetica-Bold', borderPadding=10))
styles.add(ParagraphStyle(name='SectionTitle', fontSize=14, textColor=DK2, spaceBefore=15, spaceAfter=8, fontName='Helvetica-Bold'))
styles['BodyText'].fontSize = 10
styles['BodyText'].textColor = DK1
styles['BodyText'].spaceAfter = 6
styles['BodyText'].leading = 14
styles.add(ParagraphStyle(name='FeatureBox', fontSize=10, textColor=BODY_GREY, backColor=LIGHT_BG, spaceBefore=5, spaceAfter=10, borderPadding=8, leftIndent=10, rightIndent=10))
styles.add(ParagraphStyle(name='CodeStyle', fontSize=8, textColor=DK1, backColor=LIGHT_BG, fontName='Courier', spaceBefore=5, spaceAfter=10, leftIndent=10, rightIndent=10))
styles.add(ParagraphStyle(name='StepTitle', fontSize=11, textColor=SF_BLUE, spaceBefore=10, spaceAfter=5, fontName='Helvetica-Bold'))
styles.add(ParagraphStyle(name='BulletText', fontSize=10, textColor=DK1, leftIndent=20, bulletIndent=10))
styles.add(ParagraphStyle(name='TableHeader', fontSize=10, textColor=WHITE, fontName='Helvetica-Bold'))
styles.add(ParagraphStyle(name='ExerciseBox', fontSize=10, textColor=DK2, backColor=HexColor('#E8F4F8'), spaceBefore=10, spaceAfter=10, borderPadding=10, fontName='Helvetica-Bold'))

story = []

story.append(Spacer(1, 4*cm))
story.append(Paragraph("WORKSHOP SNOWFLAKE", styles['CoverTitle']))
story.append(Paragraph("Mediaset — Hands-on Lab", styles['CoverSubtitle']))
story.append(Spacer(1, 1*cm))
story.append(Paragraph("Guida per i Partecipanti", styles['CoverSubtitle']))
story.append(Spacer(1, 3*cm))

info_data = [['Durata', '3.5 ore'], ['Livello', 'Introduttivo/Intermedio'], ['Prerequisiti', 'Account Snowflake, SQL base'], ['Settore', 'TV Broadcasting']]
info_table = Table(info_data, colWidths=[5*cm, 8*cm])
info_table.setStyle(TableStyle([('BACKGROUND', (0, 0), (0, -1), LIGHT_BG), ('TEXTCOLOR', (0, 0), (-1, -1), DK1), ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'), ('FONTSIZE', (0, 0), (-1, -1), 10), ('PADDING', (0, 0), (-1, -1), 8), ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY)]))
story.append(info_table)
story.append(PageBreak())

story.append(Paragraph("AGENDA", styles['SectionTitle']))
agenda_data = [['Orario', 'Modulo', 'Durata'],
    ['00:00 - 00:40', 'Modulo 1: Setup e Basi Snowflake', '40 min'],
    ['00:40 - 01:15', 'Modulo 2: Row & Column Level Security', '35 min'],
    ['01:15 - 01:45', 'Modulo 3: Data Pipelines (Dynamic Tables)', '30 min'],
    ['01:45 - 02:00', 'Pausa', '15 min'],
    ['02:00 - 02:25', 'Modulo 4: Cortex AI SQL Functions', '25 min'],
    ['02:25 - 03:05', 'Modulo 5: Semantic Views & Cortex Analyst', '40 min'],
    ['03:05 - 03:30', 'Modulo 6: Cortex Search & Intelligence', '25 min']]
agenda_table = Table(agenda_data, colWidths=[3.5*cm, 8*cm, 2.5*cm])
agenda_table.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, 0), DK2), ('TEXTCOLOR', (0, 0), (-1, 0), WHITE), ('BACKGROUND', (0, 4), (-1, 4), TEAL), ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'), ('FONTSIZE', (0, 0), (-1, -1), 9), ('PADDING', (0, 0), (-1, -1), 6), ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY), ('ALIGN', (2, 0), (2, -1), 'CENTER')]))
story.append(agenda_table)
story.append(PageBreak())

story.append(Paragraph("MODULO 1: SETUP E BASI SNOWFLAKE", styles['ModuleTitle']))
story.append(Paragraph("<b>Snowflake</b> è una piattaforma dati cloud-native che separa storage e compute. I <b>Database</b> organizzano i dati in <b>Schema</b>, mentre i <b>Warehouse</b> forniscono risorse di calcolo elastiche on-demand. I <b>Ruoli</b> controllano l'accesso seguendo il principio del least privilege.", styles['FeatureBox']))

story.append(Paragraph("Obiettivi di Apprendimento", styles['SectionTitle']))
objectives = ['Creare e configurare database, schema e warehouse', 'Comprendere il modello di ruoli e permessi', 'Eseguire query SQL di base', 'Caricare e interrogare dati']
for obj in objectives:
    story.append(Paragraph(f"• {obj}", styles['BulletText']))

story.append(Paragraph("Step 1.1: Accesso a Snowflake", styles['StepTitle']))
story.append(Paragraph("1. Apri il browser e vai all'URL del tuo account Snowflake<br/>2. Effettua il login con le credenziali fornite<br/>3. Seleziona <b>Worksheets</b> dal menu laterale", styles['BodyText']))

story.append(Paragraph("Step 1.2: Creazione Database e Schema", styles['StepTitle']))
code1 = """USE ROLE SYSADMIN;
CREATE OR REPLACE DATABASE MEDIASET_LAB;
CREATE OR REPLACE SCHEMA MEDIASET_LAB.RAW;
CREATE OR REPLACE SCHEMA MEDIASET_LAB.ANALYTICS;
CREATE OR REPLACE SCHEMA MEDIASET_LAB.SECURITY;"""
story.append(Preformatted(code1, styles['CodeStyle']))

story.append(Paragraph("Step 1.3: Creazione Warehouse", styles['StepTitle']))
code2 = """USE ROLE SYSADMIN;
CREATE OR REPLACE WAREHOUSE MEDIASET_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;"""
story.append(Preformatted(code2, styles['CodeStyle']))

story.append(Paragraph("Step 1.4: Creazione Ruoli", styles['StepTitle']))
code3 = """USE ROLE SECURITYADMIN;
CREATE OR REPLACE ROLE MEDIASET_ADMIN;
CREATE OR REPLACE ROLE MEDIASET_ANALYST;
CREATE OR REPLACE ROLE MEDIASET_MARKETING;

-- Best Practice: ruoli custom riportano a SYSADMIN
GRANT ROLE MEDIASET_ADMIN TO ROLE SYSADMIN;
GRANT ROLE MEDIASET_ANALYST TO ROLE SYSADMIN;
GRANT ROLE MEDIASET_MARKETING TO ROLE SYSADMIN;"""
story.append(Preformatted(code3, styles['CodeStyle']))

story.append(Paragraph("Esercizio: Scrivi una query che mostri i top 5 programmi per share medio.", styles['ExerciseBox']))
story.append(PageBreak())

story.append(Paragraph("MODULO 2: ROW & COLUMN LEVEL SECURITY", styles['ModuleTitle']))
story.append(Paragraph("Le <b>Masking Policy</b> nascondono dati sensibili (PII) a livello di colonna in base al ruolo. Le <b>Row Access Policy</b> filtrano automaticamente le righe visibili, garantendo che ogni utente veda solo i dati di sua competenza.", styles['FeatureBox']))

story.append(Paragraph("Step 2.1: Masking Policy per Email", styles['StepTitle']))
code4 = """CREATE OR REPLACE MASKING POLICY email_mask 
AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN') THEN val
        WHEN CURRENT_ROLE() = 'MEDIASET_MARKETING' THEN 
            REGEXP_REPLACE(val, '(.{2})(.*)(@.*)', '\\\\1***\\\\3')
        ELSE '***RISERVATO***'
    END;

ALTER TABLE MEDIASET_LAB.RAW.ABBONATI 
    MODIFY COLUMN email SET MASKING POLICY email_mask;"""
story.append(Preformatted(code4, styles['CodeStyle']))

story.append(Paragraph("Step 2.2: Row Access Policy", styles['StepTitle']))
code5 = """CREATE OR REPLACE ROW ACCESS POLICY region_access_policy 
AS (regione_col VARCHAR) RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() IN ('MEDIASET_ADMIN') THEN TRUE
        WHEN EXISTS (
            SELECT 1 FROM ROLE_REGION_MAPPING 
            WHERE role_name = CURRENT_ROLE() 
            AND regione = regione_col
        ) THEN TRUE
        ELSE FALSE
    END;"""
story.append(Preformatted(code5, styles['CodeStyle']))

story.append(Paragraph("Esercizio: Crea una masking policy per il campo telefono.", styles['ExerciseBox']))
story.append(PageBreak())

story.append(Paragraph("MODULO 3: DYNAMIC TABLES", styles['ModuleTitle']))
story.append(Paragraph("Le <b>Dynamic Tables</b> si aggiornano automaticamente quando cambiano i dati sorgente. Definisci la trasformazione SQL una volta e Snowflake gestisce il refresh incrementale. Ideali per pipeline ETL declarative senza orchestrazione esterna.", styles['FeatureBox']))

story.append(Paragraph("Step 3.1: Dynamic Table - Ascolti Giornalieri", styles['StepTitle']))
code6 = """CREATE OR REPLACE DYNAMIC TABLE ASCOLTI_GIORNALIERI
    TARGET_LAG = '1 hour'
    WAREHOUSE = MEDIASET_WH
AS
SELECT 
    a.data_rilevazione,
    p.titolo,
    p.genere,
    SUM(a.telespettatori) as telespettatori_totali,
    AVG(a.share_percentuale) as share_medio
FROM MEDIASET_LAB.RAW.ASCOLTI a
JOIN MEDIASET_LAB.RAW.PROGRAMMI_TV p 
    ON a.programma_id = p.programma_id
GROUP BY a.data_rilevazione, p.titolo, p.genere;"""
story.append(Preformatted(code6, styles['CodeStyle']))

story.append(Paragraph("Esercizio: Crea una Dynamic Table per KPI pubblicitari per settore.", styles['ExerciseBox']))
story.append(PageBreak())

story.append(Paragraph("MODULO 4: CORTEX AI SQL FUNCTIONS", styles['ModuleTitle']))
story.append(Paragraph("<b>Cortex AI Functions</b> sono funzioni SQL native che integrano modelli LLM. Analizza sentiment, classifica testi, genera riassunti, traduci contenuti—tutto in SQL senza infrastruttura ML da gestire.", styles['FeatureBox']))

story.append(Paragraph("Funzioni Disponibili", styles['SectionTitle']))
funcs = [('SENTIMENT', 'Analizza il sentiment di testi'), ('CLASSIFY_TEXT', 'Classifica in categorie'), ('SUMMARIZE', 'Riassume testi lunghi'), ('TRANSLATE', 'Traduce tra lingue'), ('COMPLETE', 'Genera testo con LLM')]
func_data = [['Funzione', 'Descrizione']] + [[f[0], f[1]] for f in funcs]
func_table = Table(func_data, colWidths=[4*cm, 10*cm])
func_table.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, 0), SF_BLUE), ('TEXTCOLOR', (0, 0), (-1, 0), WHITE), ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'), ('FONTSIZE', (0, 0), (-1, -1), 9), ('PADDING', (0, 0), (-1, -1), 6), ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY)]))
story.append(func_table)

story.append(Paragraph("Esempio: Analisi Sentiment", styles['StepTitle']))
code7 = """SELECT 
    testo_feedback,
    SNOWFLAKE.CORTEX.SENTIMENT(testo_feedback) as sentiment
FROM FEEDBACK_SOCIAL
ORDER BY sentiment DESC;"""
story.append(Preformatted(code7, styles['CodeStyle']))

story.append(Paragraph("Esercizio: Identifica feedback negativi e genera suggerimenti con COMPLETE.", styles['ExerciseBox']))
story.append(PageBreak())

story.append(Paragraph("MODULO 5: SEMANTIC VIEWS & CORTEX ANALYST", styles['ModuleTitle']))
story.append(Paragraph("Le <b>Semantic Views</b> definiscono metriche e dimensioni di business in modo centralizzato. <b>Cortex Analyst</b> usa queste definizioni per tradurre domande in linguaggio naturale in SQL corretto.", styles['FeatureBox']))

story.append(Paragraph("Step 5.1: Creazione Semantic View", styles['StepTitle']))
code8 = """CREATE OR REPLACE SEMANTIC VIEW SV_ANALISI_ASCOLTI
AS SEMANTIC MODEL
  TABLES (
    PROGRAMMI AS (
      SELECT programma_id, titolo, genere, canale
      FROM MEDIASET_LAB.RAW.PROGRAMMI_TV
      PRIMARY KEY (programma_id)
      DIMENSIONS (titolo, genere, canale)
    ),
    ASCOLTI AS (
      SELECT ascolto_id, programma_id, telespettatori
      FROM MEDIASET_LAB.RAW.ASCOLTI
      FACTS (telespettatori)
    )
  )
  METRICS (
    SHARE_MEDIO AS (AVG(ASCOLTI.share_percentuale))
  );"""
story.append(Preformatted(code8, styles['CodeStyle']))

story.append(Paragraph("Domande Esempio per Cortex Analyst", styles['SectionTitle']))
questions = ['"Qual è il programma con lo share più alto?"', '"Mostrami i top 5 programmi in prime time"', '"Confronta gli ascolti di Canale 5 e Italia 1"']
for q in questions:
    story.append(Paragraph(f"• {q}", styles['BulletText']))

story.append(Paragraph("Esercizio: Crea una Semantic View per analisi commerciale.", styles['ExerciseBox']))
story.append(PageBreak())

story.append(Paragraph("MODULO 6: CORTEX SEARCH & INTELLIGENCE", styles['ModuleTitle']))
story.append(Paragraph("<b>Cortex Search</b> abilita ricerche semantiche: trova contenuti per significato, non keyword. <b>Snowflake Intelligence</b> è l'assistente AI integrato che risponde in linguaggio naturale combinando Analyst e Search.", styles['FeatureBox']))

story.append(Paragraph("Step 6.1: Cortex Search Service", styles['StepTitle']))
code9 = """CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_PROGRAMMI
  ON testo_ricercabile
  ATTRIBUTES titolo, genere, canale
  WAREHOUSE = MEDIASET_WH
  TARGET_LAG = '1 hour'
AS (SELECT * FROM V_CONTENUTI_RICERCABILI);"""
story.append(Preformatted(code9, styles['CodeStyle']))

story.append(Paragraph("Ricerca Semantica", styles['StepTitle']))
code10 = """SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MEDIASET_LAB.RAW.SEARCH_PROGRAMMI',
    '{"query": "programmi divertenti per famiglie",
      "columns": ["titolo", "genere"],
      "limit": 5}'
);"""
story.append(Preformatted(code10, styles['CodeStyle']))

story.append(Paragraph("Esercizio: Crea un Search Service sui feedback social.", styles['ExerciseBox']))
story.append(PageBreak())

story.append(Paragraph("RIEPILOGO & BEST PRACTICES", styles['ModuleTitle']))
summary = [('Modulo 1', 'Database, Schema, Warehouse, Ruoli'), ('Modulo 2', 'Masking Policy, Row Access Policy'), ('Modulo 3', 'Dynamic Tables per ETL automatico'), ('Modulo 4', 'Cortex AI Functions (Sentiment, Classify, Summarize)'), ('Modulo 5', 'Semantic Views, Cortex Analyst'), ('Modulo 6', 'Cortex Search, Snowflake Intelligence')]
summary_data = [['Modulo', 'Concetti Chiave']] + [[s[0], s[1]] for s in summary]
summary_table = Table(summary_data, colWidths=[3*cm, 11*cm])
summary_table.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, 0), DK2), ('TEXTCOLOR', (0, 0), (-1, 0), WHITE), ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'), ('FONTSIZE', (0, 0), (-1, -1), 10), ('PADDING', (0, 0), (-1, -1), 8), ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY)]))
story.append(summary_table)

story.append(Spacer(1, 1*cm))
story.append(Paragraph("Best Practices", styles['SectionTitle']))
bp = ['Usa ruoli specifici per ogni tipo di utente', 'Implementa masking su tutti i dati sensibili (PII)', 'Preferisci Dynamic Tables per trasformazioni ricorrenti', 'Definisci metriche consistenti nelle Semantic Views', 'Sfrutta le AI functions per arricchire i dati']
for b in bp:
    story.append(Paragraph(f"✓ {b}", styles['BulletText']))

story.append(Spacer(1, 2*cm))
story.append(Paragraph("Grazie per aver partecipato al workshop!", styles['CoverSubtitle']))

doc.build(story)
print(f"PDF salvato: {output_path}")
