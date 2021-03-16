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
-- 06.08.2014 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE VIEW [Analysis].[EPCISValueType]
WITH SCHEMABINDING
AS
SELECT
	v.[ID],
	v.[URN]  as ValueType,
	vt.[URN] as ValueClass,
	--Mandantenkennung
	c.[URN]  as [Client]
FROM [Event].[EPCISEvent_Value] ev
JOIN [Event].[EPCISEvent]				 e on e.ID = ev.EPCISEventID
JOIN [Vocabulary].[Vocabulary] v on v.ID = ev.ValueTypeID
JOIN [Vocabulary].[VocabularyType] vt on vt.ID = v.VocabularyTypeID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
WHERE vt.URN in (N'urn:quibiq:epcis:vtype:extensiontype', N'urn:quibiq:epcis:vtype:ilmd', N'urn:quibiq:epcis:vtype:valuetype')
and v.Deleted = 0 
GROUP BY v.[ID], v.[URN], vt.[URN], c.[URN]
UNION ALL
SELECT 
	-2147483648 as [ID], 
	'Leer' as ValueType,
	'Leer' as ValueClass,
	--Mandantenkennung
	N'urn:quibiq:epcis:cbv:client:epcisrepository' as [Client]
