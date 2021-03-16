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
-- 17.08.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE FUNCTION [Helper].[tvf_get_MandantenReceivePorts]()
RETURNS TABLE as
RETURN
(
		select
			Loc.value('.', N'nvarchar(512)') as ReceivePort,
			v.URN as Client
		from Vocabulary.VocabularyAttribute va
		CROSS APPLY Value.nodes('declare namespace rl="urn:quibiq:epcis:atype:receiveport"; /Value/rl:receiveport/text()') as T2(Loc) 
		join Vocabulary.AttributeType       at on at.ID = va.AttributeTypeID
		join Vocabulary.Vocabulary           v on  v.ID = va.VocabularyID 
		join Vocabulary.VocabularyType      vt on vt.ID = v.VocabularyTypeID
		where
			vt.URN = N'urn:quibiq:epcis:vtype:client'
		and at.URN = N'urn:quibiq:epcis:atype:receiveport'
)