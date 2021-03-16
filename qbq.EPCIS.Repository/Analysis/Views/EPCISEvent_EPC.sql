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
-- 30.01.2015 | 1.0.1.0 | Florian Wagner      | FLW001 - Anpassungen EPCIS 1_1
-----------------------------------------------------------------------------------------
CREATE VIEW [Analysis].[EPCISEvent_EPC]
WITH SCHEMABINDING
AS
SELECT 
--	eepc.[ID],
	eepc.[EPCISEventID],
	eepc.[EPCID],
	eepc.[IsParentID],
	eepc.[IsInput],
	eepc.[IsOutput],
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent_EPC] eepc
JOIN [Event].[EPCISEvent] e on e.ID = eepc.EPCISEventID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
UNION ALL
SELECT 
	e.[ID] as [EPCISEventID], 
	-2147483648 as [EPCID], 
	0 as [IsParentID],
	0 as [IsInput],
	0 as [IsOutput],
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent] e
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
WHERE not exists (select top 1 1 from [Event].[EPCISEvent_EPC] where EPCISEventID = e.ID)
