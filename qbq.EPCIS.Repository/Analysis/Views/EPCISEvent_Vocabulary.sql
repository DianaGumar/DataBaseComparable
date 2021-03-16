-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2014  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 30.07.2014 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE VIEW [Analysis].[EPCISEvent_Vocabulary]
WITH SCHEMABINDING
AS 
SELECT 
	[EPCISEventID], 
	[VocabularyID],
	v.[URN]  as [VocabularyElement],
	vt.[URN] as [Vocabulary],
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent_Vocabulary] ev
JOIN [Event].[EPCISEvent] e on e.ID = ev.EPCISEventID
JOIN [Vocabulary].[Vocabulary] v on v.ID = ev.VocabularyID
JOIN [Vocabulary].[VocabularyType] vt on vt.ID = v.VocabularyTypeID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
