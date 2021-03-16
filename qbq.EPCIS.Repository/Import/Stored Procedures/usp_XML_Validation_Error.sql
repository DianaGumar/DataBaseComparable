CREATE PROCEDURE  [Import].[usp_XML_Validation_Error](
	@Document xml,
	@Client nvarchar(255) = N'urn:quibiq:epcis:cbv:client:gmos',
	@AdditionalInformation nvarchar(2048),
	@ErrorNumber int,
	@ErrorProcedure nvarchar(126),
	@ErrorMessage nvarchar(2048),
	@ErrorLine int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	begin try

		begin transaction

			declare @ErrorQueue table (
				ID bigint
			);

			declare @ErrorQueueID bigint;

			-- Fehlerprotokoll
			INSERT INTO [Import].[EPCISEvent_Queue] 
				(EPCISEvent
				,Client
				,Processed
				,Error)
			OUTPUT inserted.ID INTO @ErrorQueue
			VALUES
				(@Document
				,@Client
				,0
				,1)
			
			SELECT TOP 1 @ErrorQueueID = ID FROM @ErrorQueue;

			INSERT INTO [Import].[Error]
			   ([TimeStampGeneration]
			   ,[AdditionalInformation]
			   ,[ErrorNumber]
			   ,[ErrorSeverity]
			   ,[ErrorProcedure]
			   ,[ErrorMessage]
			   ,[ErrorLine]
			   ,[ErrorState]
			   ,[ObjectID])
			VALUES
			   (getdate()
			   ,@AdditionalInformation
			   ,@ErrorNumber
			   ,0
			   ,@ErrorProcedure 
			   ,@ErrorMessage
			   ,@ErrorLine
			   ,0
			   ,@ErrorQueueID)

		commit transaction

	end try
	begin catch
		rollback transaction

			-- Rethrow Error with extended Error Message
			DECLARE @ErrorMsg		nvarchar(4000) = ERROR_MESSAGE();
			DECLARE @ErrorState		int			   = isnull(ERROR_STATE(), 1);

			SET @ErrorMsg = N'Error while storing to Event QUEUE' + SUBSTRING(@ErrorMsg, 1, 3962);

			THROW 51000, @ErrorMsg, @ErrorState;

		end catch;

END
