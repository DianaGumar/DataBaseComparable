-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS1_1
-- Firma:    QUIBIQ
-- (c) 2015  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 08.04.2015 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE VIEW [Event].[ChildrenType]
AS
with ParentToChildren as (
	select 
		 EPCISEventID as ID
		,VocabularyID
	from Event.EPCISEvent_Vocabulary ev
	join Vocabulary.Vocabulary v on v.ID = ev.VocabularyID
	where v.Deleted = 0
	union all
	select
		c.ID
	   ,p.VocabularyID as VocabularyID
	from ParentToChildren c
	join Vocabulary.VocabularyChildren p on p.ChildVocabularyID = c.VocabularyID
	where p.Deleted = 0
)
select 

	ptc.ID,
	v.URN as VocabularyURN,
	null as ChildVocabularyURN,
	vt.URN as VocabularyTypeURN,
	null as ChildVocabularyTypeURN 

from ParentToChildren ptc
join Vocabulary.Vocabulary v on v.ID = ptc.VocabularyID
join Vocabulary.VocabularyType vt on vt.ID = v.VocabularyTypeID
where v.Deleted = 0
