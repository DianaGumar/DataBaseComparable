
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
-- 21.02.2013 | 1.0.0.0 | Sven Scholle	      | Erstellt.
-----------------------------------------------------------------------------------------
-- 21.07.2014 | 1.0.2.0 | Florian Wagner      | FLW001 - Nur als nicht gelöscht markierte Stammdaten verwenden
-----------------------------------------------------------------------------------------
CREATE procedure [Import].[usp_Import_MasterData] 
	@EPCISMasterData		xml, 
	@Client					nvarchar(512)
as
begin

	set nocount on

	--***************************************************************
	-- Variablendeklaration für gesamt SP:
	--***************************************************************

	declare 
		--@EPCISMasterData_QueueID bigint,
		@SystemClientID			bigint,
		@ClientID				bigint,
		@ContentTypeID			bigint,

		@VocabularyList			xml,
		@Vocabulary				xml,	
		@VocabularyType			nvarchar(512),
		@VocabularyTypeID		bigint,
		@MaxOccurs				int,
		@DeletedFlag			bit,																--FLW001+

		@VocabularyElementList	xml,
		@VocabularyElement		xml,
		@VocabularyElementID	bigint,
		@VocabularyElementurn	nvarchar(512);
	
	--***************************************************************
	-- Tabelle zum Zwischenspeichern der hierachischen Vokabeln, da IDs erst bekannt sind,
	-- wenn alles andere vorher eingetragen ist.
	--***************************************************************

	if object_id('tempdb..#VocabularyChildren') is not null drop table #VocabularyChildren
	create table #VocabularyChildren
	(
		VocabularyParentURN	nvarchar(512)	not null,
		VocabularyChildURN	nvarchar(512)	not null,
		ParentVocabularyID	bigint			null,
		ChildVocabularyID	bigint			null,
		Deleted				bit				not null default 0										--FLW001+
	)

	--select TOP 1
	--	@EPCISMasterData = EPCISMasterData,
	--	@Client = Client,
	--	@EPCISMasterData_QueueID = ID
	--from 
	--	Import.EPCISMasterData_Queue
	--where
	--	Processed = 0 and Error = 0

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

		declare @msg nvarchar(2048) = 'Mandant ''' + @Client + ''' does not exist.';
		throw 50000, @msg, 1

	end;

	--begin try

	--	begin transaction;

		--***************************************************************
		-- Liste der Vokabeln laden
		--***************************************************************
		with xmlnamespaces (N'urn:epcglobal:epcis-masterdata:xsd:1' as epcismd, N'urn:quibiq:epcis:md' as quibiqmd)		--FLW001~
		select
			@VocabularyList = @EPCISMasterData.query(N'/epcismd:EPCISMasterDataDocument/EPCISBody/VocabularyList/.');

		--***************************************************************
		-- per Schleife durch Liste aller Vokabeln durcharbeiten
		--***************************************************************
		declare curVocabulary cursor for
			select
				content.nodes.query(N'.')
			from
				@VocabularyList.nodes(N'/*/*/.') as content(nodes)

		open curVocabulary

		fetch next from curVocabulary into @Vocabulary

		while @@FETCH_STATUS = 0
		begin

			--select @Vocabulary as 'Vocabulary'
			--***************************************************************
			-- Vokabeltyp auslesen
			--***************************************************************

			select @VocabularyType = @Vocabulary.value(N'(/Vocabulary/@type)[1]', 'nvarchar(512)')
			-->FLW001 INSERT START
			-- Ermitteln des gelöscht Status 
			;with xmlnamespaces (N'urn:epcglobal:epcis-masterdata:xsd:1' as epcismd, N'urn:quibiq:epcis:md' as quibiqmd)
			select @DeletedFlag = @Vocabulary.value(N'(/Vocabulary/@quibiqmd:delete)[1]', 'bit')						
			if (@DeletedFlag is null) SET @DeletedFlag = 0;
			--<FLW001 INSERT END	
			
			select @MaxOccurs = 1

			--***************************************************************
			-- ID von VokabelTyp bestimmen (falls nicht vorhanden --> eintragen)
			--***************************************************************

			set @VocabularyTypeID = 0

			select
				@VocabularyTypeID = ID
			from
				Vocabulary.VocabularyType
			where
				URN = @VocabularyType

			if @VocabularyTypeID = 0
			begin
				--***************************************************************
				-- VokabelTyp nicht vorhanden --> eintragen
				--***************************************************************
	
				Insert into 
					Vocabulary.VocabularyType (URN, Description, MaxOccurs)
				values
					(@VocabularyType, '', @MaxOccurs)

				set @VocabularyTypeID = SCOPE_IDENTITY();

			end

			-->FLW001 INSERT START
			-- Eintragen der Verknüpfung Mandant zu Vokabular
			IF not exists (select top 1 1 from Vocabulary.VocabularyType_Client where VocabularyTypeID = @VocabularyTypeID and ClientID = @ClientID)
			BEGIN			
				INSERT INTO
					Vocabulary.VocabularyType_Client (VocabularyTypeID, ClientID) 
				VALUES (@VocabularyTypeID, @ClientID);
			END;

			-- Aktualisieren des Status des Vokabulars
			UPDATE Vocabulary.VocabularyType_Client 
			   SET Deleted = @DeletedFlag
			 WHERE VocabularyTypeID = @VocabularyTypeID and ClientID = @ClientID;

			-- Aktualisieren des Status der VokabularElemente
			--IF @DeletedFlag = 1
			--BEGIN
			--	UPDATE Vocabulary.Vocabulary
			--	   SET Deleted = @DeletedFlag
			--	WHERE ClientID = @ClientID and VocabularyTypeID = @VocabularyTypeID;
			--END;
			--<FLW001 INSERT END

			--***************************************************************
			-- Liste der Vokabelelemente laden
			--***************************************************************

			select
				@VocabularyElementList = @Vocabulary.query(N'/Vocabulary/VocabularyElementList/.');


			--***************************************************************
			-- per Schleife durch Liste aller VokabelElement durcharbeiten
			--***************************************************************
			declare curVocabularyElement cursor for
				select
					content.nodes.query(N'.')
				from
					@VocabularyElementList.nodes(N'/*/*/.') as content(nodes)

			open curVocabularyElement

			fetch next from curVocabularyElement into @VocabularyElement

			while @@FETCH_STATUS = 0
			begin

				--select @VocabularyElement as 'VocabularyElement'
				--***************************************************************
				-- Vokabelelementurn auslesen
				--***************************************************************

				select @VocabularyElementurn = @VocabularyElement.value(N'(/VocabularyElement/@id)[1]', 'nvarchar(512)')	
				-->FLW001 INSERT START
				-- Ermitteln des gelöscht Status, wenn das Vokabular als nicht gelöscht markiert ist			
				IF @DeletedFlag = 0
				BEGIN
					;with xmlnamespaces (N'urn:epcglobal:epcis-masterdata:xsd:1' as epcismd, N'urn:quibiq:epcis:md' as quibiqmd)
					select @DeletedFlag          = @VocabularyElement.value(N'(/VocabularyElement/@quibiqmd:delete)[1]', 'bit')	
					if (@DeletedFlag is null) SET @DeletedFlag = 0;
				END;
				--<FLW001 INSERT END			
					
				--***************************************************************
				-- ID von VokabelElementurn bestimmen (falls nicht vorhanden --> eintragen)
				--***************************************************************

				set @VocabularyElementID = 0

				select 
					@VocabularyElementID = ID
				from
					Vocabulary.Vocabulary
				where
					URN      = @VocabularyElementurn
				and VocabularyTypeID = @VocabularyTypeID																	--FLW001+
				and ClientID = @ClientID;

				if @VocabularyElementID = 0
				begin
					--***************************************************************
					-- VokabelElementurn nicht vorhanden --> eintragen
					--***************************************************************
			
					Insert into 
						Vocabulary.Vocabulary (ClientID, VocabularyTypeID, URN)
					values
						(@ClientID, @VocabularyTypeID ,@VocabularyElementurn)

					set @VocabularyElementID = SCOPE_IDENTITY();

				end

				-->FLW001 INSERT START
				-- Aktualisieren des gelöscht Status des Vokabularelements
				UPDATE Vocabulary.Vocabulary 
				   SET Deleted = @DeletedFlag
				 WHERE ID = @VocabularyElementID and ClientID = @ClientID;
				--<FLW001 INSERT END

				--***************************************************************
				-- Alle Attribute zum Vokabelelement laden und zwischenspeichern
				--***************************************************************

				if object_id('tempdb..#VocabularyAttribute') is not null drop table #VocabularyAttribute
				
				create table #VocabularyAttribute
				(
					VocabularyID		bigint			not null,
					AttributeTypeID		bigint			null,
					[XML]				xml				not null,
					AttributeTypeURN	nvarchar(512)	null,
					Value				xml				null,
					ContentTypeID		bigint			null
					,Deleted			bit				not null DEFAULT 0								--FLW001+
				)

				select top 1
					@ContentTypeID = v.ID
				from
					 Vocabulary.Vocabulary     v  
				join Vocabulary.VocabularyType vt on v.VocabularyTypeID = vt.ID
				where
					v.URN      = N'urn:quibiq:epcis:cbv:datatype:unknown'
				and vt.URN     = N'urn:quibiq:epcis:vtype:datatype'
				and v.ClientID = @SystemClientID

				--<FLW001 MODIFY START
				;with xmlnamespaces (N'urn:epcglobal:epcis-masterdata:xsd:1' as epcismd, N'urn:quibiq:epcis:md' as quibiqmd)
				insert into #VocabularyAttribute (VocabularyID, [XML], ContentTypeID, Deleted)
				select
					@VocabularyElementID,
					content.nodes.query(N'.') as [xml],
					@ContentTypeID,
					ISNULL(content.nodes.value(N'(./@quibiqmd:delete)[1]', 'bit'), 0)	
				from
					@VocabularyElement.nodes(N'/*/attribute/.') as content(nodes);		
				--<FLW001 MODIFY END

				--***************************************************************
				-- Aufbereiten der Attribute, z.B. Formatieren, Fremdschlüssel bestimmen etc.
				--***************************************************************

				-- Erst die Values die eine XMl-Struktur darstellen

				update
					#VocabularyAttribute
				set
					AttributeTypeURN = [XML].value(N'(/attribute/@id)[1]', 'nvarchar(512)'),
					Value =
					(				
						select
							[XML].query(N'if (fn:empty(/*/*))
											then
											  /*/text()
											else
											  /*/*
											 ')
						for xml path(''), root('Value')
					)
			
				merge into Vocabulary.AttributeType as target
				using #VocabularyAttribute as source
				on target.URN = source.AttributeTypeURN
				when not matched by target then
					insert (URN, Description, ContentTypeID)
						values (source.AttributeTypeURN, '', source.ContentTypeID);

				update
					va
				set
					va.AttributeTypeID = at.ID
				from
					#VocabularyAttribute va
				inner join
					Vocabulary.AttributeType at on at.URN = va.AttributeTypeURN

				--select
				--	*
				--from
				--	#VocabularyAttribute


				merge into Vocabulary.VocabularyAttribute as target
				using #VocabularyAttribute as source
				on target.VocabularyID = source.VocabularyID and target.AttributeTypeID = source.AttributeTypeID
				when matched then
					update set Value = source.Value, Deleted = source.Deleted					--FLW001~
				when not matched by target then
					insert (VocabularyID, AttributeTypeID, Value)
						values (source.VocabularyID, source.AttributeTypeID, source.Value);
			
				drop table #VocabularyAttribute


				--***************************************************************
				-- Alle Children zum Vokabelelement laden und zwischenspeichern
				--***************************************************************

				insert into #VocabularyChildren (VocabularyParentURN, ParentVocabularyID, VocabularyChildURN)
				select
					@VocabularyElementurn,
					@VocabularyElementID,
					content.nodes.query(N'.').value(N'(/id/node())[1]', 'nvarchar(max)')
				from
					@VocabularyElement.nodes(N'/*/children/id/.') as content(nodes);		

				-->FLW001 INSERT START
				-- Aktualisieren des gelöscht Status des Childelements (wegen Schema nicht via Attribut möglich)
				update vc
				set Deleted = 1, VocabularyChildURN = REPLACE ( VocabularyChildURN , N'urn:quibiq:epcis:md:delete#' , N'' )
				from #VocabularyChildren vc
				where vc.VocabularyChildURN like N'urn:quibiq:epcis:md:delete#%' and ISNULL(ParentVocabularyID, -1) = @VocabularyElementID;

				-- Wenn Element gelöscht wird auch alle Childs löschen
				--IF @DeletedFlag = 1 
				--BEGIN
				--	update #VocabularyChildren
				--	set Deleted = 1
				--	where ParentVocabularyID = @VocabularyElementID;
				--END;
				--<FLW001 INSERT END
				
				fetch next from curVocabularyElement into @VocabularyElement

			end

			close curVocabularyElement
			deallocate curVocabularyElement

			fetch next from curVocabulary into @Vocabulary
		end

		close curVocabulary
		deallocate curVocabulary

		--***************************************************************
		-- Zu allen ChildrenURN die zugehörigen IDs bestimmen
		--***************************************************************

		update 
			vc
		set
			vc.ChildVocabularyID = v.ID
		from
			#VocabularyChildren vc
		inner join
			Vocabulary.Vocabulary v on v.URN = vc.VocabularyChildURN and v.ClientID = @ClientID						--FLW001~

		--***************************************************************
		-- Eintragen der Children
		--***************************************************************

		merge into Vocabulary.VocabularyChildren as target
		using #VocabularyChildren as source
		on target.VocabularyID = source.ParentVocabularyID and target.ChildVocabularyID = source.ChildVocabularyID
		-->FLW001 MODIFY START
		when matched 
			then update set Deleted = source.Deleted
		when not matched by target
			then insert (VocabularyID, ChildVocabularyID, Deleted)
				values (source.ParentVocabularyID, source.ChildVocabularyID, source.Deleted);
		-->FLW001 MODIFY END

		--select 
		--	*
		--from
		--	#VocabularyChildren

		drop table #VocabularyChildren

		--update
		--	Import.EPCISMasterData_Queue
		--set
		--	Processed = 1
		--where
		--	ID = @EPCISMasterData_QueueID
		--delete from
		--	Import.EPCISMasterData_Queue
		--where 
		--	ID = @EPCISMasterData_QueueID;

	--	commit Transaction;

	--end try

	--begin catch
		
	--	rollback transaction;

	--	update
	--		Import.EPCISMasterData_Queue
	--	set
	--		Error = 1
	--	where
	--		ID = @EPCISMasterData_QueueID

	--	exec [Import].[usp_write_error_log] 
	--		@AddInformation = N'ObjectID: MasterData_Queue',
	--		@ObjectID = @EPCISMasterData_QueueID;


	--end catch
end
