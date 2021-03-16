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
CREATE VIEW [Analysis].[EPCISEvent_Disposition]
WITH SCHEMABINDING
AS
SELECT 
	[EPCISEventID], 
	[VocabularyID],
	[VocabularyElement] as Disposition,
	--Mandantenkennung
	[Client]
FROM [Analysis].[EPCISEvent_Vocabulary]
-- Filter
WHERE [Vocabulary] = N'urn:epcglobal:epcis:vtype:Disposition'
