CREATE view Event.EPCType
as
select
	ee.EPCISEventID as ID,
	e.URN,
	ee.IsParentID
from
	Event.EPCISEvent_EPC ee
inner join
	Event.EPC e on e.ID = ee.EPCID