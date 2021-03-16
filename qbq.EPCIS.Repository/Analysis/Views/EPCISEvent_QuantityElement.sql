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
CREATE VIEW [Analysis].[EPCISEvent_QuantityElement]
WITH SCHEMABINDING
AS 
SELECT 
	eeqe.[EPCISEventID],
	eeqe.QuantityElementID,
	eeqe.IsInput,
	eeqe.IsOutput,
	--Mandantenkennung
	c.URN as [Client]
FROM [Event].[EPCISEvent_QuantityElement] eeqe
JOIN [Event].[EPCISEvent]				   e on e.ID = eeqe.EPCISEventID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
UNION ALL
SELECT 
	e.ID as [EPCISEventID],
	-2147483648 as QuantityElementID, 
	0 as [IsInput],
	0 as [IsOutput],
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent] e
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
WHERE not exists (select top 1 1 from [Event].[EPCISEvent_QuantityElement] where EPCISEventID = e.ID)
