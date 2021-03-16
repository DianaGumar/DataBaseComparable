-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS 1_1
-- Firma:    QUIBIQ
-- (c) 2015  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 10.03.2015 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE VIEW [Event].[EPCISEvents_OrderByString]
AS
select 
	ev.EPCISEventID, 
	ValueTypeID, 
	max(vs.Value) as [SortValue]
from Event.EPCISEvent_Value ev
join Event.EPCISEvent_Value_String evn on evn.EPCISEvent_ValueID = ev.ID
join Event.Value_String vs on vs.ID = evn.Value_StringID
group by EPCISEventID, ValueTypeID
