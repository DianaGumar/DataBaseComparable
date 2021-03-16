-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- Erhöht den InstanceIdentifier Wert um eins oder fügt ihn Hinzu falls noch nicht vorhanden
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 06.09.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Helper].[usp_Update_InstanceIdentifier]
	@Client				nvarchar(512),
	@Username			nvarchar(512),
	@InstanceIdentifier int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @GLN                nvarchar(512) = null;
	--DECLARE @InstanceIdentifier int;
	DECLARE @XMLValue           xml = CAST(N'<Value>1</Value>' as XML);

	IF @Username is not null
	BEGIN
		select top 1
			@GLN = GLN, 
			@InstanceIdentifier = Value.value(N'(Value/text())[1]', N'int') 
		from [Helper].[tvf_get_Partner_Settings]( @Client, @Username )
		where Atype = N'urn:quibiq:epcis:atype:instanceidentifier';
	END;


	IF @GLN is null
	BEGIN
		-- InstanceIdentifier noch nicht angelegt zu User
		SET @InstanceIdentifier = 1;

		IF @Username is not null
		BEGIN
			select top 1
				@GLN = GLN
			from [Helper].[tvf_get_Partner_Settings]( @Client, @Username );
		END;
		
		IF @GLN is null 
		BEGIN
			-- Prüfen ob Masteruser
			IF exists ( SELECT TOP 1 1
					FROM (
					SELECT
						Loc.value('.', N'nvarchar(512)') as Username
					FROM [Helper].[tvf_get_Client_Settings] ( @Client, N'urn:quibiq:epcis:atype:masteruser' ) t
					CROSS APPLY t.Value.nodes(N'declare namespace rl="urn:quibiq:epcis:atype:username"; /Value/rl:username/text()') as T2(Loc)
					) a
					where Username = @Username )
			BEGIN
				-- Laufnummer ermitteln
				SELECT TOP 1 @InstanceIdentifier =	Value.value(N'.', N'int')
				 FROM [Helper].[tvf_get_Client_Settings]( @Client, N'urn:quibiq:epcis:atype:instanceidentifier' );

				IF @InstanceIdentifier is null
				BEGIN
					-- Einfügen Instance Identifier
					INSERT INTO [Vocabulary].[VocabularyAttribute] (
						VocabularyID,
						AttributeTypeID,
						Value
					)
					SELECT
							v.ID,
							at2.ID,
							@XMLValue
					FROM  
							Vocabulary.Vocabulary v
					join Vocabulary.VocabularyType           vt  on v.VocabularyTypeID    = vt.ID
					join Vocabulary.Vocabulary               syc on v.ClientID            = syc.ID
					join Vocabulary.VocabularyType           svt on syc.VocabularyTypeID  = svt.ID
					JOIN [Vocabulary].[AttributeType]       at2  on at2.URN = N'urn:quibiq:epcis:atype:instanceidentifier'
					where
						-- gesuchter Mandant
							syc.URN   = N'urn:quibiq:epcis:cbv:client:epcisrepository'
						and svt.URN   = N'urn:quibiq:epcis:vtype:client'
						and vt.URN    = N'urn:quibiq:epcis:vtype:client'
						and v.URN     = @Client;

				END
				ELSE
				BEGIN
					-- Aktualisieren Instance Identifier
					SET @InstanceIdentifier = @InstanceIdentifier + 1;

					UPDATE [Vocabulary].[VocabularyAttribute] 
						SET Value.modify(N'replace value of (//Value/text())[1]
													with sql:variable("@InstanceIdentifier")')
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
							syc.URN   = N'urn:quibiq:epcis:cbv:client:epcisrepository'
						and svt.URN   = N'urn:quibiq:epcis:vtype:client'
						and vt.URN    = N'urn:quibiq:epcis:vtype:client'
						and at2.URN   = N'urn:quibiq:epcis:atype:instanceidentifier'
						and v.URN     = @Client;

				END;

				RETURN;

			END
			ELSE
			BEGIN
				-- Falls auch kein Masteruser ausspringen -> keine weitere Aktion
				RETURN;
			END;
		END;
		

		-- Hinzufügen des Attributs zum Partner
		INSERT INTO [Vocabulary].[VocabularyAttribute] (
			VocabularyID,
			AttributeTypeID,
			Value
		)
		SELECT
			 v.ID,
			 at2.ID,
			 @XMLValue
		FROM  
			 Vocabulary.Vocabulary v
		join Vocabulary.VocabularyType           vt  on v.VocabularyTypeID    = vt.ID
		join Vocabulary.Vocabulary               syc on v.ClientID            = syc.ID
		join Vocabulary.VocabularyType           svt on syc.VocabularyTypeID  = svt.ID
		JOIN [Vocabulary].[AttributeType]       at2  on at2.URN = N'urn:quibiq:epcis:atype:instanceidentifier'
		where
			-- gesuchter Mandant
				syc.URN   = @Client
			and svt.URN   = N'urn:quibiq:epcis:vtype:client'
			and vt.URN    = N'urn:gmos:epcis:vtype:partners'
			and v.URN     = @GLN;
			
	END
	ELSE
	BEGIN
		-- InstanceIdentifier des Partner anpassen
		SET @InstanceIdentifier = @InstanceIdentifier + 1;

		UPDATE [Vocabulary].[VocabularyAttribute] 
			SET Value.modify(N'replace value of (//Value/text())[1]
										with sql:variable("@InstanceIdentifier")')
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
			and at2.URN   = N'urn:quibiq:epcis:atype:instanceidentifier'
			and v.URN     = @GLN;
			
	END;

END;