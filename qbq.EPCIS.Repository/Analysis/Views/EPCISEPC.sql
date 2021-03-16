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
CREATE VIEW [Analysis].[EPCISEPC]
WITH SCHEMABINDING
AS 
SELECT 
	epc.[ID], 
	epc.[URN] as EPC,
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent_EPC] eepc
JOIN [Event].[EPC] epc on epc.ID = eepc.EPCID
JOIN [Event].[EPCISEvent] e on e.ID = eepc.EPCISEventID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
GROUP BY epc.[ID], epc.[URN], c.[URN]
UNION ALL
SELECT 
	-2147483648 as [ID], 
	'Leer' as EPC,
	--Mandantenkennung
	N'urn:quibiq:epcis:cbv:client:epcisrepository' as [Client]
