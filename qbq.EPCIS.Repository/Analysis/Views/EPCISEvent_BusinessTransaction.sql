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
CREATE VIEW [Analysis].[EPCISEvent_BusinessTransaction]
WITH SCHEMABINDING
AS 
SELECT 
	eb.[EPCISEventID],
	eb.BusinessTransactionIDID,
	--Mandantenkennung
	c.URN as [Client]
FROM [Event].[EPCISEvent_BusinessTransactionID] eb
JOIN [Event].[EPCISEvent]						 e on e.ID = eb.EPCISEventID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
UNION ALL
SELECT 
	e.ID as [EPCISEventID],
	-2147483648 as BusinessTransactionIDID, 
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent] e
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
WHERE not exists (select top 1 1 from [Event].[EPCISEvent_BusinessTransactionID] where EPCISEventID = e.ID)
