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
-- 25.02.2013 | 1.0.0.0 | Sven Scholle	      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Import_MasterData_to_Queue]
	 @EPCISMasterData xml
	,@Client nvarchar(255) = 'urn:quibiq:epcis:cbv:client:gmos'
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
	SET NOCOUNT ON;

	begin try

		begin transaction

		exec [Import].[usp_Import_MasterData]
			@EPCISMasterData = @EPCISMasterData,
			@Client          = @Client;

		;with XMLNAMESPACES ('http://Import/SQL' as "sql")
		select	
			1 as "sql:ReturnValue"
		for xml path(''), root('sql:usp_Import_MasterData_to_Queue')

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
			INSERT INTO [Import].[EPCISMasterData_Queue] (
				EPCISMasterData, Client, Processed, Error)
			OUTPUT inserted.ID INTO @ErrorQueue
			VALUES
				(
				@EPCISMasterData, @Client, 0, 1
				)

			SELECT TOP 1 @ErrorQueueID = ID FROM @ErrorQueue;

			;with XMLNAMESPACES ('http://Import/SQL' as "sql")
			select	
				1 as "sql:ReturnValue"
			for xml path(''), root('sql:usp_Import_MasterData_to_Queue')

			-- Protokolliere Fehler
			exec [Import].[usp_write_error_log]
				 @AddInformation = N'ObjectID: EPCISMasterData_QUEUE'
				,@ObjectID = @ErrorQueueID;

			commit transaction;

		end try
		begin catch

			rollback transaction;

			-- Rethrow Error with extended Error Message
			DECLARE @ErrorMsg		nvarchar(4000) = ERROR_MESSAGE();
			DECLARE @ErrorState		int			   = isnull(ERROR_STATE(), 1);

			SET @ErrorMsg = N'Error while storing to MasterDataQUEUE' + SUBSTRING(@ErrorMsg, 1, 3962);

			THROW 51000, @ErrorMsg, @ErrorState;

		end catch;

	end catch;
END