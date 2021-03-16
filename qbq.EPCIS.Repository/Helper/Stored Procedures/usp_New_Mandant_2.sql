-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [Helper].[usp_New_Mandant]
	-- Add the parameters for the stored procedure here
		@CLIENTUPPER NVARCHAR(100),
		@QUERYSERVERNAME NVARCHAR(100),
		@USER NVARCHAR(1000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

----------------------------------------------------------
-- Set Variables
----------------------------------------------------------
DECLARE	@CLIENTLOWER NVARCHAR(100)

SET @CLIENTLOWER = LOWER(@CLIENTUPPER)

----------------------------------------------------------
-- Vocabulary.VocabularyType only Insert
----------------------------------------------------------
CREATE TABLE #VocabularyType (
    [URN]         NVARCHAR (512) NOT NULL,
    [Description] NVARCHAR (50)  NOT NULL,
    [MaxOccurs]   INT            NOT NULL
     );

-- Insert Content into temp-Table
INSERT INTO #VocabularyType
           ([URN]
           ,[Description]
           ,[MaxOccurs])
     VALUES
           (N'urn:quibiq:epcis:vtype:client'
           ,N''
           ,1);

-- Mix Information (delete/insert won't work because of Foreign Key Constraints)
MERGE INTO [Vocabulary].[VocabularyType] AS TARGET
USING #VocabularyType AS SOURCE
ON (target.[URN] = source.[URN] COLLATE Latin1_General_CI_AS)
--WHEN MATCHED			    
--	THEN UPDATE SET [URN] = source.[URN], [Description] = source.[Description], [MaxOccurs] = source.[MaxOccurs]
WHEN NOT MATCHED BY TARGET 
    THEN INSERT ([URN]
                ,[Description]
                ,[MaxOccurs])
         VALUES (source.[URN], source.[Description], source.[MaxOccurs])
--WHEN NOT MATCHED BY SOURCE 
--	THEN DELETE
;

----------------------------------------------------------
-- Vocabulary.Vocabulary only Insert
----------------------------------------------------------
CREATE TABLE #Vocabulary (
    [ClientID]         BIGINT         NOT NULL,
    [VocabularyTypeID] BIGINT         NOT NULL,
    [URN]              NVARCHAR (512) NOT NULL
)

INSERT INTO #Vocabulary
           ([ClientID]
           ,[VocabularyTypeID]
           ,[URN])
     VALUES
           (1
           ,1
           ,N'urn:quibiq:epcis:cbv:client:epcisrepository')
           ,
           (1
           ,1
           ,N'urn:quibiq:epcis:cbv:client:' + @CLIENTLOWER);

-- Mix Information (delete/insert won't work because of Foreign Key Constraints)
MERGE INTO [Vocabulary].[Vocabulary] AS TARGET
USING #Vocabulary AS SOURCE
ON (target.[URN] = source.[URN] COLLATE Latin1_General_CI_AS and target.[ClientID] = source.[ClientID] and target.[VocabularyTypeID] = source.[VocabularyTypeID])
--WHEN MATCHED			    
--	THEN UPDATE SET [URN] = source.[URN], [ClientID] = source.[ClientID], [VocabularyTypeID] = source.[VocabularyTypeID]
WHEN NOT MATCHED BY TARGET 
    THEN INSERT ([ClientID]
                 ,[VocabularyTypeID]
                 ,[URN])
         VALUES (source.[ClientID], source.[VocabularyTypeID], source.[URN])
--WHEN NOT MATCHED BY SOURCE 
--	THEN DELETE
;
----------------------------------------------------------
-- Vocabulary.VocabularyType_Client only Insert
----------------------------------------------------------
IF (not exists (select 1 from Vocabulary.VocabularyType_Client))
BEGIN
INSERT INTO Vocabulary.VocabularyType_Client (VocabularyTypeID, ClientID) VALUES (1, 1);
END;

drop table #VocabularyType;
drop table #Vocabulary;

DECLARE @RC int
DECLARE @EPCISMasterData xml
DECLARE @Client nvarchar(255)

set @Client = N'urn:quibiq:epcis:cbv:client:epcisrepository';

set @EPCISMasterData = N'<?xml version="1.0" encoding="utf-16" standalone="yes"?>
<epcismd:EPCISMasterDataDocument xmlns:epcismd="urn:epcglobal:epcis-masterdata:xsd:1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" schemaVersion="1" creationDate="2015-03-17T09:22:00+02:00">
	<EPCISBody>
		<VocabularyList>
			<Vocabulary type="urn:quibiq:epcis:vtype:action">
				<VocabularyElementList>
					<VocabularyElement id="urn:quibiq:epcis:cbv:action:add"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:action:observe"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:action:delete"/>
				</VocabularyElementList>
			</Vocabulary>
			<Vocabulary type="urn:quibiq:epcis:vtype:event">
				<VocabularyElementList>
					<VocabularyElement id="urn:quibiq:epcis:cbv:event:object"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:event:aggregation"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:event:quantity"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:event:transaction"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:event:transformation"/>		
				</VocabularyElementList>
			</Vocabulary>
			<Vocabulary type="urn:quibiq:epcis:vtype:valuetype">
				<VocabularyElementList>
					<VocabularyElement id="urn:quibiq:epcis:cbv:valuetype:quantity"/>
				</VocabularyElementList>
			</Vocabulary>
			<Vocabulary type="urn:quibiq:epcis:vtype:datatype">
				<VocabularyElementList>
					<VocabularyElement id="urn:quibiq:epcis:cbv:datatype:int"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:datatype:float"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:datatype:time"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:datatype:xml"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:datatype:string"/>
					<VocabularyElement id="urn:quibiq:epcis:cbv:datatype:unknown"/>
				</VocabularyElementList>
			</Vocabulary>
			<Vocabulary type="urn:quibiq:epcis:vtype:extensiontype"/>
			<Vocabulary type="urn:quibiq:epcis:vtype:ilmd"/>
		</VocabularyList>
	</EPCISBody>
</epcismd:EPCISMasterDataDocument>'

EXECUTE @RC = [Import].[usp_Import_MasterData_to_Queue] 
   @EPCISMasterData
  ,@Client

set @Client = N'urn:quibiq:epcis:cbv:client:epcisrepository';

set @EPCISMasterData = N'<epcismd:EPCISMasterDataDocument xmlns:epcismd="urn:epcglobal:epcis-masterdata:xsd:1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" schemaVersion="1" creationDate="2005-07-11T11:30:47.0Z">
<EPCISBody>
	<VocabularyList>
		<Vocabulary type="urn:quibiq:epcis:vtype:client">
			<VocabularyElementList>
				<VocabularyElement id="urn:quibiq:epcis:cbv:client:' + @CLIENTLOWER + '">
					<attribute id="urn:quibiq:epcis:atype:receiveport">
						<receiveport xmlns ="urn:quibiq:epcis:atype:receiveport">GetEPCISDocumentRcvPort_' + @CLIENTUPPER + '</receiveport>
						<receiveport xmlns ="urn:quibiq:epcis:atype:receiveport">GetEPCISMasterDataServiceSoap_' + @CLIENTUPPER + '</receiveport>    
					</attribute>
					<attribute id="urn:quibiq:epcis:atype:querycontrolendpoint">
						<endpoint xmlns ="urn:quibiq:epcis:atype:querycontrolendpoint">' + @QUERYSERVERNAME + '/EPCISQueryHTTP/EPCISQueryHttpService.svc/Request?mandant:urn:quibiq:epcis:cbv:client:' + @CLIENTLOWER + '</endpoint>
					</attribute>
					<attribute id="urn:quibiq:epcis:atype:StandardBusinessDocumentHeader">
						<sbdh:StandardBusinessDocumentHeader xmlns:sbdh="http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader">
							<sbdh:HeaderVersion>1.0</sbdh:HeaderVersion>
							<sbdh:Sender>
								<sbdh:Identifier Authority="EAN.UCC">urn:epc:id:gln:7617007099109</sbdh:Identifier>
							</sbdh:Sender>
							<sbdh:Receiver>
								<sbdh:Identifier Authority="EAN.UCC">urn:epc:id:gln:</sbdh:Identifier>
							</sbdh:Receiver>
							<sbdh:DocumentIdentification>
								<sbdh:Standard>EPCISStandard</sbdh:Standard>
								<sbdh:TypeVersion>1.1</sbdh:TypeVersion>
								<sbdh:InstanceIdentifier>Laufnummer</sbdh:InstanceIdentifier>
								<sbdh:Type>Event</sbdh:Type>
								<sbdh:MultipleType>false</sbdh:MultipleType>
								<sbdh:CreationDateAndTime>CurrentDate</sbdh:CreationDateAndTime>
							</sbdh:DocumentIdentification>
							<sbdh:Manifest>
								<sbdh:NumberOfItems>AnzahlSaetze</sbdh:NumberOfItems>
								<sbdh:ManifestItem>
									<sbdh:MimeTypeQualifierCode>text/xml</sbdh:MimeTypeQualifierCode>
									<sbdh:UniformResourceIdentifier>urn:epcglobal</sbdh:UniformResourceIdentifier>
								</sbdh:ManifestItem>
							</sbdh:Manifest>
						</sbdh:StandardBusinessDocumentHeader>
					</attribute>
					<attribute id="urn:quibiq:epcis:atype:instanceidentifier">0</attribute>
					<attribute id="urn:quibiq:epcis:atype:masteruser">' +
						@USER +
					'</attribute>
				</VocabularyElement>
			</VocabularyElementList>
		</Vocabulary>
	</VocabularyList>
</EPCISBody>
</epcismd:EPCISMasterDataDocument>'

EXECUTE @RC = [Import].[usp_Import_MasterData_to_Queue] 
   @EPCISMasterData
  ,@Client


set @Client = N'urn:quibiq:epcis:cbv:client:' + @CLIENTLOWER;

set @EPCISMasterData = N'<?xml version="1.0" encoding="utf-16" standalone="yes"?>
<epcismd:EPCISMasterDataDocument xmlns:epcismd="urn:epcglobal:epcis-masterdata:xsd:1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" schemaVersion="1" creationDate="2015-03-17T09:22:00+02:00">
	<EPCISBody>
		<VocabularyList>
			<Vocabulary type="urn:epcglobal:epcis:vtype:ReadPoint">
			</Vocabulary>
			<Vocabulary type="urn:epcglobal:epcis:vtype:BusinessLocation">
			</Vocabulary>
			<Vocabulary type="urn:epcglobal:epcis:vtype:SourceDest">
			</Vocabulary>
			<Vocabulary type="urn:epcglobal:epcis:vtype:BusinessStep">
				<VocabularyElementList>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:accepting"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:arriving"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:assembling"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:collecting"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:commissioning"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:consigning"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:creating_class_instance"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:cycle_counting"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:decommissioning"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:departing"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:destroying"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:disassembling"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:encoding"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:entering_exiting"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:holding"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:inspecting"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:installing"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:killing"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:loading"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:other"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:packing"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:picking"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:receiving"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:removing"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:repackaging"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:repairing"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:replacing"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:reserving"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:retail_selling"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:shipping"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:staging_outbound"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:stock_taking"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:stocking"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:storing"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:transforming"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:transporting"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:unloading"/>
					<VocabularyElement id="urn:epcglobal:cbv:bizstep:unpacking"/>
				</VocabularyElementList>
			</Vocabulary>
			<Vocabulary type="urn:epcglobal:epcis:vtype:Disposition">
				<VocabularyElementList>
					<VocabularyElement id="urn:epcglobal:cbv:disp:active"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:container_closed"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:destroyed"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:encoded"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:inactive"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:in_progress"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:in_transit"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:non_sellable_expired"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:non_sellable_damaged"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:non_sellable_disposed"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:non_sellable_no_pedigree_match"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:non_sellable_recalled"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:expired"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:damaged"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:disposed"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:no_pedigree_match"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:non_sellable_other"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:recalled"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:reserved"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:returned"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:sellable_accessible"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:sellable_not_accessible"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:retail_sold"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:stolen"/>
					<VocabularyElement id="urn:epcglobal:cbv:disp:unknown"/>	
					<VocabularyElement id="http://epcis.migros.net/migros/disposition/dutied"/>				
				</VocabularyElementList>
			</Vocabulary>
			<!--Vocabulary type="urn:epcglobal:epcis:vtype:BusinessTransaction">
				</Vocabulary!-->
			<Vocabulary type="urn:epcglobal:epcis:vtype:BusinessTransactionType">
				<VocabularyElementList>
					<VocabularyElement id="urn:epcglobal:cbv:btt:po"/>
					<VocabularyElement id="urn:epcglobal:cbv:btt:poc"/>
					<VocabularyElement id="urn:epcglobal:cbv:btt:bol"/>
					<VocabularyElement id="urn:epcglobal:cbv:btt:inv"/>
					<VocabularyElement id="urn:epcglobal:cbv:btt:rma"/>
					<VocabularyElement id="urn:epcglobal:cbv:btt:pedigree"/>
					<VocabularyElement id="urn:epcglobal:cbv:btt:desadv"/>
					<VocabularyElement id="urn:epcglobal:cbv:btt:recadv"/>
					<VocabularyElement id="urn:epcglobal:cbv:btt:prodorder"/>
					<VocabularyElement id="urn:epcglobal:fmcg:btt:po"/>
					<VocabularyElement id="urn:epcglobal:fmcg:btt:desadv"/>
				</VocabularyElementList>
			</Vocabulary>
			<Vocabulary type="urn:epcglobal:epcis:vtype:EPCClass">	
				<VocabularyElementList>
					<VocabularyElement id="urn:epc:class:lgtin:0761702.758320.L-Y15"/>
					<VocabularyElement id="urn:epc:class:lgtin:0761702.780772.L-Y15"/>			
					<VocabularyElement id="urn:epc:class:lgtin:0761702.780772.L-X12"/>		
					<VocabularyElement id="urn:epc:idpat:sgtin:0761020.038433.*"/>		
					<VocabularyElement id="urn:epc:class:lgtin:0761702.780772.Lot15"/>
					<VocabularyElement id="urn:epc:class:lgtin:0761020.027766.L-R01"/>		
					<VocabularyElement id="urn:epc:class:lgtin:0761020.038433.L-E52"/>		
					<VocabularyElement id="urn:epc:idpat:sgtin:0761020.027766.*"/>		
					<VocabularyElement id="urn:epc:idpat:sgtin:0761020.027995.*"/>	
				</VocabularyElementList>	
			</Vocabulary>
			<Vocabulary type="urn:epcglobal:epcis:vtype:SourceDestType">
				<VocabularyElementList>
					<VocabularyElement id="urn:epcglobal:cbv:sdt:owning_party"/>
					<VocabularyElement id="urn:epcglobal:cbv:sdt:possessing_party"/>
					<VocabularyElement id="urn:epcglobal:cbv:sdt:location"/>
					<VocabularyElement id="http://epcis.migros.net/migros/elements/destination/SU"/>
					<VocabularyElement id="http://epcis.migros.net/migros/elements/destination/DP"/>
					<VocabularyElement id="http://epcis.migros.net/migros/elements/destination/UC"/>
					<VocabularyElement id="http://migros.net/migros/ele/dest/SU"/>
					<VocabularyElement id="http://migros.net/migros/ele/dest/UC"/>
					<VocabularyElement id="http://migros.net/migros/ele/dest/DP"/>
				</VocabularyElementList>
			</Vocabulary>
		</VocabularyList>
	</EPCISBody>
</epcismd:EPCISMasterDataDocument>'

EXECUTE @RC = [Import].[usp_Import_MasterData_to_Queue] 
   @EPCISMasterData
  ,@Client
END