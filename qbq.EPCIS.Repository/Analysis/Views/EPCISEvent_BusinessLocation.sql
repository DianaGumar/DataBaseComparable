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
CREATE VIEW [Analysis].[EPCISEvent_BusinessLocation]
WITH SCHEMABINDING
AS 
SELECT 
	v.[EPCISEventID], 
	v.[VocabularyID],
	v.[VocabularyElement] as BusinessLocation,
	--Geographie
	longitude.Value.value(N'/Value[1]', N'float') as longitude, 
	latitude.Value.value(N'/Value[1]', N'float') as latitude, 
	--Mandantenkennung
	v.[Client]
FROM [Analysis].[EPCISEvent_Vocabulary] v
--Geographie
outer apply (
select va.Value from
 Vocabulary.VocabularyAttribute va 
join Vocabulary.AttributeType at on at.ID = va.AttributeTypeID
where va.VocabularyID = v.[VocabularyID] and at.URN = N'urn:epcglobal:fmcg:mda:longitude'
) as longitude
outer apply (
select va.Value from
 Vocabulary.VocabularyAttribute va 
join Vocabulary.AttributeType at on at.ID = va.AttributeTypeID
where va.VocabularyID = v.[VocabularyID] and at.URN = N'urn:epcglobal:fmcg:mda:latitude'
) as latitude
-- Filter
WHERE [Vocabulary] = N'urn:epcglobal:epcis:vtype:BusinessLocation'
