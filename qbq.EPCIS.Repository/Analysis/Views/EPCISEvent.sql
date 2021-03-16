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
CREATE VIEW [Analysis].[EPCISEvent]
WITH SCHEMABINDING
AS 
SELECT 
	e.[ID], 
	[EventTime], 
	[RecordTime], 
	[XmlRepresentation],
	-- Zeitintervalle
	DATEPART(ms, SWITCHOFFSET([EventTimeZoneOffset], '+01:00'))	as [Millisecond],
	DATEPART(s,  SWITCHOFFSET([EventTimeZoneOffset], '+01:00'))	as [Second],
	DATEPART(mi, SWITCHOFFSET([EventTimeZoneOffset], '+01:00'))	as [Minute],
	DATEPART(hh, SWITCHOFFSET([EventTimeZoneOffset], '+01:00'))	as [Hour],
	-- EventDatum
	CAST(SWITCHOFFSET([EventTimeZoneOffset], '+01:00') as date) as [DateKeyEvent],
	-- RecordDatum
	CAST([RecordTime] as date)									as [DateKeyRecord],
	-- EventURL
	s.Value + CAST(e.[ID] as nvarchar(20))						as [EventURL],
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent] e 
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
CROSS APPLY [Analysis].[Settings] s
WHERE
	s.ClientID = e.ClientID and s.ID = N'GetEventURL'
