-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- Ermittelt zu eiem Mandanten den StandardBusinessDocumentHeader
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 05.07.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE FUNCTION  [Helper].[svf_get_StandardBusinessDocumentHeader]
(
	 @Client   nvarchar(512)
	,@Username nvarchar(512)
	,@EventTyp nvarchar(128)  -- EPCISDocument, EPCISQueryDocument
)
RETURNS XML
AS
BEGIN
	DECLARE @Result				xml;
	DECLARE @currentDate		datetime2(0) = CONVERT(datetime2(0), getdate());
	DECLARE @GLN				nvarchar(512);
	DECLARE @InstanceIdentifier int;
	DECLARE @Partner			TABLE
	(
		GLN   nvarchar(512) NOT NULL,
		Atype nvarchar(512) NOT NULL,
		Value xml           NOT NULL
	);

	-- Load StandardBusinessDocumentHeader for Client
	select TOP 1
		@Result = Value.query('/Value/*')
	FROM [Helper].[tvf_get_Client_Settings] ( @Client, N'urn:quibiq:epcis:atype:StandardBusinessDocumentHeader' );

	-- Aktuelle Uhrzeit
	SET @Result.modify(N'declare namespace sbdh="http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader";
					replace value of (//sbdh:DocumentIdentification/sbdh:CreationDateAndTime/text())[1]
					with sql:variable("@currentDate")');

	-- Document Typ
	SET @Result.modify(N'declare namespace sbdh="http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader";
					replace value of (//sbdh:DocumentIdentification/sbdh:Type/text())[1]
					with sql:variable("@EventTyp")');
	
	IF @Username is not null
	BEGIN
		-- Partnerinformationen ermitteln
		INSERT INTO @Partner (
			GLN,
			Atype,
			Value
		)
		SELECT
			GLN,
			Atype,
			Value
		FROM [Helper].[tvf_get_Partner_Settings] (@Client, @Username);
	END;

	-- GLN ermitteln 
	SELECT TOP 1 @GLN = GLN FROM @Partner;
	
	IF @GLN is null
	BEGIN
		-- Prüfen ob Masteruser
		IF exists (	SELECT TOP 1 1
					FROM (
					SELECT
						Loc.value('.', N'nvarchar(512)') as Username
					FROM [Helper].[tvf_get_Client_Settings] ( @Client, N'urn:quibiq:epcis:atype:masteruser' ) t
					CROSS APPLY t.Value.nodes(N'declare namespace rl="urn:quibiq:epcis:atype:username"; /Value/rl:username/text()') as T2(Loc)
					) a
					where Username = @Username
		)
		BEGIN

			-- GLN ermitteln 
			SET @GLN = @Result.value(N'declare namespace sbdh="http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader";
										(//sbdh:Sender/sbdh:Identifier/text())[1]', N'nvarchar(512)');
			-- Laufnummer ermitteln
			SELECT TOP 1 @InstanceIdentifier =	Value.value(N'.', N'int')
			 FROM [Helper].[tvf_get_Client_Settings](N'urn:quibiq:epcis:cbv:client:gmos', N'urn:quibiq:epcis:atype:instanceidentifier');

		END
		ELSE
		BEGIN
			-- Ansonsten unbekannter Empfänger
			SET @GLN = 'UNKNOWN';
		END;
	END
	ELSE
	BEGIN
		-- Laufnummer ermitteln bei Partner
		SELECT TOP 1 @InstanceIdentifier = Value.value(N'(/Value/text())[1]', N'int') 
		FROM @Partner
		WHERE Atype = N'urn:quibiq:epcis:atype:instanceidentifier';
	END;



	IF @InstanceIdentifier is null
	BEGIN
		SET @InstanceIdentifier = 1;
	END
	ELSE
	BEGIN
		SET @InstanceIdentifier = @InstanceIdentifier + 1;
	END;

	-- Werte setzen
	SET @Result.modify(N'declare namespace sbdh="http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader";
					replace value of (//sbdh:DocumentIdentification/sbdh:InstanceIdentifier/text())[1]
					with sql:variable("@InstanceIdentifier")');
	SET @Result.modify(N'declare namespace sbdh="http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader";
					replace value of (//sbdh:Receiver/sbdh:Identifier/text())[1]
					with sql:variable("@GLN")');

	RETURN @Result;
END;