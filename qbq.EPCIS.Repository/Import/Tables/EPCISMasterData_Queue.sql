CREATE TABLE [Import].[EPCISMasterData_Queue] (
    [ID]                      BIGINT         IDENTITY (1, 1) NOT NULL,
    [Client]                  NVARCHAR (512) NOT NULL,
    [EPCISMasterData]         XML            NOT NULL,
    [Processed]               BIT            CONSTRAINT [DF_EPCISMasterData_Queue_Processed] DEFAULT ((0)) NOT NULL,
    [Error]                   BIT            CONSTRAINT [DF_EPCISMasterData_Queue_Error] DEFAULT ((0)) NOT NULL,
    [EPCISMasterDataOriginal] XML            NULL,
    CONSTRAINT [PK_EPCISMasterData_Queue] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO

CREATE TRIGGER [Import].[Tr_EPCISMasterData_Queue]
ON [Import].[EPCISMasterData_Queue]
FOR INSERT
AS
BEGIN
    SET NoCount ON;

	UPDATE u
		SET u.[EPCISMasterDataOriginal] = u.[EPCISMasterData]
	FROM [Import].[EPCISMasterData_Queue] u
	JOIN inserted i on i.ID = u.ID;

END
