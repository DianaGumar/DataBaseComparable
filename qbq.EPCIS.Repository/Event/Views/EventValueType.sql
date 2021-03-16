-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 10.07.2013 | 1.0.0.0 | Paul Hummel	      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE view [Event].[EventValueType]
as
select
	eev.ID as EPCISEvent_ValueID, 
	eevd.Value AS DatetimeValue, 
	eevf.Value AS NumericValue, 
	vs.Value   AS StringValue
from 
	Event.EPCISEvent_Value eev
left join Event.EPCISEvent_Value_Datetime eevd
	on eev.ID = eevd.EPCISEvent_ValueID
left join Event.EPCISEvent_Value_Numeric eevf
	on eev.ID = eevf.EPCISEvent_ValueID
--join Event.EPCISEvent_Value_Int eevi
--	on eev.ID = eevi.EPCISEvent_ValueID
join Event.EPCISEvent_Value_String eevs
	on eev.ID = eevs.EPCISEvent_ValueID
join Event.Value_String vs
	on vs.ID = eevs.Value_StringID