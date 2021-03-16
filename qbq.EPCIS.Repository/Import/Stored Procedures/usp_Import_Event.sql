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
-- 27.02.2013 | 1.0.0.0 | Sven Scholle	      | Erstellt.
-----------------------------------------------------------------------------------------
-- 10.04.2014 | 1.0.0.1 | Florian Wagner      | FLW001 - HOLDLOCK an BusinessTransactionID, String_Value, EPC Merge
-----------------------------------------------------------------------------------------
-- 13.05.2014 | 1.0.1.0 | Florian Wagner      | FLW002 - Mandant bei Stammdaten Merge verwenden
-----------------------------------------------------------------------------------------
-- 21.07.2014 | 1.0.2.0 | Florian Wagner      | FLW003 - Nur als nicht gelöscht markierte Stammdaten verwenden
-----------------------------------------------------------------------------------------
-- 30.01.2015 | 2.0.0.0 | Florian Wagner      | FLW004 - EPCIS 1_1 Erweiterungen
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Import_Event]
		@EPCISEvent			xml,
		@Client             nvarchar(512),
		@Debug				bit = 0,
		@RecordTime			datetime2 output
AS
BEGIN

	-----------------------------------------------------------------
	-- Variablendeklaration 
	-----------------------------------------------------------------

	declare
		@Error							bit = 0,
		@ErrorMsg						nvarchar(2048), 

		@AddNewVocabulary				bit = 0,
		@AddBizLocAndReadPoints			bit = 1, 
		@AddEPCClass					bit = 1,
		@AddSourceDestination			bit = 1,
		@ProcessOnlyWholeDocument		bit = 1,  

		@EPCISEventList					xml,
		@CurEvent						xml,
		@StandardBusinessDocumentHeader	xml,

		@SystemClientID					bigint,  -- SystemclientID
		@ClientID						bigint;  -- Client ID


		-----------------------------------------------------------------
		-- Tabelle zum Zwischenspeichern der Wurzel-Event Daten
		-----------------------------------------------------------------

		create table #EventData
		(
			EPCISEventID			bigint			   not null PRIMARY KEY IDENTITY(1,1),
			[ClientID]              BIGINT             NOT NULL,
			[EventTime]             DATETIME2 (0)      NOT NULL,
			[RecordTime]            DATETIME2 (0)      NOT NULL,
			[EventTimeZoneOffset]   DATETIMEOFFSET (7) NOT NULL,
			[EPCISRepresentation]   XML                NOT NULL
		);

		-----------------------------------------------------------------
		-- Mapping-Tabelle zwischen SP und Tabellen EPCISEventID
		-----------------------------------------------------------------

		create table #EPCISEventIDs
		(
			EPCISEventID		   bigint		not null PRIMARY KEY,
			TechnicalEPCISEventID  bigint       not null
		);

		-----------------------------------------------------------------
		-- Tabelle zum Zwischenspeichern der hierachischen Vokabeln, da IDs erst bekannt sind,
		-- wenn alles andere vorher eingetragen ist.
		-----------------------------------------------------------------

		create table #EPCISEvent_Vocabulary
		(
			VocabularyTypeURN	nvarchar(512)	not null,
			VocabularyURN		nvarchar(512)	not null,
			VocabularyTypeID	bigint			null,
			ID					bigint			null,
			EPCISEventID		bigint			not null
		);


		-----------------------------------------------------------------
		-- Tabelle zum Zwischenspeichern der EPCs
		-----------------------------------------------------------------
	
		create table #EPCISEvent_EPC
		(
			EPCURN			nvarchar(512)	not null,
			EPCID			bigint			null,
			EPCISEventID	bigint			not null,
			IsParentID		bit				not null,
			IsInput			bit				not null,
			IsOutput		bit				not null,
		);


		-----------------------------------------------------------------
		-- Tabelle zum Zwischenspeichern der BusinessTransactions
		-----------------------------------------------------------------
	
		create table #EPCISEvent_BusinessTransactionID
		(
			BusinessTransactionIDURN	nvarchar(512)	not null,
			BusinessTransactionTypeURN	nvarchar(512)	not null,
			VocabularyTypeURN			nvarchar(512)	not null,
			BusinessTransactionIDID		bigint			null,
			BusinessTransactionTypeID	bigint			null,
			VocabularyTypeID			bigint			null,
			EPCISEventID				bigint			not null
		);

		-----------------------------------------------------------------
		-- Tabelle zum Zwischenspeichern der QuantityElements
		-----------------------------------------------------------------

		create table #EPCISEvent_QuantityElement
		(
			EPCISEventID			bigint			not null,
			EPCClassURN				nvarchar(512)	not null,
			EPCClassID				bigint			null,
			Quantity				float(53)		not null,
			UOM						nchar(3)		not null default (''),
			IsInput					bit				not null,
			IsOutput				bit				not null,
			QuantityElementID		bigint			null,
		);

		-----------------------------------------------------------------
		-- Tabelle zum Zwischenspeichern der SourceDestination
		-----------------------------------------------------------------

		create table #EPCISEvent_SourceDestination
		(
			EPCISEventID				bigint		  not null,
			IsSource					bit			  not null,
			SourceDestinationURN		nvarchar(512) not null,
			SourceDestinationTypeURN	nvarchar(512) not null,
			SourceDestinationID			bigint		  null,
			SourceDestinationTypeID		bigint		  null,
		);

		-----------------------------------------------------------------
		-- Tabelle zum Zwischenspeichern der TransformationID
		-----------------------------------------------------------------

		create table #EPCISEvent_TransformationID
		(
			EPCISEventID				bigint		  not null,
			TransformationIDURN			nvarchar(512) not null,
			TransformationIDID			bigint		  null,
		);

		-----------------------------------------------------------------
		-- Tabelle zum Zwischenspeichern der Extension-Typen wie
		-----------------------------------------------------------------

		create table #EPCISEvent_ExtenstionType
		(
			EPCISEventID		 bigint			not null,
			ExtensionTypeURN	 nvarchar(512)	not null,
			ExtensionTypeTypeURN nvarchar(512)	not null
		);

		-----------------------------------------------------------------
		-- Tabelle zum Zwischenspeichern der Values wie z.B. quantity und extension fields
		-----------------------------------------------------------------

		create table #EPCISEvent_Value
		(
			ValueTypeURN		nvarchar(512)	not null,
			ValueTypeTypeURN	nvarchar(512)	not null,
			DataTypeURN			nvarchar(512)	not null,
			DataTypeTypeURN		nvarchar(512)	not null,
			ValueTypeID			bigint			null,
			ValueTypeTypeID		bigint			null,
			DataTypeID			bigint			null,
			DataTypeTypeID		bigint			null,
			EPCISEventID		bigint			not null,
			IntValue			bigint			null,
			FloatValue			float			null,
			TimeValue			datetimeoffset	null,
			StringValue 		nvarchar(max)	null,
			ParentURN			nvarchar(512)	null,
			Depth				int				not null,
			ExtensionType       bit             not null
		);


		create table #EPCISEvent_Value_Values
		(
			EPCISEvent_ValueID					bigint         not null,
			ValueTypeURN						nvarchar(512)	not null,
			DataTypeURN							nvarchar(512)	not null,
			IntValue							bigint			null,
			FloatValue							float			null,
			TimeValue							datetimeoffset	null,
			StringValue 						nvarchar(max)	null,
			ParentURN							nvarchar(512)	not null,
			Parent_EPCISEvent_ValueID			bigint			null,
			Depth								int				not null
		);

		create table #EPCISEvent_Value_String_Value_String
		(
			EPCISEvent_ValueID  bigint       not null,
			Value_StringID		bigint      not null
		);



		-----------------------------------------------------------------
		-- Tabelle zum Zwischenspeichern von Eventfehlerklassen
		-----------------------------------------------------------------
		create table #EPCISEvent_Error
		(
			EPCISEventID	 bigint			 not null,
			Reason		 	 nvarchar(4000)  not null
		);

		--***************************************************************
		-- MandantenID bestimmen
		--***************************************************************

		set @ClientID = 0

		select TOP 1
			@ClientID       = ClientID,
			@SystemClientID = SystemClientID
		from [Import].[tvf_get_ClientID] (@Client);

		if @ClientID = 0
		begin
			--***************************************************************
			-- Fehler werfen, falls Mandant nicht gefunden
			--***************************************************************

			set @ErrorMsg = 'Mandant ''' + @Client + ''' does not exist.';
			throw 50000, @ErrorMsg, 1

		end;

		--***************************************************************
		-- Header laden
		--***************************************************************

		with xmlnamespaces (N'urn:epcglobal:epcis:xsd:1' as epcg)
		select
			@StandardBusinessDocumentHeader = @EPCISEvent.query(N'/epcg:EPCISDocument/EPCISHeader/*');

		--***************************************************************
		-- Liste der Events laden
		--***************************************************************
		with xmlnamespaces (N'urn:epcglobal:epcis:xsd:1' as epcg)
		select
			@EPCISEventList = @EPCISEvent.query(N'/epcg:EPCISDocument/EPCISBody/EventList/.');

		--***************************************************************
		-- per Schleife durch Liste aller Events durcharbeiten
		--***************************************************************
		declare curEvent INSENSITIVE cursor for
			select
				content.nodes.query(N'.')
			from
				@EPCISEventList.nodes(N'/*/*/.') as content(nodes);

		open curEvent

		fetch next from curEvent into @CurEvent

		while @@FETCH_STATUS = 0
		begin

			--***************************************************************
			-- Scope Declarations
			--***************************************************************
				declare
					@xmlPath				nvarchar(max),
					@EPCISEPCISEventID		bigint,
					@EPCISEventTime			datetime2(7),
					@EPCISEventTimeZoneOffset	datetimeoffset,	
					@EPCISEventTimeString   nvarchar(50),

					@EPCISEventTypePath		nvarchar(128),
					@ValueTypeURN			nvarchar(512),
					@DataTypeURN			nvarchar(512),
					@ValueTypeTypeURN		nvarchar(512),
					@DataTypeTypeURN		nvarchar(512),
					@IntValue				int,
					@CharValue				nvarchar(512),
		
					@IsOutput				bit,
					@EPCList				xml,
					@EPCURN					nvarchar(512),
					@BizTransactionList		xml,
					@XmlList				xml,

					@VocabularyTypeURN		nvarchar(512),
					@VocabularyURN			nvarchar(512);

				declare @OutputEPCISEventID table (
					ID bigint
				);
			
			--***************************************************************
			-- EventTyp auslesen um xmlPath bauen zu können
			--***************************************************************

			select
				@EPCISEventTypePath= cast(@CurEvent.query('local-name((/*)[1])') as nvarchar(128))	

			--***************************************************************
			-- EPCIS 1.1 TransformationEvent - Sonderbehandlung - (Liegt unter extension)
			--***************************************************************

			if (@EPCISEventTypePath = N'extension')
			begin
				SET @CurEvent = @CurEvent.query(N'/extension/*');

				select
					@EPCISEventTypePath= cast(@CurEvent.query('local-name((/*)[1])') as nvarchar(128))	
			end;

			--***************************************************************
			-- EventTime und -ZoneOffset auslesen
			--***************************************************************
			
			--select @EPCISEventTime = @CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/eventTime/node())[1]', 'datetime2(7)');
			--select @EPCISEventTimeZoneOffset = SWITCHOFFSET(convert(datetimeoffset, @EPCISEventTime), @CurEvent.value('(//eventTimeZoneOffset/node())[1]', 'varchar(6)'));

			select @EPCISEventTimeString = @CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/eventTime/node())[1]', 'nvarchar(50)');

			if @EPCISEventTimeString not like N'%Z%' and
			   @EPCISEventTimeString not like N'%+%' and
			   @EPCISEventTimeString not like N'%-%'
			BEGIN

				select @EPCISEventTimeZoneOffset = convert(datetimeoffset, @CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/eventTime/node())[1]', 'nvarchar(50)') + @CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/eventTimeZoneOffset/node())[1]', 'nvarchar(6)'));
				select @EPCISEventTime = convert(datetime2(7), SWITCHOFFSET(@EPCISEventTimeZoneOffset, '+00:00'));

			END
			ELSE
			BEGIN

				select @EPCISEventTime = @CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/eventTime/node())[1]', 'datetime2(7)');
				select @EPCISEventTimeZoneOffset = SWITCHOFFSET(convert(datetimeoffset, @EPCISEventTime), @CurEvent.value('(//eventTimeZoneOffset/node())[1]', 'varchar(6)'));

			END;

			--***************************************************************
			-- EinzelEvent speichern
			--***************************************************************
			SET @RecordTime	= cast(getdate() as datetime2(0));

			insert into #EventData 
				(ClientID, 
				 EventTime, 
				 RecordTime, 
				 EventTimeZoneOffset, 
				 [EPCISRepresentation])
			OUTPUT inserted.EPCISEventID INTO @OutputEPCISEventID
			values (
				@ClientID,
				cast(@EPCISEventTime as datetime2(0)),
				@RecordTime,
				@EPCISEventTimeZoneOffset,
				@CurEvent
				);

			select TOP 1 @EPCISEPCISEventID = ID FROM @OutputEPCISEventID;
			delete from @OutputEPCISEventID;

			--***************************************************************
			-- Zwischentabelle befüllen mit Vokabelnamen und -typen für alle 
			-- unverarbeiteten Events um später die IDs auf einmal bestimmen
			-- zu können
			--***************************************************************

			--***************************************************************
			-- EventTyp auslesen, xmlPath bauen zu können
			--***************************************************************

			select
				@EPCISEventTypePath= cast(@CurEvent.query('local-name((/*)[1])') as nvarchar(128))	

			--***************************************************************
			-- EventVokabel zwischenspeichern
			--***************************************************************
			select
				@VocabularyTypeURN = N'urn:quibiq:epcis:vtype:event',
				@VocabularyURN = N'urn:quibiq:epcis:cbv:event:' + lower(replace(@EPCISEventTypePath, 'Event', ''))

			insert into #EPCISEvent_Vocabulary (VocabularyTypeURN, VocabularyURN, EPCISEventID)
				values (@VocabularyTypeURN, @VocabularyURN, @EPCISEPCISEventID)

			--***************************************************************
			-- EPCList
			--***************************************************************
	
			select
				@EPCList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/epcList/./.');

			insert into #EPCISEvent_EPC (EPCURN, EPCISEventID, IsParentID, IsInput, IsOutput)
			select
				REPLACE(content.nodes.query(N'.').value('(/epc/.)[1]', 'nvarchar(512)'), N' ', N'') as EPCURN,
				@EPCISEPCISEventID,
				0  as IsParent,
				0  as IsInput,
				0  as IsOutput
			from
				@EPCList.nodes(N'/*/*/.') as content(nodes)		

			--***************************************************************
			-- IsParent
			--***************************************************************
	
			select		
				@EPCURN = REPLACE(@CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/parentID/node())[1]', 'nvarchar(512)'), N' ', N'');

			if @EPCURN is not null 
			begin
				insert into #EPCISEvent_EPC (EPCURN, EPCISEventID, IsParentID, IsInput, IsOutput)
					values (@EPCURN, @EPCISEPCISEventID, 1, 0, 0)
			end

			--***************************************************************
			-- IsInput
			--***************************************************************
	
			select
				@EPCList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/inputEPCList/./.');

			insert into #EPCISEvent_EPC (EPCURN, EPCISEventID, IsParentID, IsInput, IsOutput)
			select
				REPLACE(content.nodes.query(N'.').value('(/epc/.)[1]', 'nvarchar(512)'), N' ', N'') as EPCURN,
				@EPCISEPCISEventID,
				0  as IsParent,
				1  as IsInput,
				0  as IsOutput
			from
				@EPCList.nodes(N'/*/*/.') as content(nodes)		


			--***************************************************************
			-- IsOutput
			--***************************************************************
	
			select
				@EPCList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/outputEPCList/./.');

			insert into #EPCISEvent_EPC (EPCURN, EPCISEventID, IsParentID, IsInput, IsOutput)
			select
				REPLACE(content.nodes.query(N'.').value('(/epc/.)[1]', 'nvarchar(512)'), N' ', N'') as EPCURN,
				@EPCISEPCISEventID,
				0  as IsParent,
				0  as IsInput,
				1  as IsOutput
			from
				@EPCList.nodes(N'/*/*/.') as content(nodes)		


			--***************************************************************
			-- childEPCs
			--***************************************************************
	
			select
				@EPCList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/childEPCs/./.');

			insert into #EPCISEvent_EPC (EPCURN, EPCISEventID, IsParentID, IsInput, IsOutput)
			select
				REPLACE(content.nodes.query(N'.').value('(/epc/.)[1]', 'nvarchar(512)'), N' ', N'') as EPCURN,
				@EPCISEPCISEventID,
				0  as IsParent,
				0  as IsInput,
				0  as IsOutput
			from
				@EPCList.nodes(N'/*/*/.') as content(nodes)

			--***************************************************************
			-- bizTransactionList
			--***************************************************************

			select
				@BizTransactionList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/bizTransactionList/./.');

			insert into #EPCISEvent_BusinessTransactionID (BusinessTransactionIDURN, BusinessTransactionTypeURN, VocabularyTypeURN, EPCISEventID)
			select
				REPLACE(content.nodes.query(N'.').value('(/bizTransaction/.)[1]', 'nvarchar(512)'), N' ', N'') as BusinessTransactionIDURN,
				REPLACE(content.nodes.query(N'.').value('(/bizTransaction/@type)[1]', 'nvarchar(512)'), N' ', N'') as BusinessTransactionTypeURN,
				N'urn:epcglobal:epcis:vtype:BusinessTransactionType' as VocabularyTypeURN,
				@EPCISEPCISEventID
			from
				@BizTransactionList.nodes(N'/*/*/.') as content(nodes)	

			--***************************************************************
			-- Action
			--***************************************************************
	
			select 
				@VocabularyTypeURN = N'urn:quibiq:epcis:vtype:action',
				@VocabularyURN = 'urn:quibiq:epcis:cbv:action:' + REPLACE(lower(@CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/action/node())[1]', 'nvarchar(512)')), N' ', N'');

			if @VocabularyURN is not null
			begin
				insert into #EPCISEvent_Vocabulary (VocabularyTypeURN, VocabularyURN, EPCISEventID)
					values (@VocabularyTypeURN, @VocabularyURN, @EPCISEPCISEventID)
			end 

			--***************************************************************
			-- TransformationID EPCIS 1.1
			--***************************************************************
	
			select 
				@CharValue = REPLACE(@CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/transformationID/text())[1]', 'nvarchar(512)'), N' ', N'');

			if @CharValue is not null
			begin
				insert into #EPCISEvent_TransformationID (EPCISEventID, TransformationIDURN)
					values (@EPCISEPCISEventID, @CharValue)
			end 

			--***************************************************************
			-- Quantity EPCIS 1.0
			--***************************************************************
	
			select 
				@ValueTypeTypeURN = N'urn:quibiq:epcis:vtype:valuetype',
				@ValueTypeURN = N'urn:quibiq:epcis:cbv:valuetype:quantity',
				@DataTypeTypeURN = N'urn:quibiq:epcis:vtype:datatype',
				@DataTypeURN = N'urn:quibiq:epcis:cbv:datatype:int',
				@IntValue = @CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/quantity/node())[1]', 'int')

			if @IntValue is not null
			begin
				insert into #EPCISEvent_Value (ValueTypeTypeURN, ValueTypeURN, DataTypeTypeURN, DataTypeURN, IntValue, FloatValue, EPCISEventID, ExtensionType, ParentURN, Depth)
					values (@ValueTypeTypeURN, @ValueTypeURN, @DataTypeTypeURN, @DataTypeURN, @IntValue, @IntValue, @EPCISEPCISEventID, 0, N'', 0)
			end 

			--***************************************************************
			-- Quantity EPCIS 1.1
			--***************************************************************

			IF @EPCISEventTypePath = N'TransformationEvent'
			BEGIN
				SET @IsOutput = 1;
				SELECT @XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/outputQuantityList/./.');
				
				insert into #EPCISEvent_QuantityElement (EPCISEventID, IsInput, IsOutput, EPCClassURN, Quantity, UOM)
				select
					@EPCISEPCISEventID,
					0          as IsInput,
					@IsOutput  as IsOutput,
					REPLACE(content.nodes.query(N'.').value('(/quantityElement/epcClass/text())[1]', 'nvarchar(512)'), N' ', N'') as EPCClassURN,
					ISNULL(REPLACE(content.nodes.query(N'.').value('(/quantityElement/quantity/text())[1]', 'float(53)'), N' ', N''), 0) as Quantity,
					ISNULL(REPLACE(content.nodes.query(N'.').value('(/quantityElement/uom/text())[1]', 'nchar(3)'), N' ', N''), N'') as UOM
				from
					@XmlList.nodes(N'/*/*/.') as content(nodes)		

				select
					@XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/inputQuantityList/./.');


				insert into #EPCISEvent_QuantityElement (EPCISEventID, IsInput, IsOutput, EPCClassURN, Quantity, UOM)
				select
					@EPCISEPCISEventID,
					1  as IsInput,
					0  as IsOutput,
					REPLACE(content.nodes.query(N'.').value('(/quantityElement/epcClass/text())[1]', 'nvarchar(512)'), N' ', N'') as EPCClassURN,
					REPLACE(content.nodes.query(N'.').value('(/quantityElement/quantity/text())[1]', 'float(53)'), N' ', N'') as Quantity,
					ISNULL(REPLACE(content.nodes.query(N'.').value('(/quantityElement/uom/text())[1]', 'nchar(3)'), N' ', N''), N'') as UOM
				from
					@XmlList.nodes(N'/*/*/.') as content(nodes)		

			END
			ELSE
			BEGIN

				IF @EPCISEventTypePath = N'AggregationEvent'
				BEGIN
					SELECT @XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/extension/childQuantityList/./.');

					insert into #EPCISEvent_QuantityElement (EPCISEventID, IsInput, IsOutput, EPCClassURN, Quantity, UOM)
					select
						@EPCISEPCISEventID,
						0          as IsInput,
						0          as IsOutput,
						REPLACE(content.nodes.query(N'.').value('(/quantityElement/epcClass/text())[1]', 'nvarchar(512)'), N' ', N'') as EPCClassURN,
						ISNULL(REPLACE(content.nodes.query(N'.').value('(/quantityElement/quantity/text())[1]', 'float(53)'), N' ', N''), 0) as Quantity,
						ISNULL(REPLACE(content.nodes.query(N'.').value('(/quantityElement/uom/text())[1]', 'nchar(3)'), N' ', N''), N'') as UOM
					from
						@XmlList.nodes(N'/*/*/.') as content(nodes)		

				END
				BEGIN
					SELECT @XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/extension/quantityList/./.');

					insert into #EPCISEvent_QuantityElement (EPCISEventID, IsInput, IsOutput, EPCClassURN, Quantity, UOM)
					select
						@EPCISEPCISEventID,
						0          as IsInput,
						0          as IsOutput,
						REPLACE(content.nodes.query(N'.').value('(/quantityElement/epcClass/text())[1]', 'nvarchar(512)'), N' ', N'') as EPCClassURN,
						ISNULL(REPLACE(content.nodes.query(N'.').value('(/quantityElement/quantity/text())[1]', 'float(53)'), N' ', N''), 0) as Quantity,
						ISNULL(REPLACE(content.nodes.query(N'.').value('(/quantityElement/uom/text())[1]', 'nchar(3)'), N' ', N''), N'') as UOM
					from
						@XmlList.nodes(N'/*/*/.') as content(nodes)		

				END;
			END;

			--***************************************************************
			-- SourceDestination
			--***************************************************************

			IF @EPCISEventTypePath = N'TransformationEvent'
			BEGIN
				SELECT @XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/sourceList/./.');
			END
			ELSE
			BEGIN
				SELECT @XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/extension/sourceList/./.');
			END;

			insert into #EPCISEvent_SourceDestination (EPCISEventID, IsSource, SourceDestinationURN, SourceDestinationTypeURN)
			select
				@EPCISEPCISEventID,
				1  as IsSource,
				REPLACE(content.nodes.query(N'.').value('(/source/text())[1]', 'nvarchar(512)'), N' ', N'') as SourceDestinationURN,
				REPLACE(content.nodes.query(N'.').value('(/source/@type)[1]', 'nvarchar(512)'), N' ', N'') as SourceDestinationTypeURN
			from
				@XmlList.nodes(N'/*/*/.') as content(nodes)		

	
			IF @EPCISEventTypePath = N'TransformationEvent'
			BEGIN
				SELECT @XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/destinationList/./.');
			END
			ELSE
			BEGIN
				SELECT @XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/extension/destinationList/./.');
			END;

			insert into #EPCISEvent_SourceDestination (EPCISEventID, IsSource, SourceDestinationURN, SourceDestinationTypeURN)
			select
				@EPCISEPCISEventID,
				0  as IsSource,
				REPLACE(content.nodes.query(N'.').value('(/destination/text())[1]', 'nvarchar(512)'), N' ', N'') as SourceDestinationURN,
				REPLACE(content.nodes.query(N'.').value('(/destination/@type)[1]', 'nvarchar(512)'), N' ', N'') as SourceDestinationTypeURN
			from
				@XmlList.nodes(N'/*/*/.') as content(nodes)	
				

			--***************************************************************
			-- baseExtension Fields(eventID, errorDeclarationTime, correctiveEventId, reason) 1.2
			--***************************************************************

			--***************************************************************
			-- errorDecalration extension fields
			--***************************************************************
			SELECT @XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/baseExtension/errorDeclaration/./.');
			;with extensions as(
				select 
					N'urn:quibiq:epcis:vtype:errordeclaration'																							as [ValueTypeTypeURN]
					,N'urn:quibiq:epcis:vtype:datatype'																						as [DataTypeTypeURN]
					-- Generisch erstellt namespace#root
					,content.nodes.value('fn:concat(namespace-uri(.),"#",local-name(.))','nvarchar(max)')	as [ValueTypeURN]

					-- CONTENT
					,content.nodes.value('./text()[1]','nvarchar(max)')																		as [StringValue]
					,TRY_CONVERT(bigint,content.nodes.value('./text()[1]','nvarchar(max)'))													as [IntValue]
					,TRY_CONVERT(datetimeoffset,content.nodes.value('./text()[1]','nvarchar(max)'))												as [TimeValue]
					,TRY_CONVERT(float,content.nodes.value('./text()[1]','nvarchar(max)'))													as [FloatValue]
					-- HIERARCHY
					,CAST(N'' as nvarchar(max))																								as [ParentURN]
					,0																														as [Depth]
					,content.nodes.query('./node()')																							as [Content]
				from
					@XmlList.nodes(N'/*/*[namespace-uri() != '''' and namespace-uri() != ''urn:epcglobal:epcis:xsd:1'']') as content(nodes)		
			UNION ALL
				select
					N'urn:quibiq:epcis:vtype:errordeclaration'																							as [ValueTypeTypeURN]			  
					,N'urn:quibiq:epcis:vtype:datatype'																						as [DataTypeTypeURN]
					-- Generisch erstellt urn:quibiq:epcis:cbv:valuetype:namespace#root
					,con.nodes.value('fn:concat(namespace-uri(.),"#",local-name(.))','nvarchar(max)')		as [ValueTypeURN]

					-- CONTENT
					,con.nodes.value('./text()[1]','nvarchar(max)')																			as [StringValue]
					,TRY_CONVERT(bigint,con.nodes.value('./text()[1]','nvarchar(max)'))														as [IntValue]
					,TRY_CONVERT(datetimeoffset,con.nodes.value('./text()[1]','nvarchar(max)'))													as [TimeValue]
					,TRY_CONVERT(float,con.nodes.value('./text()[1]','nvarchar(max)'))														as [FloatValue]
					-- HIERARCHY
					,[ValueTypeURN]																											as [ParentURN]
					,[Depth]+1																												as [Depth]
					,con.nodes.query('./node()')																								as [Content]
				from extensions
					cross apply Content.nodes(N'/*') as con(nodes)
			)
				insert into #EPCISEvent_Value 
					(  EPCISEventID
						, ValueTypeTypeURN
						, ValueTypeURN
						, DataTypeTypeURN
						, DataTypeURN
						, IntValue
						, FloatValue		
						, TimeValue			
						, StringValue 
						, ParentURN
						, Depth
						, ExtensionType)		
				select 
						@EPCISEPCISEventID as EPCISEventID
						, ValueTypeTypeURN
						, ValueTypeURN
						, DataTypeTypeURN
						, [Import].[svf_get_DataTypeURN](IntValue, FloatValue, TimeValue, StringValue) as DataTypeURN
						, IntValue
						, FloatValue		
						, TimeValue			
						, StringValue 	
						, ParentURN
						, Depth 	
						, 1 as ExtensionType
				from extensions;

				--***************************************************************
				-- eventID
				--***************************************************************
				DECLARE @EventId NVARCHAR(128);
				SELECT @EventId = @CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/baseExtension/eventID/node())[1]', 'nvarchar(50)')
				IF @EventId IS NOT NULL
				BEGIN
					select 
					@ValueTypeTypeURN = N'urn:quibiq:epcis:vtype:baseextension',
					@ValueTypeURN = N'urn:quibiq:epcis:cbv:valuetype:eventid',
					@DataTypeTypeURN = N'urn:quibiq:epcis:vtype:datatype',
					@DataTypeURN = N'urn:quibiq:epcis:cbv:datatype:string';

					insert into #EPCISEvent_Value (ValueTypeTypeURN, ValueTypeURN, DataTypeTypeURN, DataTypeURN, StringValue, EPCISEventID, ExtensionType, ParentURN, Depth)
						values (@ValueTypeTypeURN, @ValueTypeURN, @DataTypeTypeURN, @DataTypeURN, @EventId, @EPCISEPCISEventID, 0, N'', 0)
					--INSERT eventID
				END
            
				--***************************************************************
				-- errorDeclaration
				--***************************************************************
				if @CurEvent.exist(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/baseExtension/errorDeclaration/.') = 1
				BEGIN
					DECLARE @DeclarationTime DATETIME2(2),
							@Reason NVARCHAR(128);
					SELECT @DeclarationTime = @CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/baseExtension/errorDeclaration/declarationTime/node())[1]', 'nvarchar(50)')
					--INSERT declarationtime
					select 
					@ValueTypeTypeURN = N'urn:quibiq:epcis:vtype:baseextension',
					@ValueTypeURN = N'urn:quibiq:epcis:cbv:valuetype:declarationtime',
					@DataTypeTypeURN = N'urn:quibiq:epcis:vtype:datatype',
					@DataTypeURN = N'urn:quibiq:epcis:cbv:datatype:time';

					insert into #EPCISEvent_Value (ValueTypeTypeURN, ValueTypeURN, DataTypeTypeURN, DataTypeURN, TimeValue, EPCISEventID, ExtensionType, ParentURN, Depth)
						values (@ValueTypeTypeURN, @ValueTypeURN, @DataTypeTypeURN, @DataTypeURN, @DeclarationTime, @EPCISEPCISEventID, 0, N'', 0);

					SELECT @Reason = @CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/baseExtension/errorDeclaration/reason/node())[1]', 'nvarchar(50)')
					IF @Reason IS NOT NULL
					BEGIN
						select 
						@ValueTypeTypeURN = N'urn:quibiq:epcis:vtype:baseextension',
						@ValueTypeURN = N'urn:quibiq:epcis:cbv:valuetype:reason',
						@DataTypeTypeURN = N'urn:quibiq:epcis:vtype:datatype',
						@DataTypeURN = N'urn:quibiq:epcis:cbv:datatype:string';

						insert into #EPCISEvent_Value (ValueTypeTypeURN, ValueTypeURN, DataTypeTypeURN, DataTypeURN, StringValue, EPCISEventID, ExtensionType, ParentURN, Depth)
							values (@ValueTypeTypeURN, @ValueTypeURN, @DataTypeTypeURN, @DataTypeURN, @Reason, @EPCISEPCISEventID, 0, N'', 0)
					--INSERT Reason
					END
					if @CurEvent.exist(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/baseExtension/errorDeclaration/correctiveEventIDs') = 1
					BEGIN
						DECLARE @CorretiveEventIds XML;
						select 
							@ValueTypeTypeURN = N'urn:quibiq:epcis:vtype:baseextension',
							@ValueTypeURN = N'urn:quibiq:epcis:cbv:valuetype:correctiveeventid',
							@DataTypeTypeURN = N'urn:quibiq:epcis:vtype:datatype',
							@DataTypeURN = N'urn:quibiq:epcis:cbv:datatype:string';
						--INSERT INTO
						select @CorretiveEventIds = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/baseExtension/errorDeclaration/correctiveEventIDs/./.')
						insert into #EPCISEvent_Value (ValueTypeTypeURN, ValueTypeURN, DataTypeTypeURN, DataTypeURN, StringValue, EPCISEventID, ExtensionType, ParentURN, Depth)
						SELECT
							@ValueTypeTypeURN,
							@ValueTypeURN,
							@DataTypeTypeURN,
							@DataTypeURN,
							REPLACE(content.nodes.query(N'.').value('(/correctiveEventID/.)[1]', 'nvarchar(512)'), N' ', N'') as correctiveEventIds,
							@EPCISEPCISEventID,
							0,
							N'',
							0
						from
							@CorretiveEventIds.nodes(N'/*/*/.') as content(nodes)
                    END
                    
                END
                
			--***************************************************************
			-- ILMD Extension Fields
			--***************************************************************

			IF @EPCISEventTypePath = N'TransformationEvent'
			BEGIN
				SELECT @XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/ilmd/./.');
			END
			ELSE
			BEGIN
				SELECT @XmlList = @CurEvent.query(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/extension/ilmd/./.');
			END;

			;with extensions as(
					select 
					   N'urn:quibiq:epcis:vtype:ilmd'																							as [ValueTypeTypeURN]
					  ,N'urn:quibiq:epcis:vtype:datatype'																						as [DataTypeTypeURN]
					  -- Generisch erstellt namespace#root
					  ,content.nodes.value('fn:concat(namespace-uri(.),"#",local-name(.))','nvarchar(max)')	as [ValueTypeURN]

					  -- CONTENT
					  ,content.nodes.value('./text()[1]','nvarchar(max)')																		as [StringValue]
					  ,TRY_CONVERT(bigint,content.nodes.value('./text()[1]','nvarchar(max)'))													as [IntValue]
					  ,TRY_CONVERT(datetimeoffset,content.nodes.value('./text()[1]','nvarchar(max)'))												as [TimeValue]
					  ,TRY_CONVERT(float,content.nodes.value('./text()[1]','nvarchar(max)'))													as [FloatValue]
					  -- HIERARCHY
					  ,CAST(N'' as nvarchar(max))																								as [ParentURN]
					  ,0																														as [Depth]
					  ,content.nodes.query('./node()')																							as [Content]
					from
						@XmlList.nodes(N'/ilmd/*[namespace-uri() != '''' and namespace-uri() != ''urn:epcglobal:epcis:xsd:1'']') as content(nodes)		
				UNION ALL
					select
					   N'urn:quibiq:epcis:vtype:ilmd'																							as [ValueTypeTypeURN]			  
					  ,N'urn:quibiq:epcis:vtype:datatype'																						as [DataTypeTypeURN]
					  -- Generisch erstellt urn:quibiq:epcis:cbv:valuetype:namespace#root
					  ,con.nodes.value('fn:concat(namespace-uri(.),"#",local-name(.))','nvarchar(max)')		as [ValueTypeURN]

					  -- CONTENT
					  ,con.nodes.value('./text()[1]','nvarchar(max)')																			as [StringValue]
					  ,TRY_CONVERT(bigint,con.nodes.value('./text()[1]','nvarchar(max)'))														as [IntValue]
					  ,TRY_CONVERT(datetimeoffset,con.nodes.value('./text()[1]','nvarchar(max)'))													as [TimeValue]
					  ,TRY_CONVERT(float,con.nodes.value('./text()[1]','nvarchar(max)'))														as [FloatValue]
					  -- HIERARCHY
					  ,[ValueTypeURN]																											as [ParentURN]
					  ,[Depth]+1																												as [Depth]
					  ,con.nodes.query('./node()')																								as [Content]
					from extensions
						cross apply Content.nodes(N'/*') as con(nodes)
				)
				insert into #EPCISEvent_Value 
					(  EPCISEventID
					 , ValueTypeTypeURN
					 , ValueTypeURN
					 , DataTypeTypeURN
					 , DataTypeURN
					 , IntValue
					 , FloatValue		
					 , TimeValue			
					 , StringValue 
					 , ParentURN
					 , Depth
					 , ExtensionType)		
				select 
					  @EPCISEPCISEventID as EPCISEventID
					 , ValueTypeTypeURN
					 , ValueTypeURN
					 , DataTypeTypeURN
					 , [Import].[svf_get_DataTypeURN](IntValue, FloatValue, TimeValue, StringValue) as DataTypeURN
					 , IntValue
					 , FloatValue		
					 , TimeValue			
					 , StringValue 	
					 , ParentURN
					 , Depth 	
					 , 1 as ExtensionType
				from extensions;

			--***************************************************************
			-- Customer Extension Fields
			--***************************************************************
	
			;with extensions2 as(
					select 
					   N'urn:quibiq:epcis:vtype:extensiontype'																					as [ValueTypeTypeURN]
					  ,N'urn:quibiq:epcis:vtype:datatype'																						as [DataTypeTypeURN]
					  -- Generisch erstellt namespace#root
					  ,content.nodes.value('fn:concat(namespace-uri(.),"#",local-name(.))','nvarchar(max)')	as [ValueTypeURN]

					  -- CONTENT
					  ,content.nodes.value('./text()[1]','nvarchar(max)')																		as [StringValue]
					  ,TRY_CONVERT(bigint,content.nodes.value('./text()[1]','nvarchar(max)'))													as [IntValue]
					  ,TRY_CONVERT(datetimeoffset,content.nodes.value('./text()[1]','nvarchar(max)'))												as [TimeValue]
					  ,TRY_CONVERT(float,content.nodes.value('./text()[1]','nvarchar(max)'))													as [FloatValue]
					  -- HIERARCHY
					  ,CAST(N'' as nvarchar(max))																								as [ParentURN]
					  ,0																														as [Depth]
					  ,content.nodes.query('./node()')																							as [Content]
					from
						@CurEvent.nodes(N'/*[local-name()= sql:variable("@EPCISEventTypePath")]/*[namespace-uri() != '''' and namespace-uri() != ''urn:epcglobal:epcis:xsd:1'']') as content(nodes)		
				UNION ALL
					select
					   N'urn:quibiq:epcis:vtype:extensiontype'																					as [ValueTypeTypeURN]
					  ,N'urn:quibiq:epcis:vtype:datatype'																						as [DataTypeTypeURN]
					  -- Generisch erstellt urn:quibiq:epcis:cbv:valuetype:namespace#root
					  ,con.nodes.value('fn:concat(namespace-uri(.),"#",local-name(.))','nvarchar(max)')		as [ValueTypeURN]

					  -- CONTENT
					  ,con.nodes.value('./text()[1]','nvarchar(max)')																			as [StringValue]
					  ,TRY_CONVERT(bigint,con.nodes.value('./text()[1]','nvarchar(max)'))														as [IntValue]
					  ,TRY_CONVERT(datetimeoffset,con.nodes.value('./text()[1]','nvarchar(max)'))													as [TimeValue]
					  ,TRY_CONVERT(float,con.nodes.value('./text()[1]','nvarchar(max)'))														as [FloatValue]
					  -- HIERARCHY
					  ,[ValueTypeURN]																											as [ParentURN]
					  ,[Depth]+1																												as [Depth]
					  ,con.nodes.query('./node()')																								as [Content]
					from extensions2
						cross apply Content.nodes(N'/*') as con(nodes)
				)
				insert into #EPCISEvent_Value 
					(  EPCISEventID
					 , ValueTypeTypeURN
					 , ValueTypeURN
					 , DataTypeTypeURN
					 , DataTypeURN
					 , IntValue
					 , FloatValue		
					 , TimeValue			
					 , StringValue 
					 , ParentURN
					 , Depth
					 , ExtensionType)		
				select 
					  @EPCISEPCISEventID as EPCISEventID
					 , ValueTypeTypeURN
					 , ValueTypeURN
					 , DataTypeTypeURN
					 , [Import].[svf_get_DataTypeURN](IntValue, FloatValue, TimeValue, StringValue) as DataTypeURN
					 , IntValue
					 , FloatValue		
					 , TimeValue			
					 , StringValue 	
					 , ParentURN
					 , Depth 	
					 , 1 as ExtensionType
				from extensions2;

			 
			    insert into #EPCISEvent_ExtenstionType (EPCISEventID, ExtensionTypeURN, ExtensionTypeTypeURN)
				select 
					 @EPCISEPCISEventID as EPCISEventID
					,ValueTypeURN  as ExtensionTypeURN
					,ValueTypeTypeURN as ExtensionTypeTypeURN
				from #EPCISEvent_Value where ExtensionType = 1
				group by ValueTypeURN, ValueTypeTypeURN

			--***************************************************************
			-- EPCClass
			--***************************************************************
	
			select 
				@VocabularyTypeURN = N'urn:epcglobal:epcis:vtype:EPCClass',
				@VocabularyURN = REPLACE(lower(@CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/epcClass/node())[1]', 'nvarchar(512)')), N' ', N'');

			if @VocabularyURN is not null
			begin
				insert into #EPCISEvent_Vocabulary (VocabularyTypeURN, VocabularyURN, EPCISEventID)
					values (@VocabularyTypeURN, @VocabularyURN, @EPCISEPCISEventID)
			end 

			--***************************************************************
			-- Bizstep
			--***************************************************************

			select 
				@VocabularyTypeURN = N'urn:epcglobal:epcis:vtype:BusinessStep',
				@VocabularyURN = REPLACE(@CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/bizStep/node())[1]', 'nvarchar(512)'), N' ', N'');

			if @VocabularyURN is not null
			begin
				insert into #EPCISEvent_Vocabulary (VocabularyTypeURN, VocabularyURN, EPCISEventID)
					values (@VocabularyTypeURN, @VocabularyURN, @EPCISEPCISEventID)
			end

			--***************************************************************
			-- Disposition
			--***************************************************************

			select 
				@VocabularyTypeURN = N'urn:epcglobal:epcis:vtype:Disposition',
				@VocabularyURN = REPLACE(@CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/disposition/node())[1]', 'nvarchar(512)'), N' ', N'');

			if @VocabularyURN is not null
			begin
				insert into #EPCISEvent_Vocabulary (VocabularyTypeURN, VocabularyURN, EPCISEventID)
					values (@VocabularyTypeURN, @VocabularyURN, @EPCISEPCISEventID)
			end

			--***************************************************************
			-- Readpoint
			--***************************************************************

			select 
				@VocabularyTypeURN = N'urn:epcglobal:epcis:vtype:Readpoint',
				@VocabularyURN = REPLACE(@CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/readPoint/id/node())[1]', 'nvarchar(512)'), N' ', N'');

			if @VocabularyURN is not null
			begin
				insert into #EPCISEvent_Vocabulary (VocabularyTypeURN, VocabularyURN, EPCISEventID)
					values (@VocabularyTypeURN, @VocabularyURN, @EPCISEPCISEventID)	
			end

			--***************************************************************
			-- bizLocation
			--***************************************************************

			select 
				@VocabularyTypeURN = N'urn:epcglobal:epcis:vtype:BusinessLocation',
				@VocabularyURN = REPLACE(@CurEvent.value('(/*[local-name()= sql:variable("@EPCISEventTypePath")]/bizLocation/id/node())[1]', 'nvarchar(512)'), N' ', N'');

			if @VocabularyURN is not null
			begin
				insert into #EPCISEvent_Vocabulary (VocabularyTypeURN, VocabularyURN, EPCISEventID)
					values (@VocabularyTypeURN, @VocabularyURN, @EPCISEPCISEventID)
			end

			fetch next from curEvent into @curEvent;
		end

		close curEvent
		deallocate curEvent;


		--***************************************************************
		-- Prüfung auf vorhandene VocabularyTypes
		--***************************************************************

		merge into #EPCISEvent_Vocabulary as target
		using (select 
		        vt.[ID],
				vt.URN,
				vtc.Deleted
			   from Vocabulary.[VocabularyType] vt 
			   join Vocabulary.[VocabularyType_Client] vtc on vtc.[VocabularyTypeID] = vt.[ID]
			    and (vtc.ClientID = @ClientID or vtc.ClientID = @SystemClientID)
		) as source	
		on target.VocabularyTypeURN = source.URN and source.Deleted = 0
		when matched then
			update set VocabularyTypeID = source.[ID];

		-- Falls Vokabeltyp nicht vorhanden, dann werden die betroffenen Events mit Begründung markiert
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  EPCISEventID
			,  N'Vokabeltyp für '''+ VocabularyURN +''' nicht in Stammdaten (oder logisch geloescht). Fehlender Typ: ''' + VocabularyTypeURN + ''''	
		FROM #EPCISEvent_Vocabulary where VocabularyTypeID is null;
		
		--***************************************************************
		-- Prüfung auf vorhandenes Vocabulary
		--***************************************************************

		-- Nur BizLocation und ReadPoints hinzufügen
		if @AddBizLocAndReadPoints = 1 and @AddNewVocabulary = 0
		begin
			merge into Vocabulary.[Vocabulary] WITH (HOLDLOCK) as target
			using (select distinct VocabularyURN, VocabularyTypeID from #EPCISEvent_Vocabulary 
				  where VocabularyTypeURN = N'urn:epcglobal:epcis:vtype:BusinessLocation' or VocabularyTypeURN = N'urn:epcglobal:epcis:vtype:ReadPoint'
				  ) as source
			on target.URN = source.VocabularyURN and target.[VocabularyTypeID] = source.VocabularyTypeID and target.ClientID = @ClientID		
			when matched then
				update set Deleted = 0
			when not matched by target then
				insert (URN, [VocabularyTypeID], ClientID)
					values (source.VocabularyURN, source.VocabularyTypeID, @ClientID);
	
		end

		-- Nur EPCClass hinzufügen
		DECLARE @EPCISClassTypeID BIGINT;
		select @EPCISClassTypeID = ID from Vocabulary.VocabularyType vt
						join Vocabulary.VocabularyType_Client vtc on vtc.VocabularyTypeID = vt.ID
		where URN = N'urn:epcglobal:epcis:vtype:EPCClass' and ClientID = @ClientID and Deleted = 0;

		if @AddEPCClass = 1 or @AddNewVocabulary = 1
		begin
			merge into Vocabulary.[Vocabulary] WITH (HOLDLOCK) as target
			using (select distinct EPCClassURN as VocabularyURN, @EPCISClassTypeID as [VocabularyTypeID] from #EPCISEvent_QuantityElement) as source
			on target.URN = source.VocabularyURN and target.[VocabularyTypeID] = source.VocabularyTypeID and target.ClientID = @ClientID		
			when matched then
				update set Deleted = 0
			when not matched by target then
				insert (URN, [VocabularyTypeID], ClientID)
					values (source.VocabularyURN, source.VocabularyTypeID, @ClientID);	
		end

		-- SourceDestination hinzufügen
		if @AddSourceDestination = 1 or @AddNewVocabulary = 1
		begin
			DECLARE @ID BIGINT;
			
			select @ID = ID from Vocabulary.VocabularyType vt
						join Vocabulary.VocabularyType_Client vtc on vtc.VocabularyTypeID = vt.ID
			where URN = N'urn:epcglobal:epcis:vtype:SourceDest' and ClientID = @ClientID and Deleted = 0;

			merge into Vocabulary.[Vocabulary] WITH (HOLDLOCK) as target
			using (select distinct SourceDestinationURN from #EPCISEvent_SourceDestination 
				  ) as source
			on target.URN = source.SourceDestinationURN and target.[VocabularyTypeID] = @ID and target.ClientID = @ClientID		
			when matched then
				update set Deleted = 0
			when not matched by target then
				insert (URN, [VocabularyTypeID], ClientID)
					values (source.SourceDestinationURN, @ID, @ClientID);	
		end

		-- Alle Vokabeln hinzfügen
		if @AddNewVocabulary = 1 
		begin
			merge into Vocabulary.[Vocabulary] WITH (HOLDLOCK) as target
			using (select distinct VocabularyURN, VocabularyTypeID from #EPCISEvent_Vocabulary) as source
			on target.URN = source.VocabularyURN and target.[VocabularyTypeID] = source.VocabularyTypeID and target.ClientID = @ClientID		
			when matched then
				update set Deleted = 0
			when not matched by target then
				insert (URN, [VocabularyTypeID], ClientID)
					values (source.VocabularyURN, source.VocabularyTypeID, @ClientID);
		end

		-- Systemvokablen (Systemmandant) ergänzen
		update 
			#EPCISEvent_Vocabulary
		set ID = v.[ID]
		from #EPCISEvent_Vocabulary ev
		join Vocabulary.[Vocabulary] v on v.URN = ev.VocabularyURN and v.[VocabularyTypeID] = ev.VocabularyTypeID and v.ClientID = @SystemClientID and v.Deleted = 0;

		-- Mandantenvokabeln ergänzen
		update 
			#EPCISEvent_Vocabulary
		set ID = v.[ID]
		from #EPCISEvent_Vocabulary ev
		join Vocabulary.[Vocabulary] v on v.URN = ev.VocabularyURN and v.[VocabularyTypeID] = ev.VocabularyTypeID and v.ClientID = @ClientID and v.Deleted = 0;

		-- Describe Error
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  EPCISEventID
			,  N'Vokabel '''+ VocabularyURN +''' nicht in Stammdaten gepflegt (oder logisch geloescht).'													
		FROM #EPCISEvent_Vocabulary where ID is null;
	
		--***************************************************************
		-- EventBusinessTransaction: IDs zu den gesammelten URN bestimmen
		--***************************************************************

		if @AddNewVocabulary = 1 
		begin
			merge into Vocabulary.[Vocabulary] WITH (HOLDLOCK) as target
			using (select distinct BusinessTransactionTypeURN, VocabularyTypeID from #EPCISEvent_BusinessTransactionID) as source
			on target.URN = source.BusinessTransactionTypeURN and target.[VocabularyTypeID] = source.VocabularyTypeID and target.ClientID = @ClientID	
			when matched then
				update set Deleted = 0
			when not matched by target then
				insert (URN, [VocabularyTypeID], ClientID)
					values (source.BusinessTransactionTypeURN, source.VocabularyTypeID, @ClientID);

			merge into #EPCISEvent_BusinessTransactionID as target
			using Vocabulary.[Vocabulary] as source
			on target.VocabularyTypeID = source.[VocabularyTypeID] and target.BusinessTransactionTypeURN = source.URN and source.ClientID = @ClientID	
			when matched then
				update set BusinessTransactionTypeID = source.[ID];
		end

		merge into #EPCISEvent_BusinessTransactionID as target
		using (select 
		        vt.[ID],
				vt.URN,
				vtc.Deleted
			   from Vocabulary.[VocabularyType] vt 
			   join Vocabulary.[VocabularyType_Client] vtc on vtc.[VocabularyTypeID] = vt.[ID] and vtc.ClientID = @ClientID
		) as source	
		on target.VocabularyTypeURN = source.URN and source.Deleted = 0
		when matched then 
			update set VocabularyTypeID = source.[ID];

		merge into #EPCISEvent_BusinessTransactionID as target
		using Vocabulary.[Vocabulary] as source
		on target.VocabularyTypeID = source.[VocabularyTypeID] and target.BusinessTransactionTypeURN = source.URN and source.ClientID = @ClientID	and source.Deleted = 0
		when matched then
			update set BusinessTransactionTypeID = source.[ID];
		
		-- Describe Error
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  EPCISEventID
			, N'''' + BusinessTransactionTypeURN + ''' unbekannter BusinessTransactionsTyp (oder logisch geloescht).'								
		FROM #EPCISEvent_BusinessTransactionID where BusinessTransactionTypeID is null;



		--***************************************************************
		-- QuantityElement
		--***************************************************************
		
		merge into #EPCISEvent_QuantityElement as target
		using Vocabulary.[Vocabulary] as source
		on @EPCISClassTypeID = source.[VocabularyTypeID] and target.EPCClassURN = source.URN and source.ClientID = @ClientID	and source.Deleted = 0
		when matched then
			update set EPCClassID = source.[ID];
				

		-- Describe Error
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  EPCISEventID
			, N'''' + EPCClassURN + ''' unbekannte EPCClass (oder logisch geloescht).'								
		FROM #EPCISEvent_QuantityElement where EPCClassID is null;

		--***************************************************************
		-- SourceDestination
		--***************************************************************
		select @ID = ID from Vocabulary.VocabularyType vt
						join Vocabulary.VocabularyType_Client vtc on vtc.VocabularyTypeID = vt.ID
		where URN = N'urn:epcglobal:epcis:vtype:SourceDest' and ClientID = @ClientID and Deleted = 0;
	    
		merge into #EPCISEvent_SourceDestination as target
		using Vocabulary.[Vocabulary] as source
		on @ID = source.[VocabularyTypeID] and target.SourceDestinationURN = source.URN and source.ClientID = @ClientID	and source.Deleted = 0
		when matched then
			update set SourceDestinationID = source.[ID];
		
		select @ID = ID from Vocabulary.VocabularyType vt
						join Vocabulary.VocabularyType_Client vtc on vtc.VocabularyTypeID = vt.ID
		where URN = N'urn:epcglobal:epcis:vtype:SourceDestType' and ClientID = @ClientID and Deleted = 0;

		merge into #EPCISEvent_SourceDestination as target
		using Vocabulary.[Vocabulary] as source
		on @ID = source.[VocabularyTypeID] and target.SourceDestinationTypeURN = source.URN and source.ClientID = @ClientID and source.Deleted = 0
		when matched then
			update set SourceDestinationTypeID = source.[ID];

		-- Describe Error
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  EPCISEventID
			, N'''' + SourceDestinationURN + ''' unbekannte SourceDest (oder logisch geloescht).'								
		FROM #EPCISEvent_SourceDestination where SourceDestinationID is null
		group by EPCISEventID, SourceDestinationURN;

		-- Describe Error
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  EPCISEventID
			, N'''' + SourceDestinationTypeURN + ''' unbekannter SourceDest Typ (oder logisch geloescht).'								
		FROM #EPCISEvent_SourceDestination where SourceDestinationTypeID is null
		group by EPCISEventID, SourceDestinationTypeURN;

		--***************************************************************
		-- Inhaltliche Prüfungen
		--***************************************************************

		-- Prüfung EPC Struktur entweder URI (schema:path) oder EPC Pure Identity urn:epc:id:... 
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  EPCISEventID
			, N'EPC URI ''' + EPCURN + ''' is not valid'
		FROM #EPCISEvent_EPC
		WHERE [Helper].svf_check_EPC_Code(EPCURN) = 0;

		-- Prüfung Aggregation ADD und DELETE benoetigen ParentID
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  ed.EPCISEventID
			, N'Aggregation-Event mit Action:''' + UPPER(SUBSTRING(ev.VocabularyURN, 29, LEN(ev.VocabularyURN)-28)) + ''' parentID fehlt'
		FROM #EventData ed
		JOIN #EPCISEvent_Vocabulary ev   on ed.EPCISEventID = ev.EPCISEventID
		JOIN #EPCISEvent_Vocabulary ev2  on ed.EPCISEventID = ev2.EPCISEventID
		WHERE 
			ev.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:action' and (ev.VocabularyURN = N'urn:quibiq:epcis:cbv:action:add' or ev.VocabularyURN = N'urn:quibiq:epcis:cbv:action:delete')
		and ev2.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:event' and (ev2.VocabularyURN = N'urn:quibiq:epcis:cbv:event:aggregation')
		and not exists (select TOP 1 1 FROM #EPCISEvent_EPC where EPCISEventID = ed.EPCISEventID and IsParentID = 1)
		group by ed.EPCISEventID, ev.VocabularyURN;

		-- Prüfung ObjectEvent epcList oder qunatityList oder beides
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  ed.EPCISEventID
			, N'Object-Event ohne epcList oder quantityList'
		FROM #EventData ed
		JOIN #EPCISEvent_Vocabulary ev			  on ed.EPCISEventID = ev.EPCISEventID
		LEFT JOIN #EPCISEvent_EPC   ec			  on ed.EPCISEventID = ec.EPCISEventID
		LEFT JOIN #EPCISEvent_QuantityElement qe   on ed.EPCISEventID = qe.EPCISEventID
		WHERE 
			ec.EPCURN is null and qe.EPCClassURN is null
		and ev.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:event' and (ev.VocabularyURN = N'urn:quibiq:epcis:cbv:event:object')
		group by ed.EPCISEventID;

		-- Prüfung ObjectEvent != ADD kein ILMD
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  ed.EPCISEventID
			, N'Object-Event mit Action:''' + UPPER(SUBSTRING(ev.VocabularyURN, 29, LEN(ev.VocabularyURN)-28)) + ''' darf kein ILMD besitzen'
		FROM #EventData ed
		JOIN #EPCISEvent_Vocabulary ev   on ed.EPCISEventID = ev.EPCISEventID
		JOIN #EPCISEvent_Vocabulary ev3  on ed.EPCISEventID = ev3.EPCISEventID
		JOIN #EPCISEvent_Value      ev2  on ed.EPCISEventID = ev2.EPCISEventID
		WHERE 
			ev.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:action' and (ev.VocabularyURN = N'urn:quibiq:epcis:cbv:action:observe' or ev.VocabularyURN = N'urn:quibiq:epcis:cbv:action:delete')
		and ev2.[ValueTypeTypeURN] = N'urn:quibiq:epcis:vtype:ilmd'
		and ev3.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:event' and (ev3.VocabularyURN = N'urn:quibiq:epcis:cbv:event:object')
		group by ed.EPCISEventID, ev.VocabularyURN;

		-- Prüfung AggregationEvent != DELETE childEpcList oder qunatityList oder beides
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  ed.EPCISEventID
			, N'Aggregation-Event mit Action:''' + UPPER(SUBSTRING(ev.VocabularyURN, 29, LEN(ev.VocabularyURN)-28)) + ''' ohne childEpcList oder childQuantityList'
		FROM #EventData ed
		JOIN #EPCISEvent_Vocabulary ev   on ed.EPCISEventID = ev.EPCISEventID
		JOIN #EPCISEvent_Vocabulary ev3  on ed.EPCISEventID = ev3.EPCISEventID
		LEFT JOIN #EPCISEvent_EPC   ec			  on ed.EPCISEventID = ec.EPCISEventID
		LEFT JOIN #EPCISEvent_QuantityElement qe   on ed.EPCISEventID = qe.EPCISEventID
		WHERE 
			ev.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:action' and (ev.VocabularyURN = N'urn:quibiq:epcis:cbv:action:observe' or ev.VocabularyURN = N'urn:quibiq:epcis:cbv:action:add')
		and ec.EPCURN is null 
		and qe.EPCClassURN is null
		and ev3.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:event' and (ev3.VocabularyURN = N'urn:quibiq:epcis:cbv:event:aggregation')
		group by ed.EPCISEventID, ev.VocabularyURN;

		-- Prüfung TransactionEvent != DELETE childEpcList oder qunatityList oder beides
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  ed.EPCISEventID
			, N'Transaction-Event mit Action:''' + UPPER(SUBSTRING(ev.VocabularyURN, 29, LEN(ev.VocabularyURN)-28)) + ''' ohne childEpcList oder childQuantityList'
		FROM #EventData ed
		JOIN #EPCISEvent_Vocabulary ev   on ed.EPCISEventID = ev.EPCISEventID
		JOIN #EPCISEvent_Vocabulary ev3  on ed.EPCISEventID = ev3.EPCISEventID
		LEFT JOIN #EPCISEvent_EPC   ec			  on ed.EPCISEventID = ec.EPCISEventID
		LEFT JOIN #EPCISEvent_QuantityElement qe   on ed.EPCISEventID = qe.EPCISEventID
		WHERE 
			ev.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:action' and (ev.VocabularyURN = N'urn:quibiq:epcis:cbv:action:observe' or ev.VocabularyURN = N'urn:quibiq:epcis:cbv:action:add')
		and ec.EPCURN is null 
		and qe.EPCClassURN is null
		and ev3.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:event' and (ev3.VocabularyURN = N'urn:quibiq:epcis:cbv:event:transaction')
		group by ed.EPCISEventID, ev.VocabularyURN;

		-- Prüfung TransformationEvent ohne transformationID
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  ed.EPCISEventID
			, N'Transformation-Event ohne transformationID muss mindestens einen Input (epc/quantity) und einen Output (epc/quantity) besitzen.'
		FROM #EventData ed
		JOIN #EPCISEvent_Vocabulary ev			  on ed.EPCISEventID = ev.EPCISEventID
		LEFT JOIN #EPCISEvent_TransformationID et  on ed.EPCISEventID = et.EPCISEventID
		WHERE 
			et.TransformationIDURN is null
		and ev.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:event' and ev.VocabularyURN = N'urn:quibiq:epcis:cbv:event:transformation'

		and 
		(
				(not exists (select top 1 1 from #EPCISEvent_EPC where EPCISEventID = ed.EPCISEventID and IsInput = 1)
			and not exists (select top 1 1 from #EPCISEvent_QuantityElement where EPCISEventID = ed.EPCISEventID and IsInput = 1))
	 
			or

			(not exists (select top 1 1 from #EPCISEvent_EPC where EPCISEventID = ed.EPCISEventID and IsOutput = 1)
			and not exists (select top 1 1 from #EPCISEvent_QuantityElement where EPCISEventID = ed.EPCISEventID and IsInput = 0))
		)

		group by ed.EPCISEventID;

		-- Prüfung TransformationEvent mit transformationID
		INSERT INTO #EPCISEvent_Error 
			(  EPCISEventID
			 , Reason)
		SELECT 
			  ed.EPCISEventID
			, N'Transformation-Event mit transformationID muss entweder einen Input (epc/quantity) oder einen Output (epc/quantity) besitzen.'
		FROM #EventData ed
		JOIN #EPCISEvent_Vocabulary ev			  on ed.EPCISEventID = ev.EPCISEventID
		JOIN #EPCISEvent_TransformationID et		  on ed.EPCISEventID = et.EPCISEventID
		WHERE 
		ev.VocabularyTypeURN = N'urn:quibiq:epcis:vtype:event' and (ev.VocabularyURN = N'urn:quibiq:epcis:cbv:event:transformation')

		and  (not exists (select top 1 1 from #EPCISEvent_EPC where EPCISEventID = ed.EPCISEventID and IsInput = 1)
		 and not exists (select top 1 1 from #EPCISEvent_QuantityElement where EPCISEventID = ed.EPCISEventID and IsInput = 1))
	    
		and  (not exists (select top 1 1 from #EPCISEvent_EPC where EPCISEventID = ed.EPCISEventID and IsOutput = 1)
		  and not exists (select top 1 1 from #EPCISEvent_QuantityElement where EPCISEventID = ed.EPCISEventID and IsInput = 0) )

		group by ed.EPCISEventID;

		--***************************************************************
		-- Debug OUT aus Zwischenstruktur 
		--***************************************************************
		IF @Debug = 1
		begin
			select 
				EPCISEventID,
				[ClientID],
				[EventTime],
				[RecordTime],
				[EventTimeZoneOffset],
				[EPCISRepresentation]
		    from 
				#EventData;

			select 
				BusinessTransactionIDURN,
				BusinessTransactionTypeURN,
				VocabularyTypeURN,
				BusinessTransactionIDID,
				BusinessTransactionTypeID,
				VocabularyTypeID,
				EPCISEventID
			from
				#EPCISEvent_BusinessTransactionID;

			select 
				QuantityElementID,
				EPCClassID,
				EPCClassURN,
				Quantity,
				IsInput,
				IsOutput,
				UOM,
				EPCISEventID
			from
				#EPCISEvent_QuantityElement;

			select 
				TransformationIDID,
				TransformationIDURN,
				EPCISEventID
			from
				#EPCISEvent_TransformationID;

			select 
				SourceDestinationID,
				SourceDestinationTypeID,
				SourceDestinationTypeURN,
				SourceDestinationURN,
				IsSource,
				EPCISEventID
			from
				#EPCISEvent_SourceDestination;

			select  
				EPCURN,
				EPCID,
				EPCISEventID,
				IsParentID,
				IsInput,
				IsOutput
			from
				#EPCISEvent_EPC;

			select 
				VocabularyTypeURN,
				VocabularyURN,
				VocabularyTypeID,
				ID,
				EPCISEventID
			from
				#EPCISEvent_Vocabulary;

			select 
				ValueTypeURN,
				ValueTypeTypeURN,
				DataTypeURN,
				DataTypeTypeURN,
				ValueTypeID,
				ValueTypeTypeID,
				DataTypeID,
				DataTypeTypeID,
				EPCISEventID,
				IntValue,
				FloatValue,
				TimeValue,
				StringValue,
				ParentURN,
				Depth,
				ExtensionType
			from 
				#EPCISEvent_Value;

			select  
				EPCISEventID,
				ExtensionTypeURN,
				ExtensionTypeTypeURN
			from 
				#EPCISEvent_ExtenstionType;

			select  
				EPCISEventID,
				TechnicalEPCISEventID 
			from 
				#EPCISEventIDs;

			select
				EPCISEventID,
				Reason
			from
				#EPCISEvent_Error;
		end;

		--***************************************************************
		-- Entfernen Fehlerhafter Events aus Zwischenstruktur 
		--***************************************************************
		IF exists (select top 1 1 from #EPCISEvent_Error)
		begin
			
			if @ProcessOnlyWholeDocument = 1 
			begin
				-- Fehlertext erstellen
				declare @curErrorText nvarchar(256);
				declare @errMessage   nvarchar(4000);
				set @errMessage = N'Following Errors occured while processing EventList: ';

				declare curError INSENSITIVE cursor for
					select
						Reason
					from #EPCISEvent_Error;
						
				open curError
				fetch next from curError into @curErrorText

				while @@FETCH_STATUS = 0
				begin
					set @errMessage = SUBSTRING(@errMessage, 1, 3744) + @curErrorText;
					fetch next from curError into @curErrorText
				end;

				-- Fehler werfen
				throw 53000, @errMessage, 1;
			end;

			-- Falls Einzelevents verarbeitet werden können
			
			delete d from 
				#EPCISEvent_BusinessTransactionID d
			join #EPCISEvent_Error e on e.EPCISEventID = d.EPCISEventID;

			delete d from 
				#EPCISEvent_EPC d
			join #EPCISEvent_Error e on e.EPCISEventID = d.EPCISEventID;

			delete d from 
				#EPCISEvent_Vocabulary d
			join #EPCISEvent_Error e on e.EPCISEventID = d.EPCISEventID;

			delete d from 
				#EPCISEvent_Value d
			join #EPCISEvent_Error e on e.EPCISEventID = d.EPCISEventID;
				
			delete d from 
				#EPCISEvent_ExtenstionType d
			join #EPCISEvent_Error e on e.EPCISEventID = d.EPCISEventID;
		end;

		--***************************************************************
		-- Events in Tabelle speichern und Konvertierung der EPCISEventID
		--***************************************************************
		 
		merge into Event.[EPCISEvent] as target
		using #EventData as source
		on 1 = 0
		when not matched by target then
			insert (ClientID, EventTime, RecordTime, EventTimeZoneOffset, [XmlRepresentation])
		    values (source.ClientID, source.EventTime, source.RecordTime, source.EventTimeZoneOffset, source.EPCISRepresentation)
		output source.EPCISEventID , inserted.[ID] into #EPCISEventIDs;

		update  
			t
		set t.EPCISEventID = s.TechnicalEPCISEventID
		from #EPCISEvent_BusinessTransactionID t
		join #EPCISEventIDs                    s on s.EPCISEventID = t.EPCISEventID;
		
		update  
			t
		set t.EPCISEventID = s.TechnicalEPCISEventID
		from #EPCISEvent_EPC t
		join #EPCISEventIDs                    s on s.EPCISEventID = t.EPCISEventID;

		update  
			t
		set t.EPCISEventID = s.TechnicalEPCISEventID
		from #EPCISEvent_Vocabulary t
		join #EPCISEventIDs                    s on s.EPCISEventID = t.EPCISEventID;

		update  
			t
		set t.EPCISEventID = s.TechnicalEPCISEventID
		from #EPCISEvent_Value t
		join #EPCISEventIDs                    s on s.EPCISEventID = t.EPCISEventID;

		update  
			t
		set t.EPCISEventID = s.TechnicalEPCISEventID
		from #EPCISEvent_ExtenstionType t
		join #EPCISEventIDs                    s on s.EPCISEventID = t.EPCISEventID;

		update  
			t
		set t.EPCISEventID = s.TechnicalEPCISEventID
		from #EPCISEvent_TransformationID t
		join #EPCISEventIDs                    s on s.EPCISEventID = t.EPCISEventID;

		update  
			t
		set t.EPCISEventID = s.TechnicalEPCISEventID
		from #EPCISEvent_SourceDestination t
		join #EPCISEventIDs                    s on s.EPCISEventID = t.EPCISEventID;

		update  
			t
		set t.EPCISEventID = s.TechnicalEPCISEventID
		from #EPCISEvent_QuantityElement t
		join #EPCISEventIDs                    s on s.EPCISEventID = t.EPCISEventID;


		-- Einzeleventfehler speichern - falls vorhanden
		IF exists (select top 1 1 from #EPCISEvent_Error)
		begin
			
			update  
				t
			set t.EPCISEventID = s.TechnicalEPCISEventID
			from #EPCISEvent_Error t
			join #EPCISEventIDs                    s on s.EPCISEventID = t.EPCISEventID;

			INSERT INTO [Import].[Error] (
				[TimeStampGeneration]
				,[AdditionalInformation]
				,[ErrorNumber]
				,[ErrorSeverity]
				,[ErrorProcedure]
				,[ErrorMessage]
				,[ErrorLine]
				,[ErrorState]
				,[ObjectID] )
			SELECT
				getdate()								   as TimeStampGeneration
				,N'ObjectID: Event.ID'				   as AdditionalInformation
				,55555								   as ErrorNumber
				,16										   as ErrorSeverity
				,N'usp_Import_Event'			           as ErrorProcedure
				,SUBSTRING(Reason, 1, 2048)	               as ErrorMessage
				,0						                   as ErrorLine
				,1						                   as ErrorState 
				,EPCISEventID							   as ObjectID
			FROM #EPCISEvent_Error;

		end;
					
		--***************************************************************
		-- Geprüfte Event Daten speichern
		--***************************************************************
		-- Da die interen EPCISEventIDs gegen die technischen ausgetauscht wurden ist nichts weiter zu beachten

		--***************************************************************
		-- EventVokabeln: IDs speichern
		--***************************************************************

		merge into Event.[EPCISEvent_Vocabulary] as target
			using #EPCISEvent_Vocabulary as source
		on target.[EPCISEventID] = source.EPCISEventID and target.[ID] = source.ID
		when not matched by target then
			insert ([EPCISEventID], [VocabularyID])
				values (source.EPCISEventID, source.ID);

		--***************************************************************
		-- EPC: EPCIDs zu den gesammelten EPCs bestimmen
		--***************************************************************

		merge into Event.EPC WITH (HOLDLOCK) as target									
		using (select distinct EPCURN from #EPCISEvent_EPC) as source
		on target.URN = source.EPCURN
		when not matched by target then
			insert(URN)
				values (source.EPCURN);

		merge into #EPCISEvent_EPC as target
		using Event.EPC as source
		on target.EPCURN = source.URN
		when matched then
			update set EPCID = source.[ID];


		--***************************************************************
		-- EventEPC: IDs speichern
		--***************************************************************		

		merge into Event.[EPCISEvent_EPC] as target
		using (select 
				  EPCISEventID,
				  EPCID,
				  IsParentID,
				  IsInput,
				  IsOutput
				from #EPCISEvent_EPC 
				group by EPCISEventID, EPCID, IsParentID, IsInput, IsOutput)  as source
		on target.[EPCISEventID] = source.EPCISEventID and target.EPCID = source.EPCID
		when not matched by target then
			insert ([EPCISEventID], EPCID, [IsParentID], [IsInput], [IsOutput])
				values (source.EPCISEventID , source.EPCID, source.IsParentID, source.IsInput, source.IsOutput);

		--***************************************************************
		-- TransformationID: IDs speichern
		--***************************************************************

		merge into Event.TransformationID WITH (HOLDLOCK) as target					
		using (	select 
					TransformationIDURN
				from #EPCISEvent_TransformationID
				group by TransformationIDURN
			) as source
		on target.URN = source.TransformationIDURN
		when not matched by target then
			insert (URN)
				values (source.TransformationIDURN);

		merge into #EPCISEvent_TransformationID as target
		using Event.TransformationID as source
		on target.TransformationIDURN = source.URN
		when matched then
			update set TransformationIDID = source.[ID];
	
		--***************************************************************
		-- EventTransformationID: IDs speichern
		--***************************************************************

		merge into Event.[EPCISEvent_TransformationID] as target
		using(	select 
					EPCISEventID, TransformationIDID
				from #EPCISEvent_TransformationID
				group by EPCISEventID, TransformationIDID 
				)  as source
		on target.[EPCISEventID] = source.EPCISEventID and target.TransformationIDID = source.TransformationIDID
		when not matched by target then
			insert ([EPCISEventID], TransformationIDID)
				values (source.EPCISEventID, source.TransformationIDID);

		--***************************************************************
		-- QuantityElement: IDs speichern
		--***************************************************************

		merge into Event.QuantityElement WITH (HOLDLOCK) as target					
		using (	select 
					EPCClassID, Quantity, UOM 
				from #EPCISEvent_QuantityElement
				group by EPCClassID, Quantity, UOM
			) as source
		on target.EPCClassID = source.EPCClassID and target.Quantity = source.Quantity and target.UOM = source.UOM
		when not matched by target then
			insert (EPCClassID, Quantity, UOM)
				values (source.EPCClassID, source.Quantity, source.UOM);

		merge into #EPCISEvent_QuantityElement as target
		using Event.QuantityElement as source
		on target.EPCClassID = source.EPCClassID and target.Quantity = source.Quantity and target.UOM = source.UOM
		when matched then
			update set QuantityElementID = source.[ID];
	
		--***************************************************************
		-- EventQuantityElement: IDs speichern
		--***************************************************************

		merge into Event.[EPCISEvent_QuantityElement] as target
		using(	select 
					EPCISEventID, QuantityElementID, IsInput, IsOutput
				from #EPCISEvent_QuantityElement
				group by EPCISEventID, QuantityElementID, IsInput, IsOutput 
				)  as source
		on target.[EPCISEventID] = source.EPCISEventID and target.QuantityElementID = source.QuantityElementID
		when not matched by target then
			insert ([EPCISEventID], QuantityElementID, IsInput, IsOutput)
				values (source.EPCISEventID, source.QuantityElementID, source.IsInput, source.IsOutput);


		--***************************************************************
		-- EventSourceDestination: IDs speichern
		--***************************************************************

		merge into Event.[EPCISEvent_SourceDestination] as target
		using(	select 
					EPCISEventID, SourceDestinationID, SourceDestinationTypeID, IsSource 
				from #EPCISEvent_SourceDestination
				group by EPCISEventID, SourceDestinationID, SourceDestinationTypeID, IsSource
				)  as source
		on target.[EPCISEventID] = source.EPCISEventID and target.SourceDestinationID = source.SourceDestinationID and target.SourceDestinationTypeID = source.SourceDestinationTypeID and target.IsSource = source.IsSource
		when not matched by target then
			insert ([EPCISEventID], SourceDestinationID, SourceDestinationTypeID, IsSource)
				values (source.EPCISEventID, source.SourceDestinationID, source.SourceDestinationTypeID, source.IsSource);


		--***************************************************************
		-- BusinessTransaction: IDs speichern
		--***************************************************************

		merge into Event.BusinessTransactionID WITH (HOLDLOCK) as target			
		using (	select 
					BusinessTransactionTypeID, BusinessTransactionIDURN 
				from #EPCISEvent_BusinessTransactionID
				group by BusinessTransactionTypeID, BusinessTransactionIDURN 
			) as source
		on target.BusinessTransactionTypeID = source.BusinessTransactionTypeID and target.URN = source.BusinessTransactionIDURN
		when not matched by target then
			insert (URN, BusinessTransactionTypeID)
				values (source.BusinessTransactionIDURN, source.BusinessTransactionTypeID);

		merge into #EPCISEvent_BusinessTransactionID as target
		using Event.BusinessTransactionID as source
		on target.BusinessTransactionTypeID = source.BusinessTransactionTypeID and target.BusinessTransactionIDURN = source.URN
		when matched then
			update set BusinessTransactionIDID = source.ID;
	
		--***************************************************************
		-- EventBusinessTransaction: IDs speichern
		--***************************************************************

		merge into Event.EPCISEvent_BusinessTransactionID as target
		using(	select 
					EPCISEventID, BusinessTransactionIDID 
				from #EPCISEvent_BusinessTransactionID
				group by EPCISEventID, BusinessTransactionIDID 
				)  as source
		on target.EPCISEventID = source.EPCISEventID and target.BusinessTransactionIDID = source.BusinessTransactionIDID
		when not matched by target then
			insert (EPCISEventID, BusinessTransactionIDID)
				values (source.EPCISEventID, source.BusinessTransactionIDID);


		--***************************************************************
		-- EPCISHeader: IDs speichern
		--***************************************************************

		if @StandardBusinessDocumentHeader is not null and @StandardBusinessDocumentHeader.exist(N'/*[local-name() = "StandardBusinessDocumentHeader"]') = 1
		begin

			DECLARE @EPCISDocumentHeader table (DocumentHeaderID bigint);
			DECLARE @HeaderVersion CHAR(10);

			SET @HeaderVersion = @StandardBusinessDocumentHeader.value(N'(//*[local-name() = "HeaderVersion"]/text())[1]', 'char(10)');

			insert into DocumentHeader.EPCISDocumentHeader (EPCISDocumentHeader, HeaderVersion) 
				output Inserted.ID into @EPCISDocumentHeader
			values (@StandardBusinessDocumentHeader, @HeaderVersion)

			insert into Event.EPCISEvent_DocumentHeader (DocumentHeaderID, EPCISEventID) 
			select
				 (select top 1 DocumentHeaderID from @EPCISDocumentHeader)
				,e.TechnicalEPCISEventID
			from #EPCISEventIDs e
			group by e.TechnicalEPCISEventID;

		end;

		--***************************************************************
		-- EPCISEvent_Extensions: Neue Extensions dynamisch anlegen
		--***************************************************************

		merge into Vocabulary.[Vocabulary] WITH (HOLDLOCK) as target
		using ( select 
					 e.ExtensionTypeURN
					,vt.ID as [VocabularyTypeID]
					,@SystemClientID as ClientID
				from #EPCISEvent_ExtenstionType e 
				join Vocabulary.[VocabularyType]  vt on vt.URN = e.ExtensionTypeTypeURN
				group by e.ExtensionTypeURN, vt.ID
		) as source
		on target.URN                = source.ExtensionTypeURN and
		   target.[VocabularyTypeID] = source.[VocabularyTypeID] and
		   target.ClientID           = source.ClientID
			when matched then
				update set Deleted = 0
		when not matched by target then
			insert (ClientID, [VocabularyTypeID], URN) 
			values (source.ClientID, source.[VocabularyTypeID], source.ExtensionTypeURN);

		--***************************************************************
		-- EPCISEvent_Value: IDs zu den gesammelten URN bestimmen
		--***************************************************************

		merge into #EPCISEvent_Value as target
		using Vocabulary.[VocabularyType] as source
		on target.ValueTypeTypeURN = source.URN 
		when matched then
			update set ValueTypeTypeID = source.[ID];

		merge into #EPCISEvent_Value as target
		using Vocabulary.[VocabularyType] as source
		on target.DataTypeTypeURN = source.URN
		when matched then
			update set DataTypeTypeID = source.[ID];

		merge into #EPCISEvent_Value as target
		using Vocabulary.[Vocabulary] as source
		on target.ValueTypeURN = source.URN and target.ValueTypeTypeID = source.[VocabularyTypeID]
		when matched then
			update set ValueTypeID = source.[ID];

		merge into #EPCISEvent_Value as target
		using Vocabulary.[Vocabulary] as source
		on target.DataTypeURN = source.URN and target.DataTypeTypeID = source.[VocabularyTypeID]
		when matched then
			update set DataTypeID = source.[ID];

		--***************************************************************
		-- EPCISEvent_Value/EPCISEvent_Extensions speichern
		--***************************************************************

		-- EPCISEvent_Value Einträge generieren (ex können mehrere je Event existieren,
		-- Merge Funktion erleichtert jedoch die Parent/Child auflösung
		merge into Event.[EPCISEvent_Value] as target
		using 
			(select
				 ValueTypeID
				,ValueTypeURN
				,DataTypeID
				,DataTypeURN
				,IntValue
				,FloatValue
				,TimeValue
				,StringValue
				,ParentURN
				,EPCISEventID
				,Depth
			FROM #EPCISEvent_Value 
			)
			as source
		on 
			1 = 0
		when not matched by target then
			insert ([EPCISEventID], ValueTypeID, DataTypeID)
				values (source.EPCISEventID, source.ValueTypeID, source.DataTypeID)
		output 
			inserted.[ID]           as EPCISEvent_ValueID,
			source.ValueTypeURN     as ValueTypeURN,
			source.DataTypeURN      as DataTypeURN,
			source.IntValue         as IntValue,
			source.FloatValue       as FloatValue,
			source.TimeValue        as TimeValue,
			source.StringValue      as StringValue,
			source.ParentURN        as ParentURN,
			null                    as Parent_EPCISEvent_ValueID,
			source.Depth            as Depth	   
			into #EPCISEvent_Value_Values;
		;

	    -- Da die Extension Inhalte nicht definiert werden ist es für die Abfrageoberfläche einfacher das Datum in jedem
		-- gültigen Format abzuspeichern, so kann eine effiziente / einfache und schnelle Abfrage erfolgen auf 
		-- Kosten von Datenredundanzen

		-- Numeric Values (Float und Int)
		merge into Event.[EPCISEvent_Value_Numeric] as target
		using ( select 
					   EPCISEvent_ValueID
					  ,FloatValue as Value
				from
					#EPCISEvent_Value_Values
				where FloatValue is not null )
		as source
		on 
			target.[EPCISEvent_ValueID] = source.EPCISEvent_ValueID
		and target.Value              = source.Value 
		when not matched by target then
			insert ([EPCISEvent_ValueID], Value) 
			values (source.EPCISEvent_ValueID, source.Value);

		-- Time
		merge into Event.[EPCISEvent_Value_Datetime] as target
		using ( select 
					   EPCISEvent_ValueID
					  ,TimeValue as Value
				from
					#EPCISEvent_Value_Values
				where TimeValue is not null )
		as source
		on 
			target.[EPCISEvent_ValueID] = source.EPCISEvent_ValueID
		and target.Value              = source.Value 
		when not matched by target then
			insert ([EPCISEvent_ValueID], Value) 
			values (source.EPCISEvent_ValueID, source.Value);

		-- String		
		merge into Event.Value_String WITH (HOLDLOCK) as target			
		using ( select 
					   StringValue as Value
				from
					#EPCISEvent_Value_Values
				where StringValue is not null
				group by StringValue )
		as source
		on 
		  target.Value              = source.Value 
		when not matched by target then
			insert (Value) 
			values (source.Value);


		merge into Event.[EPCISEvent_Value_String] as target
		using (
				select 
					vv.EPCISEvent_ValueID,
					vs.[ID] as Value_StringID
				from #EPCISEvent_Value_Values vv
				join Event.Value_String       vs on vs.Value = vv.StringValue
		
		      ) as source
		on 
			target.[EPCISEvent_ValueID] = source.EPCISEvent_ValueID
		and target.Value_StringID     = source.Value_StringID 
		when not matched by target then
			insert ([EPCISEvent_ValueID], Value_StringID) 
			values (source.EPCISEvent_ValueID, source.Value_StringID);

		-- XML / Parents 
		-- Parents Ermitteln

		UPDATE #EPCISEvent_Value_Values 
		  set Parent_EPCISEvent_ValueID = parent.EPCISEvent_ValueID
		  FROM #EPCISEvent_Value_Values children
		  JOIN (SELECT
					 EPCISEvent_ValueID
					,ValueTypeURN
					,Depth
				FROM #EPCISEvent_Value_Values) as parent on  parent.ValueTypeURN = children.ParentURN
		                                                 and parent.Depth        = (children.Depth-1)
		  WHERE children.Depth > 0;

		-- Hierarchy speichern
		merge into Event.[EPCISEvent_Value_Hierarchy] as target
		using ( select 
					   [EPCISEvent_ValueID]
					  ,[Parent_EPCISEvent_ValueID]
				from
					#EPCISEvent_Value_Values
				where Depth > 0 )
		as source
		on 
			target.[EPCISEvent_ValueID]		   = source.[EPCISEvent_ValueID] 
		and target.[Parent_EPCISEvent_ValueID] = source.[Parent_EPCISEvent_ValueID]
		when not matched by target then
			insert ([EPCISEvent_ValueID], [Parent_EPCISEvent_ValueID]) 
			values (source.[EPCISEvent_ValueID], source.[Parent_EPCISEvent_ValueID]);

END
