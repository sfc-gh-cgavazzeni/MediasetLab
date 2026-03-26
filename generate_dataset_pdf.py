#!/usr/bin/env python3
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.colors import HexColor
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT
import os

SF_BLUE = HexColor('#29B5E8')
DK2 = HexColor('#11567F')
TEAL = HexColor('#71D3DC')
DK1 = HexColor('#262626')
BODY_GREY = HexColor('#5B5B5B')
LIGHT_BG = HexColor('#F5F5F5')
WHITE = HexColor('#FFFFFF')

output_path = os.path.expanduser("~/Downloads/Mediaset_Dataset_Description.pdf")
doc = SimpleDocTemplate(output_path, pagesize=A4, leftMargin=1.5*cm, rightMargin=1.5*cm, topMargin=1.5*cm, bottomMargin=1.5*cm)

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='CoverTitle', fontSize=24, textColor=DK2, alignment=TA_CENTER, spaceAfter=15, fontName='Helvetica-Bold'))
styles.add(ParagraphStyle(name='CoverSubtitle', fontSize=14, textColor=BODY_GREY, alignment=TA_CENTER, spaceAfter=30))
styles.add(ParagraphStyle(name='TableTitle', fontSize=14, textColor=WHITE, backColor=DK2, alignment=TA_LEFT, spaceAfter=10, spaceBefore=20, fontName='Helvetica-Bold', leftIndent=5, borderPadding=6))
styles.add(ParagraphStyle(name='SectionTitle', fontSize=12, textColor=DK2, spaceBefore=12, spaceAfter=6, fontName='Helvetica-Bold'))
styles.add(ParagraphStyle(name='BodySmall', fontSize=9, textColor=DK1, spaceAfter=4, leading=12))
styles.add(ParagraphStyle(name='TableDesc', fontSize=9, textColor=BODY_GREY, backColor=LIGHT_BG, spaceBefore=3, spaceAfter=8, borderPadding=6, leftIndent=5, rightIndent=5))

story = []

story.append(Spacer(1, 3*cm))
story.append(Paragraph("DATASET SINTETICO", styles['CoverTitle']))
story.append(Paragraph("Mediaset TV Broadcasting", styles['CoverSubtitle']))
story.append(Spacer(1, 1*cm))

overview_data = [
    ['Database', 'MEDIASET_LAB'],
    ['Schema principale', 'RAW'],
    ['Numero tabelle', '7'],
    ['Settore', 'TV Broadcasting'],
    ['Lingua dati', 'Italiano'],
    ['Tipo dati', 'Sintetici / Fittizi'],
]
overview_table = Table(overview_data, colWidths=[5*cm, 9*cm])
overview_table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (0, -1), LIGHT_BG),
    ('TEXTCOLOR', (0, 0), (-1, -1), DK1),
    ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 10),
    ('PADDING', (0, 0), (-1, -1), 8),
    ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY),
]))
story.append(overview_table)
story.append(Spacer(1, 1*cm))

story.append(Paragraph("Schema Relazionale", styles['SectionTitle']))
story.append(Paragraph("PROGRAMMI_TV → PALINSESTO → ASCOLTI (dati di audience)<br/>PROGRAMMI_TV → CONTENUTI_DESCRIZIONI (metadati testuali)<br/>PROGRAMMI_TV → FEEDBACK_SOCIAL (commenti social)<br/>CONTRATTI_PUBBLICITARI (standalone - dati commerciali)<br/>ABBONATI (standalone - dati utenti PII)", styles['BodySmall']))
story.append(PageBreak())

# TABLE 1: PROGRAMMI_TV
story.append(Paragraph("1. PROGRAMMI_TV", styles['TableTitle']))
story.append(Paragraph("Anagrafica dei programmi televisivi Mediaset. Contiene 20 programmi reali con dati fittizi su costi e caratteristiche.", styles['TableDesc']))

cols1 = [
    ['Colonna', 'Tipo', 'Descrizione'],
    ['programma_id', 'INT', 'Chiave primaria'],
    ['titolo', 'VARCHAR(200)', 'Nome del programma (es. "Grande Fratello VIP")'],
    ['genere', 'VARCHAR(50)', 'Categoria: Reality, Quiz, Talk Show, Satira, News, etc.'],
    ['canale', 'VARCHAR(50)', 'Canale di messa in onda: Canale 5, Italia 1, Rete 4, TGCom24'],
    ['durata_minuti', 'INT', 'Durata media episodio (30-180 min)'],
    ['anno_prima_messa_in_onda', 'INT', 'Anno di debutto (1985-2018)'],
    ['produzione', 'VARCHAR(100)', 'Casa di produzione: Mediaset, Endemol, Fascino PGT, etc.'],
    ['target_eta', 'VARCHAR(50)', 'Fascia età target: 15-45, 25-54, 18-65, etc.'],
    ['costo_episodio_eur', 'DECIMAL(12,2)', 'Costo produzione per episodio (€35K-€250K)'],
    ['rating_contenuto', 'VARCHAR(10)', 'Classificazione: TV-G (tutti), TV-14 (adulti)'],
]
t1 = Table(cols1, colWidths=[3.5*cm, 3*cm, 9*cm])
t1.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), SF_BLUE),
    ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('PADDING', (0, 0), (-1, -1), 4),
    ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
story.append(t1)

# TABLE 2: PALINSESTO
story.append(Paragraph("2. PALINSESTO", styles['TableTitle']))
story.append(Paragraph("Programmazione televisiva giornaliera. ~600 record generati automaticamente per 90 giorni (Q1 2024).", styles['TableDesc']))

cols2 = [
    ['Colonna', 'Tipo', 'Descrizione'],
    ['palinsesto_id', 'INT', 'Chiave primaria'],
    ['programma_id', 'INT', 'FK → PROGRAMMI_TV'],
    ['data_trasmissione', 'DATE', 'Data messa in onda (Gen-Mar 2024)'],
    ['ora_inizio', 'TIME', 'Orario inizio trasmissione'],
    ['ora_fine', 'TIME', 'Orario fine trasmissione'],
    ['canale', 'VARCHAR(50)', 'Canale di trasmissione'],
    ['tipo_trasmissione', 'VARCHAR(50)', 'Prima TV o Replica'],
    ['stagione', 'INT', 'Numero stagione (2024)'],
    ['episodio', 'INT', 'Numero episodio (1-24)'],
]
t2 = Table(cols2, colWidths=[3.5*cm, 3*cm, 9*cm])
t2.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), SF_BLUE),
    ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('PADDING', (0, 0), (-1, -1), 4),
    ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
story.append(t2)

# TABLE 3: ASCOLTI
story.append(Paragraph("3. ASCOLTI", styles['TableTitle']))
story.append(Paragraph("Dati di audience per programma, regione e fascia oraria. ~5000 record con valori randomici realistici.", styles['TableDesc']))

cols3 = [
    ['Colonna', 'Tipo', 'Descrizione'],
    ['ascolto_id', 'INT', 'Chiave primaria'],
    ['palinsesto_id', 'INT', 'FK → PALINSESTO'],
    ['programma_id', 'INT', 'FK → PROGRAMMI_TV'],
    ['data_rilevazione', 'DATE', 'Data della rilevazione Auditel'],
    ['fascia_oraria', 'VARCHAR(50)', 'Mattina, Pomeriggio, Access Prime Time, Prime Time'],
    ['regione', 'VARCHAR(50)', 'Regione italiana (10 regioni: Lombardia, Lazio, etc.)'],
    ['telespettatori', 'INT', 'Numero spettatori (50K-2M)'],
    ['share_percentuale', 'DECIMAL(5,2)', 'Quota di mercato % (5-35%)'],
    ['target_commerciale', 'VARCHAR(50)', 'Responsabili Acquisto, Adulti 25-54, Giovani 15-34'],
    ['dispositivo', 'VARCHAR(50)', 'TV Tradizionale, Smart TV, Streaming'],
]
t3 = Table(cols3, colWidths=[3.5*cm, 3*cm, 9*cm])
t3.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), SF_BLUE),
    ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('PADDING', (0, 0), (-1, -1), 4),
    ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
story.append(t3)
story.append(PageBreak())

# TABLE 4: ABBONATI
story.append(Paragraph("4. ABBONATI", styles['TableTitle']))
story.append(Paragraph("Anagrafica abbonati con dati PII fittizi. 20 record con nomi italiani realistici. Usata per demo masking policy.", styles['TableDesc']))

cols4 = [
    ['Colonna', 'Tipo', 'Descrizione', 'PII'],
    ['abbonato_id', 'INT', 'Chiave primaria', ''],
    ['nome', 'VARCHAR(100)', 'Nome di battesimo (es. Marco, Giulia)', '✓'],
    ['cognome', 'VARCHAR(100)', 'Cognome (es. Rossi, Bianchi)', '✓'],
    ['email', 'VARCHAR(200)', 'Email fittizia (es. marco.rossi@email.it)', '✓'],
    ['telefono', 'VARCHAR(20)', 'Telefono italiano (+39 0xx xxxxxxx)', '✓'],
    ['citta', 'VARCHAR(100)', 'Città italiana (Milano, Roma, Napoli, etc.)', ''],
    ['regione', 'VARCHAR(50)', 'Regione (Lombardia, Lazio, Campania, etc.)', ''],
    ['cap', 'VARCHAR(10)', 'Codice postale', ''],
    ['data_iscrizione', 'DATE', 'Data sottoscrizione (2020-2023)', ''],
    ['tipo_abbonamento', 'VARCHAR(50)', 'Base (€9.99), Premium (€14.99), Premium Plus (€19.99)', ''],
    ['importo_mensile', 'DECIMAL(8,2)', 'Canone mensile in EUR', '✓'],
    ['stato_abbonamento', 'VARCHAR(20)', 'Attivo, Sospeso, Cancellato', ''],
    ['canali_preferiti', 'VARCHAR(500)', 'Lista canali preferiti', ''],
]
t4 = Table(cols4, colWidths=[3*cm, 2.5*cm, 7.5*cm, 1.5*cm])
t4.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), SF_BLUE),
    ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('PADDING', (0, 0), (-1, -1), 4),
    ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ('ALIGN', (3, 0), (3, -1), 'CENTER'),
]))
story.append(t4)

# TABLE 5: CONTENUTI_DESCRIZIONI
story.append(Paragraph("5. CONTENUTI_DESCRIZIONI", styles['TableTitle']))
story.append(Paragraph("Metadati testuali dei programmi per Cortex Search e AI functions. 20 record con descrizioni in italiano.", styles['TableDesc']))

cols5 = [
    ['Colonna', 'Tipo', 'Descrizione'],
    ['contenuto_id', 'INT', 'Chiave primaria'],
    ['programma_id', 'INT', 'FK → PROGRAMMI_TV'],
    ['titolo', 'VARCHAR(200)', 'Titolo programma'],
    ['descrizione_breve', 'VARCHAR(500)', 'Sinossi breve (1-2 frasi)'],
    ['descrizione_completa', 'TEXT', 'Descrizione estesa (3-5 frasi, ~500 caratteri)'],
    ['parole_chiave', 'VARCHAR(500)', 'Keywords separate da virgola'],
    ['cast_principale', 'VARCHAR(500)', 'Conduttori e protagonisti'],
    ['regista', 'VARCHAR(200)', 'Autore/Regista'],
    ['anno_produzione', 'INT', 'Anno prima produzione'],
    ['paese_origine', 'VARCHAR(100)', 'Italia'],
    ['lingua_originale', 'VARCHAR(50)', 'Italiano'],
    ['sottotitoli_disponibili', 'VARCHAR(200)', 'Lingue sottotitoli'],
]
t5 = Table(cols5, colWidths=[3.5*cm, 3*cm, 9*cm])
t5.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), SF_BLUE),
    ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('PADDING', (0, 0), (-1, -1), 4),
    ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
story.append(t5)
story.append(PageBreak())

# TABLE 6: CONTRATTI_PUBBLICITARI
story.append(Paragraph("6. CONTRATTI_PUBBLICITARI", styles['TableTitle']))
story.append(Paragraph("Contratti pubblicitari con inserzionisti italiani fittizi. 15 record con budget realistici (€900K-€4.5M).", styles['TableDesc']))

cols6 = [
    ['Colonna', 'Tipo', 'Descrizione'],
    ['contratto_id', 'INT', 'Chiave primaria'],
    ['inserzionista', 'VARCHAR(200)', 'Azienda cliente (Barilla, FIAT, TIM, Ferrero, etc.)'],
    ['agenzia', 'VARCHAR(200)', 'Agenzia media (WPP, Publicis, Havas, etc.)'],
    ['data_inizio', 'DATE', 'Inizio campagna'],
    ['data_fine', 'DATE', 'Fine campagna'],
    ['budget_totale_eur', 'DECIMAL(15,2)', 'Budget totale in EUR (€900K-€4.5M)'],
    ['canale_target', 'VARCHAR(100)', 'Canale/i di riferimento'],
    ['fascia_oraria_target', 'VARCHAR(50)', 'Slot orario preferito'],
    ['tipo_campagna', 'VARCHAR(100)', 'Brand Awareness, Lancio Prodotto, Promozione'],
    ['settore_merceologico', 'VARCHAR(100)', 'Alimentare, Automotive, Telecomunicazioni, Moda, etc.'],
    ['referente_nome', 'VARCHAR(100)', 'Nome contatto cliente'],
    ['referente_email', 'VARCHAR(200)', 'Email contatto (fittizia)'],
    ['stato_contratto', 'VARCHAR(50)', 'Attivo, Completato, Pianificato'],
]
t6 = Table(cols6, colWidths=[3.5*cm, 3*cm, 9*cm])
t6.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), SF_BLUE),
    ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('PADDING', (0, 0), (-1, -1), 4),
    ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
story.append(t6)

# TABLE 7: FEEDBACK_SOCIAL
story.append(Paragraph("7. FEEDBACK_SOCIAL", styles['TableTitle']))
story.append(Paragraph("Commenti social sui programmi per analisi sentiment con Cortex AI. 20 record con testi in italiano.", styles['TableDesc']))

cols7 = [
    ['Colonna', 'Tipo', 'Descrizione'],
    ['feedback_id', 'INT', 'Chiave primaria'],
    ['programma_id', 'INT', 'FK → PROGRAMMI_TV'],
    ['data_feedback', 'TIMESTAMP', 'Data e ora del post'],
    ['piattaforma', 'VARCHAR(50)', 'Twitter, Instagram, Facebook'],
    ['testo_feedback', 'TEXT', 'Testo del commento in italiano (positivo/negativo/neutro)'],
    ['username', 'VARCHAR(100)', 'Username fittizio (@nome o Nome C.)'],
    ['likes', 'INT', 'Numero di like (50-2500)'],
    ['shares', 'INT', 'Numero di condivisioni (5-500)'],
]
t7 = Table(cols7, colWidths=[3.5*cm, 3*cm, 9*cm])
t7.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), SF_BLUE),
    ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('PADDING', (0, 0), (-1, -1), 4),
    ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
story.append(t7)
story.append(PageBreak())

# SUMMARY
story.append(Paragraph("Riepilogo Volumi Dati", styles['SectionTitle']))
vol_data = [
    ['Tabella', 'Record', 'Uso principale'],
    ['PROGRAMMI_TV', '20', 'Anagrafica base, join'],
    ['PALINSESTO', '~600', 'Scheduling, time-series'],
    ['ASCOLTI', '~5000', 'Analytics, aggregazioni, row access policy'],
    ['ABBONATI', '20', 'PII, masking policy demo'],
    ['CONTENUTI_DESCRIZIONI', '20', 'Cortex Search, AI Summarize/Translate'],
    ['CONTRATTI_PUBBLICITARI', '15', 'Semantic Views, KPI commerciali'],
    ['FEEDBACK_SOCIAL', '20', 'Cortex Sentiment, Classify'],
]
vol_table = Table(vol_data, colWidths=[4.5*cm, 2*cm, 9*cm])
vol_table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), DK2),
    ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 9),
    ('PADDING', (0, 0), (-1, -1), 6),
    ('GRID', (0, 0), (-1, -1), 0.5, BODY_GREY),
    ('ALIGN', (1, 0), (1, -1), 'CENTER'),
]))
story.append(vol_table)

story.append(Spacer(1, 1*cm))
story.append(Paragraph("Note sui Dati", styles['SectionTitle']))
notes = [
    "• Tutti i dati personali (nomi, email, telefoni) sono <b>completamente fittizi</b>",
    "• I nomi dei programmi TV sono reali, ma i dati numerici sono inventati",
    "• I budget pubblicitari e costi di produzione sono realistici ma non verificati",
    "• Le aziende inserzioniste esistono, ma i contratti sono fittizi",
    "• I feedback social sono scritti manualmente per demo AI sentiment",
    "• I dati Auditel (ascolti, share) sono generati randomicamente",
]
for note in notes:
    story.append(Paragraph(note, styles['BodySmall']))

story.append(Spacer(1, 1.5*cm))
story.append(Paragraph("Dataset creato per il Workshop Snowflake — Mediaset 2026", styles['CoverSubtitle']))

doc.build(story)
print(f"PDF salvato: {output_path}")
