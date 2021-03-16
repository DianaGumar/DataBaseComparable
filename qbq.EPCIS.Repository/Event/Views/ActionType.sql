create view Event.ActionType
as
select
	e.ID,
	v.URN as VocabularyURN
from 
	Event.EPCISEvent e
inner join
	Event.EPCISEvent_Vocabulary ev on ev.EPCISEventID = e.ID
inner join
	Vocabulary.Vocabulary v on v.ID = ev.VocabularyID
inner join
	Vocabulary.VocabularyType vt on vt.ID = v.VocabularyTypeID
where
	vt.URN = 'urn:quibiq:epcis:vtype:action'