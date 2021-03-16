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
CREATE VIEW [Analysis].[EPCISVocabularyElement]
WITH SCHEMABINDING
AS 
SELECT 
	v.[ID], 
	v.[VocabularyTypeID], 
	v.[URN] as VocabularyElement,
	vt.[URN] as Vocabulary,
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Vocabulary].[Vocabulary] v
JOIN [Vocabulary].[VocabularyType] vt on vt.ID = v.VocabularyTypeID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = v.ClientID
WHERE v.Deleted = 0
