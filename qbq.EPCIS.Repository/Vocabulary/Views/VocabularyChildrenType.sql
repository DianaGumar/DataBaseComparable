create view Vocabulary.VocabularyChildrenType
as
select
	c.VocabularyID,
	v.URN as ChildURN
from
	Vocabulary.VocabularyChildren c
inner join
	Vocabulary.Vocabulary v on v.ID = c.ChildVocabularyID