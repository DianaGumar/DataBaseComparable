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
-- 30.01.2013 | 1.0.0.0 | Sven Scholle	      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Import_Event_to_Queue]
	@EPCISEvent xml,
	@Client nvarchar(255) = N'urn:quibiq:epcis:cbv:client:gmos'
AS
BEGIN
	DECLARE @RecordTime datetime2
	
	SET NOCOUNT ON;

	begin try

		begin transaction

		exec [Import].[usp_Import_Event]
			@EPCISEvent = @EPCISEvent,
			@Client     = @Client,
			@RecordTime = @RecordTime output

		;with XMLNAMESPACES ('http://Import/SQL' as "sql")
		select	
			1 as "sql:ReturnValue",
			@RecordTime as "sql:RecordTime"
		for xml path(''), root('sql:usp_Import_Event_to_Queue')

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

			;with XMLNAMESPACES ('http://Import/SQL' as "sql")
			select	
				ERROR_NUMBER() as "sql:ReturnValue",
				ERROR_MESSAGE() as "sql:Error"
			for xml path(''), root('sql:usp_Import_Event_to_Queue')

			-- Protokolliere Fehler
			exec [Import].[usp_write_error_log]
				 @AddInformation = N'ObjectID: EPCISEvent_QUEUE'
				,@ObjectID = @ErrorQueueID;

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

END