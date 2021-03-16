-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2015  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 30.01.2015 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE VIEW [Analysis].[EPCISEvent_SourceDestination]
WITH SCHEMABINDING
AS
SELECT 
--	eesd.[ID],
	eesd.[EPCISEventID],
	eesd.[IsSource],
	sd.URN as [SourceDestination],
	sdt.URN as [SourceDestinationType],
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent_SourceDestination] eesd
JOIN [Event].[EPCISEvent] e on e.ID = eesd.EPCISEventID
-- SourceDestination
JOIN [Vocabulary].[Vocabulary] sd  on sd.ID = eesd.SourceDestinationID
JOIN [Vocabulary].[Vocabulary] sdt on sdt.ID = eesd.SourceDestinationTypeID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
UNION ALL
SELECT 
	e.[ID] as [EPCISEventID], 
	0 as [IsSource], 
	N'Leer' as [SourceDestination],
	N'Leer' as [SourceDestinationType],
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent] e
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
WHERE not exists (select top 1 1 from [Event].[EPCISEvent_SourceDestination] where EPCISEventID = e.ID)
