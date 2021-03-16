CREATE view [Event].[QuantityType]
as
select
	e.ID,
	evi.Value as Quantity
from 
	Event.EPCISEvent e
inner join
	Event.EPCISEvent_Value ev on ev.EPCISEventID = e.ID
inner join
	Event.EPCISEvent_Value_Numeric evi on evi.EPCISEvent_ValueID = ev.ID
inner join
	Vocabulary.Vocabulary v on v.ID = ev.ValueTypeID
where
	v.URN = 'urn:quibiq:epcis:cbv:valuetype:quantity'