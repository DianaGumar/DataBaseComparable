-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- Ermittelt zu eienem Partner alle Informationen aus den Stammdaten
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 06.09.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE FUNCTION [Helper].[tvf_get_Partner_Settings]
(
	@Client   nvarchar(512),
    @Username nvarchar(512) = null
)
RETURNS @returntable TABLE
(
	GLN      nvarchar(512) NOT NULL,
	Username nvarchar(512) NOT NULL,
	Atype    nvarchar(512) NOT NULL,
	Value    xml           NOT NULL
)
AS
BEGIN

	IF @Username is not null
	BEGIN

		INSERT INTO @returntable (
			GLN,
			Username,
			Atype,
			Value
		)
		select 
			v.URN as GLN, @Username as Username, at2.URN as ATYPE, va2.Value
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
				syc.URN   = @Client
			and svt.URN   = N'urn:quibiq:epcis:vtype:client'
			and vt.URN    = N'urn:gmos:epcis:vtype:partners'
			-- N'urn:quibiq:epcis:atype:StandardBusinessDocumentHeader'
			and v.ID = 
				-- Einschränkung auf User
				(	select v.ID 
					from 
							Vocabulary.Vocabulary v
					join Vocabulary.VocabularyType           vt  on v.VocabularyTypeID    = vt.ID
					join Vocabulary.Vocabulary               syc on v.ClientID            = syc.ID
					join Vocabulary.VocabularyType           svt on syc.VocabularyTypeID  = svt.ID
					-- EPCIS Header Information
					JOIN [Vocabulary].[VocabularyAttribute] va2  on va2.VocabularyID = v.ID 
					JOIN [Vocabulary].[AttributeType]       at2  on at2.ID           = va2.AttributeTypeID and va2.Deleted = 0 -- gelöschte Partner sollen nicht berücksichtigt werden
					where   syc.URN   = @Client
						and svt.URN   = N'urn:quibiq:epcis:vtype:client'
						and va2.Value.exist(N'/Value[text() = sql:variable("@username")]') = 1
				);
	END
	ELSE
	BEGIN
		DECLARE @usernametable TABLE
		(
			GLN      nvarchar(512) NOT NULL,
			Username nvarchar(512) NOT NULL
		);

		INSERT INTO @returntable (
			GLN,
			Username,
			Atype,
			Value
		)
		select 
			v.URN as GLN, 'UNKNOWN' as Username, at2.URN as ATYPE, va2.Value
		from 
			 Vocabulary.Vocabulary v
		join Vocabulary.VocabularyType           vt  on v.VocabularyTypeID    = vt.ID
		join Vocabulary.Vocabulary               syc on v.ClientID            = syc.ID
		join Vocabulary.VocabularyType           svt on syc.VocabularyTypeID  = svt.ID
		-- EPCIS Header Information
		JOIN [Vocabulary].[VocabularyAttribute] va2  on va2.VocabularyID = v.ID 
		JOIN [Vocabulary].[AttributeType]       at2  on at2.ID           = va2.AttributeTypeID and va2.Deleted = 0 -- gelöschte Partner sollen nicht berücksichtigt werden
		where
			-- gesuchter Mandant
				syc.URN   = @Client
			and svt.URN   = N'urn:quibiq:epcis:vtype:client'
			and vt.URN    = N'urn:gmos:epcis:vtype:partners';

		-- Usernamen extrahieren
		INSERT INTO @usernametable (
			GLN,
			Username
		)
		SELECT 
			GLN,
			Value.value(N'(/Value/text())[1]', N'nvarchar(512)') as Username
		FROM @returntable
		WHERE Atype = N'urn:quibiq:epcis:atype:username';

		-- Usernamen übernehmen
		UPDATE @returntable 
			SET Username = b.Username 
		FROM @returntable a
		JOIN @usernametable b on (b.GLN = a.GLN );
		
	END;

	RETURN;
END;