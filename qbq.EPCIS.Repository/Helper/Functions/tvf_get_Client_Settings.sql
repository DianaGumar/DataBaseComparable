-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- Ermittelt zu Client und Attributtyp aus den SystemStammdaten den entsprechenden Wert
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 06.09.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE FUNCTION [Helper].[tvf_get_Client_Settings]
(
	@Client        nvarchar(512),
    @AttributeType nvarchar(512)
)
RETURNS @returntable TABLE
(
	Value xml NOT NULL
)
AS
BEGIN
	INSERT INTO @returntable (
		Value
	)
	select 
		va2.Value
	from 
		 Vocabulary.Vocabulary v
	join Vocabulary.VocabularyType           vt  on v.VocabularyTypeID    = vt.ID
	join Vocabulary.Vocabulary               syc on v.ClientID            = syc.ID
	join Vocabulary.VocabularyType           svt on syc.VocabularyTypeID  = svt.ID
	-- EPCIS Header Information
	JOIN [Vocabulary].[VocabularyAttribute] va2  on va2.VocabularyID = v.ID 
	JOIN [Vocabulary].[AttributeType]       at2  on at2.ID           = va2.AttributeTypeID
	where
		-- gesuchter Mandant
		      v.URN   = @Client
		and  vt.URN   = N'urn:quibiq:epcis:vtype:client'
		-- Systemmandant
		and syc.URN   = N'urn:quibiq:epcis:cbv:client:epcisrepository'
		and svt.URN   = N'urn:quibiq:epcis:vtype:client'
		-- Attribut
		and at2.URN   = @AttributeType;

	RETURN;
END;