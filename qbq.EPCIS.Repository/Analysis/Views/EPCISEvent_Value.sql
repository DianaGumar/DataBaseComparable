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
-- 04.08.2014 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE VIEW [Analysis].[EPCISEvent_Value]
WITH SCHEMABINDING
AS
SELECT
	ev.[EPCISEventID],
	ev.ValueTypeID,
	ISNULL(s.Value, 'Leer') as [Value],
	--Mandantenkennung
	c.URN as [Client]
FROM [Event].[EPCISEvent_Value] ev
LEFT JOIN [Event].[EPCISEvent_Value_String] evs on evs.EPCISEvent_ValueID = ev.ID
LEFT JOIN [Event].[Value_String]		      s on s.ID = evs.Value_StringID
JOIN [Event].[EPCISEvent]				      e on e.ID = ev.EPCISEventID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
UNION ALL
SELECT 
	e.[ID] as [EPCISEventID],
	-2147483648 as [ValueTypeID], 
	'Leer' as [Value],
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent] e
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
WHERE not exists (select top 1 1 from 
							[Event].[EPCISEvent_Value] ev
							JOIN [Vocabulary].[Vocabulary] v on v.ID = ev.ValueTypeID
							JOIN [Vocabulary].[VocabularyType] vt on vt.ID = v.VocabularyTypeID
							where vt.URN in (N'urn:quibiq:epcis:vtype:extensiontype', N'urn:quibiq:epcis:vtype:ilmd', N'urn:quibiq:epcis:vtype:valuetype') 
							  and ev.EPCISEventID = e.ID)
