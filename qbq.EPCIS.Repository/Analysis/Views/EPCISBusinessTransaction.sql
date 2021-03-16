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
CREATE VIEW [Analysis].[EPCISBusinessTransaction]
WITH SCHEMABINDING
AS 
SELECT 
	bt.ID,
	bt.URN as [BusinessTransaction],
	v.URN as [BusinessTransactionType],
	--Mandantenkennung
	c.URN as [Client]
FROM [Event].[EPCISEvent_BusinessTransactionID] eb
JOIN [Event].[BusinessTransactionID]		    bt on bt.ID = eb.BusinessTransactionIDID
JOIN [Vocabulary].[Vocabulary]					 v on v.ID = bt.BusinessTransactionTypeID
JOIN [Event].[EPCISEvent]						 e on e.ID = eb.EPCISEventID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
GROUP BY bt.ID, bt.URN, v.URN, c.URN
UNION ALL
SELECT 
	-2147483648 as [ID], 
	'Leer' as [BusinessTransaction],
	'Leer' as [BusinessTransactionType],
	--Mandantenkennung
	N'urn:quibiq:epcis:cbv:client:epcisrepository' as [Client]
