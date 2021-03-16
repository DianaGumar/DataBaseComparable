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
CREATE VIEW [Analysis].[EPCISEvent_Transformation]
WITH SCHEMABINDING
AS 
SELECT 
	eeti.[EPCISEventID],
	eeti.TransformationIDID,
	--Mandantenkennung
	c.URN as [Client]
FROM [Event].[EPCISEvent_TransformationID] eeti
JOIN [Event].[EPCISEvent]				   e on e.ID = eeti.EPCISEventID
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
UNION ALL
SELECT 
	e.ID as [EPCISEventID],
	-2147483648 as TransformationIDID, 
	--Mandantenkennung
	c.[URN] as [Client]
FROM [Event].[EPCISEvent] e
-- Mandantenkennung
JOIN [Vocabulary].[Vocabulary] c on c.ID = e.ClientID
WHERE not exists (select top 1 1 from [Event].[EPCISEvent_TransformationID] where EPCISEventID = e.ID)
