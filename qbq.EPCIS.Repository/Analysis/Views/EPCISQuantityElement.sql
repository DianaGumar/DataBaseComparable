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
CREATE VIEW [Analysis].[EPCISQuantityElement]
WITH SCHEMABINDING
AS
SELECT 
	eeqe.QuantityElementID as [ID],
	ec.URN as [EPCClass],
	qe.Quantity,
	qe.UOM,
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent_QuantityElement] eeqe
JOIN [Event].[QuantityElement]		        qe on qe.[ID] = eeqe.QuantityElementID
JOIN [Event].[EPCISEvent]				     e on e.ID = eeqe.EPCISEventID
-- EPCClass
JOIN [Vocabulary].[Vocabulary] ec on ec.ID = qe.EPCClassID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
GROUP BY eeqe.QuantityElementID, qe.Quantity, qe.UOM, c.URN, ec.URN
UNION ALL
SELECT 
	-2147483648 as [ID], 
	'Leer' as [EPCClass],
	0 as Quantity,
	'Leer' as UOM,
	--Mandantenkennung
	N'urn:quibiq:epcis:cbv:client:epcisrepository' as [Client]
