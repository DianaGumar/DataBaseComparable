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
CREATE VIEW [Analysis].[EPCISVocabulary]
WITH SCHEMABINDING
AS 
SELECT 
	v.[ID], 
	v.[URN] as Vocabulary,
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Vocabulary].[VocabularyType] v
-- Mandantenkennung
JOIN [Vocabulary].[VocabularyType_Client] vtc on vtc.VocabularyTypeID = v.ID
JOIN [Vocabulary].[Vocabulary] c on c.ID = vtc.ClientID
WHERE vtc.Deleted = 0
