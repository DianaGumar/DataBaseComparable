-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- Ermittelt die Mandanten VocabularyID sowie den aktuellen Systemmandanten via URN
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 05.07.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE FUNCTION [Import].[tvf_get_ClientID]
(
	@Client nvarchar(512)
)
RETURNS TABLE RETURN
(
	select
		v.ID   as ClientID,
		syc.ID as SystemClientID
	from 
		 Vocabulary.Vocabulary v
	join Vocabulary.VocabularyType vt  on v.VocabularyTypeID   = vt.ID
	join Vocabulary.Vocabulary     syc on v.ClientID           = syc.ID
	join Vocabulary.VocabularyType svt on syc.VocabularyTypeID = svt.ID
	where
		-- gesuchter Mandant
		      v.URN   = @Client
		and  vt.URN   = N'urn:quibiq:epcis:vtype:client'
		-- Systemmandant
		and syc.URN   = N'urn:quibiq:epcis:cbv:client:epcisrepository'
		and svt.URN   = N'urn:quibiq:epcis:vtype:client'
)