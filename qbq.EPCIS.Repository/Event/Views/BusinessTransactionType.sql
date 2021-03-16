
CREATE view [Event].[BusinessTransactionType]
as
select
	e.ID,	
	v.URN as VocabularyURN,
	bt.URN
from 
	Event.EPCISEvent e
inner join
	Event.EPCISEvent_BusinessTransactionID eb on eb.EPCISEventID = e.ID
inner join
	Event.BusinessTransactionID bt on bt.ID = eb.BusinessTransactionIDID
inner join
	Vocabulary.Vocabulary v on v.ID = bt.BusinessTransactionTypeID
inner join
	Vocabulary.VocabularyType vt on vt.ID = v.VocabularyTypeID
where
	vt.URN = 'urn:epcglobal:epcis:vtype:BusinessTransactionType'