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
CREATE VIEW [Analysis].[EPCISTransformation]
WITH SCHEMABINDING
AS
SELECT 
	eeti.TransformationIDID as [ID],
	tid.[URN] as [TransformationID],
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent_TransformationID] eeti
JOIN [Event].[TransformationID]		        tid on tid.[ID] = eeti.TransformationIDID
JOIN [Event].[EPCISEvent]				      e on e.ID = eeti.EPCISEventID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
GROUP BY eeti.TransformationIDID, tid.URN, c.URN
UNION ALL
SELECT 
	-2147483648 as [ID], 
	'Leer' as [TransformationID],
	--Mandantenkennung
	N'urn:quibiq:epcis:cbv:client:epcisrepository' as [Client]
