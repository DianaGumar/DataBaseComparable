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
-- 15.07.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-- 26.06.2017 | 1.1.0.0 | Sascha Laabs        | Namespace Änderung durchgeführt. (http://epcis.migros.net/gmos/ -> http://migros.net/gmos/)
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Callback].[usp_get_Subscription]
	@Client nvarchar(255) = null	-- if empty it works for all Clients
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
	SET NOCOUNT ON;
	-- exec [Callback].[usp_get_Subscription]
	-- Monday is 1 - Saturday is 7
	SET DATEFIRST 1;

	BEGIN TRANSACTION;

	-- Declarations
	DECLARE
		@This					datetime2(0) = CAST(getutcdate() as datetime2(0)),
		@Result					xml = CONVERT(xml,N'<ecw:EPCISCallbackWrapper xmlns:ecw="urn:quibiq:epcis:callbackwrapper"/>'),
		@CurQuery				xml,
		@CurDestinationEndpoint nvarchar(512),
		@CurReportIfEmpty       bit,
		@CurRecordTime			datetime2(0),
		@InstanceIdentifier		int,
		@CurUserName            nvarchar(512),
		@CurSubscription		nvarchar(512),
		@CurClient              nvarchar(512);

	BEGIN TRY;

		IF exists(SELECT TOP 1 1
			FROM [Callback].[Schedule] s
			JOIN [Callback].[Subscription]          sub on sub.ID = s.SubscriptionID
			WHERE sub.Active = 1
			  and s.[NextRun] <= @This
		)
		BEGIN
			
			-- Selectiere alle Subscriptions die für den nächsten Lauf zu berücksichtigen sind
			;WITH XMLNAMESPACES (N'urn:quibiq:epcis:callbackwrapper' as epw,
								 N'urn:epcglobal:epcis-query:xsd:1' as equ,
								 N'http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader' as sbdh)
			SELECT @Result = (
			SELECT 
				 sub.Subscription
				,[Helper].[svf_get_StandardBusinessDocumentHeader] ( v.URN, sub.Username, N'EPCISQueryDocument' ) as EPCISHeader
				,sub.Query.query('<equ:Poll>
									{/equ:Poll/queryName/.}
								   <params>
									<param>
										<name>GE_recordTime</name>
										<value>{max((sql:column("LastRecordTime"), sql:column("InitialRecordTime")))}Z</value>
									</param>
									<param>
										<name>LT_recordTime</name>
										<value>{sql:variable("@This")}Z</value>
									</param>	
									{
									if (sql:column("receiverGLN") != "all")
										then (/equ:Poll/params/*[name/text() != "GT_recordTime" and name/text() != "LE_recordTime" and name/text() != "GE_recordTime" and name/text() != "LT_recordTime" and name/text() != "SECURITY_http://migros.net/gmos/" ])
										
										else (/equ:Poll/params/*[name/text() != "GT_recordTime" and name/text() != "LE_recordTime" and name/text() != "GE_recordTime" and name/text() != "LT_recordTime" ])
									}
									{
									if (sql:column("receiverGLN") != "all")
										then (<param>
												<name>SECURITY_http://migros.net/gmos/</name>
												<value>{sql:column("receiverGLN")}</value>
											  </param>)
										else ()
									}
								   </params>
								  </equ:Poll>') as [Query]
				,va.Value.query('/Value/*') as [SOAPQueryControlEndpoints]
				,sub.DestinationEndpoint as [HTTPReceiverEndpoint]
				,sub.ReportIfEmpty as [ForwardEmptyResult]
			FROM [Callback].[Schedule] s
			JOIN [Callback].[Subscription]               sub on sub.ID          = s.SubscriptionID
			-- Client
			JOIN [Vocabulary].[Vocabulary]				 v   on v.ID            = sub.ClientID 
			-- Query Control Endpoint Information
			LEFT JOIN [Vocabulary].[VocabularyAttribute] va  on va.VocabularyID = sub.ClientID 
			LEFT JOIN [Vocabulary].[AttributeType]       at  on at.ID           = va.AttributeTypeID
			-- Query Filters
			CROSS APPLY [Helper].[tvf_get_User_Queryfilter] (v.URN , sub.Username) qf
			WHERE sub.Active = 1
			  and s.[NextRun] <= @This
			  and at.URN  = N'urn:quibiq:epcis:atype:querycontrolendpoint'
			  and (@Client is null or v.URN = @Client)
			FOR XML PATH ('EPCISCallbackRequest'), ROOT ('epw:EPCISCallbackWrapper'), ELEMENTS XSINIL
			);

			-- Update Timestamps
			UPDATE [Callback].[Subscription]
				SET [LastRecordTime] = @This
			FROM [Callback].[Schedule] s
			JOIN [Callback].[Subscription]          sub on sub.ID  = s.SubscriptionID
			WHERE sub.Active = 1
			  and s.[NextRun] <= @This;

			-- Update Laufnummern
			DECLARE curUsername INSENSITIVE CURSOR FOR
				SELECT 
					sub.Subscription,
					sub.Username,
					syc.URN as Client
				FROM [Callback].[Schedule] s
				JOIN [Callback].[Subscription]          sub on sub.ID               = s.SubscriptionID
				JOIN Vocabulary.Vocabulary              syc on sub.ClientID          = syc.ID
				JOIN Vocabulary.VocabularyType          svt on syc.VocabularyTypeID  = svt.ID
				WHERE svt.URN      = N'urn:quibiq:epcis:vtype:client'
				  and sub.Active   = 1
				  and s.[NextRun] <= @This;

			OPEN curUsername;

			FETCH NEXT FROM curUsername INTO @CurSubscription, @CurUserName, @CurClient;

			WHILE @@FETCH_STATUS = 0
			BEGIN

				-- jede Subsription muss ihre eigene Laufnummer haben, es könnten gleichzeitig mehrere Subsriptions von
				-- einem User ausgeführt werden

				-- nächster Identifier
				EXEC [Helper].[usp_Update_InstanceIdentifier] 
					@Client				= @CurClient,
					@Username			= @CurUserName,
					@InstanceIdentifier = @InstanceIdentifier OUT;
				
				-- Subsription anpassen
				SET @Result.modify(N'declare namespace epw="urn:quibiq:epcis:callbackwrapper";
								   declare namespace equ="urn:epcglobal:epcis-query:xsd:1";
								   declare namespace sbdh="http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader";
			
								   replace value of (/epw:EPCISCallbackWrapper/EPCISCallbackRequest/Subscription[text() = sql:variable("@CurSubscription")]/
								   ../EPCISHeader/sbdh:StandardBusinessDocumentHeader/sbdh:DocumentIdentification/sbdh:InstanceIdentifier/text())[1]
								   with sql:variable("@InstanceIdentifier")');

				FETCH NEXT FROM curUsername INTO @CurSubscription, @CurUserName, @CurClient;
			END;

			CLOSE curUsername;
			DEALLOCATE curUsername;

			UPDATE [Callback].[Schedule] 
				SET [NextRun] = [Callback].[svf_Calc_Next_Run] ([ID], @This)
			WHERE   [NextRun] <= @This;

		END

		SELECT @Result;

		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;

		-- Return something
		SELECT @Result = CONVERT(xml,N'<ecw:EPCISCallbackWrapper xmlns:ecw="urn:quibiq:epcis:callbackwrapper"/>');
		SELECT @Result;
	END CATCH;

END;
