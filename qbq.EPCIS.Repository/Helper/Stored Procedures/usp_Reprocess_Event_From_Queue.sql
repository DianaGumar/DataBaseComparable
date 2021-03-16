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
-- 06.08.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
-- 03.09.2014 | 1.0.1.0 | Florian Wagner      | Mandanten von aussen berücksichtigen
--            |         | FLW001              | Originalbeleg durchschleussen
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Helper].[usp_Reprocess_Event_From_Queue]
	@QueueID   bigint = null,
	@ClientURN nvarchar(512) = null,	--FLW001+
	@All       bit    = 0
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @EPCISEvent     xml;
	DECLARE @EPCISEventOrig xml;		--FLW001+
	DECLARE @Client		    nvarchar(512);
	DECLARE @ErrorQID       bigint;

	IF @All = 0 and @QueueID is null
		THROW 51000, N'QueueID has to be set', 1;

	IF @All = 1 and @QueueID is not null
		THROW 51000, N'QueueID must not be set or @All has to be 0', 1;

	declare curEventQueue INSENSITIVE cursor for
		select EPCISEvent, EPCISEventOriginal, Client, ID from Import.EPCISEvent_Queue where Error = 1 and (ID = @QueueID or @QueueID is null) and (Client = @ClientURN or @ClientURN is null);	--FLW001~

	open curEventQueue;

	fetch next from curEventQueue into @EPCISEvent, @EPCISEventOrig, @Client, @ErrorQID;		--FLW001~

	while @@FETCH_STATUS = 0
	begin

		begin try

			begin transaction

			exec [Import].[usp_Import_Event]
				@EPCISEvent = @EPCISEvent,
				@Client     = @Client;

			delete from Import.Error where ErrorProcedure = N'usp_Import_Event' and ObjectID = @ErrorQID;
			delete from Import.EPCISEvent_Queue where ID = @ErrorQID;

			print N'Success for ' + CONVERT(nvarchar(50), @ErrorQID);

			commit transaction;

		end try
		begin catch

			rollback transaction;
			begin transaction;

			begin try
			
				declare @ErrorQueue table (
					ID bigint
				);

				declare @ErrorQueueID bigint;

				-- Fehlerprotokoll
				INSERT INTO [Import].[EPCISEvent_Queue] (
					EPCISEvent, Client, Processed, Error)
				OUTPUT inserted.ID INTO @ErrorQueue
				VALUES
					(
					@EPCISEvent, @Client, 0, 1
					);
			
				SELECT TOP 1 @ErrorQueueID = ID FROM @ErrorQueue;

				-- Protokolliere Fehler
				exec [Import].[usp_write_error_log]
					 @AddInformation = N'ObjectID: EPCISEvent_QUEUE'
					,@ObjectID = @ErrorQueueID;

				-->FLW001 INSERT START
				update Import.EPCISEvent_Queue set EPCISEventOriginal = @EPCISEventOrig where ID = @ErrorQueueID;
				--<FLW001 INSERT END

				delete from Import.Error where ErrorProcedure = N'usp_Import_Event' and ObjectID = @ErrorQID;
				delete from Import.EPCISEvent_Queue where ID = @ErrorQID;
				delete from @ErrorQueue;

				print N'Failure for ' + CONVERT(nvarchar(50), @ErrorQID) + N' - new ErrorQueueID ' + CONVERT(nvarchar(50), @ErrorQueueID) ;

				commit transaction;

			end try
			begin catch

				rollback transaction;

				-- Rethrow Error with extended Error Message
				DECLARE @ErrorMsg		nvarchar(4000) = ERROR_MESSAGE();
				DECLARE @ErrorState		int			   = isnull(ERROR_STATE(), 1);

				SET @ErrorMsg = N'Error while storing to Event QUEUE' + SUBSTRING(@ErrorMsg, 1, 3962);

				THROW 51000, @ErrorMsg, @ErrorState;

			end catch;


		end catch;

		fetch next from curEventQueue into @EPCISEvent, @EPCISEventOrig, @Client, @ErrorQID;		--FLW001~
	end; -- CURSOR WHILE

	close curEventQueue;
	deallocate curEventQueue;

END
