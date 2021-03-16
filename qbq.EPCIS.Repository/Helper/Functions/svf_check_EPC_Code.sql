-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- Prüft einen String auf URI Conform und falls URI = urn:epc:id: dann auf die Regeln aus
-- http://www.gs1.org/gsmp/kc/epcglobal/tds/tds_1_3-standard-20060308.pdf Kapitel 4.1
-- 
-- urn:epc:id:gid:GeneralManagerNumber.ObjectClass.SerialNumber
--
-- urn:epc:id:sgtin:CompanyPrefix.ItemReference.SerialNumber (CompanyPrefix+ItemReference = 13)
-- urn:epc:id:sscc:CompanyPrefix.SerialReference (CompanyPrefix+SerialReference = 17)
-- urn:epc:id:sgln:CompanyPrefix.LocationReference.ExtensionComponent (CompanyPrefix+LocationReference = 12)
-- urn:epc:id:grai:CompanyPrefix.AssetType.SerialNumber (CompanyPrefix+AssetType = 12)
--
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 05.09.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
-- 19.12.2013 | 1.0.1.0 | Florian Wagner      | Anpassung SUBSTRING Length Fehler
--            |         | FLW001			  |
-----------------------------------------------------------------------------------------
CREATE FUNCTION [Helper].[svf_check_EPC_Code]
(
	@EPCURN	nvarchar(512)
)
RETURNS BIT
AS
BEGIN
	DECLARE @Valid bit = 0;
	
	IF (SUBSTRING (@EPCURN, 1, 11) = 'urn:epc:id:')
	BEGIN
		-- EPC 
		DECLARE @len            int           = LEN(@EPCURN);
		DECLARE @gidend         int			  = CHARINDEX(N':', @EPCURN, 12);
		DECLARE @gid			nvarchar(5)   = SUBSTRING (@EPCURN, 12, @gidend-12);
		DECLARE @companyend     int			  = CHARINDEX(N'.', @EPCURN, @gidend+1);
		DECLARE @CompanyPrefix	nvarchar(17)  = SUBSTRING (@EPCURN, @gidend+1, IIF(@companyend-(@gidend+1) > 0, @companyend-(@gidend+1), 0));				--FLW001~

		IF @gid = N'sgtin'
		BEGIN
			DECLARE @itemend		int			 = CHARINDEX(N'.', @EPCURN, @companyend+1);
			DECLARE @ItemReference	nvarchar(13) = SUBSTRING (@EPCURN, @companyend+1, IIF(@itemend-(@companyend+1) > 0, @itemend-(@companyend+1), 0));		--FLW001~
			--DECLARE @SerialNumber	nvarchar(100) = SUBSTRING (@EPCURN, @itemend+1, @len-(@itemend));

			IF (LEN(@CompanyPrefix)+LEN(@ItemReference)) = 13	
				SET @Valid = 1
		END;

		IF @gid = N'sscc'
		BEGIN
			DECLARE @SerialReference	nvarchar(17) = SUBSTRING (@EPCURN, @companyend+1, IIF(@len-(@companyend) > 0, @len-(@companyend), 0));				--FLW001~

			IF (LEN(@CompanyPrefix)+LEN(@SerialReference)) = 17
				SET @Valid = 1
		END;

		IF @gid = N'sgln'
		BEGIN
			DECLARE @locend				int			 = CHARINDEX(N'.', @EPCURN, @companyend+1);
			DECLARE @LocationReference	nvarchar(12) = SUBSTRING (@EPCURN, @companyend+1, IIF(@locend-(@companyend+1) > 0, @locend-(@companyend+1), 0));	--FLW001~
			--DECLARE @ExtensionComponent nvarchar(100) = SUBSTRING (@EPCURN, @locend+1, @len-(@locend));

			IF (LEN(@CompanyPrefix)+LEN(@LocationReference)) = 12
				SET @Valid = 1
		END;

		IF @gid = N'grai'
		BEGIN
			DECLARE @assetend	int			 = CHARINDEX(N'.', @EPCURN, @companyend+1);
			DECLARE @AssetType	nvarchar(12) = SUBSTRING (@EPCURN, @companyend+1, IIF(@assetend-(@companyend+1) > 0, @assetend-(@companyend+1), 0));		--FLW001~
			--DECLARE @SerialNumber	nvarchar(100) = SUBSTRING (@EPCURN, @assetend+1, @len-(@assetend));

			IF (LEN(@CompanyPrefix)+LEN(@AssetType)) = 12
				SET @Valid = 1
		END;

		IF @gid = N'giai'
		BEGIN
			DECLARE @IndividualAssetReference nvarchar(100) = SUBSTRING (@EPCURN, @companyend+1, IIF(@len-(@companyend) > 0, @len-(@companyend), 0));		--FLW001~

			IF LEN(@IndividualAssetReference) > 1
				SET @Valid = 1
		END;
		
	END
	ELSE
	BEGIN
		-- URI min 3 Zeichen s:p und min. ein Doppelpunkt auf Position 2 oder höher (nicht C++ Zählweise)
		IF (CHARINDEX(N':', @EPCURN) > 1) AND (LEN(@EPCURN) >= 3)
		BEGIN
			SET @Valid = 1;
		END;
	END;

	RETURN @Valid;
END;
