CREATE TABLE [Import].[EPCISEvent_Queue] (
    [ID]                 BIGINT         IDENTITY (1, 1) NOT NULL,
    [Client]             NVARCHAR (512) NOT NULL,
    [EPCISEvent]         XML            NOT NULL,
    [Processed]          BIT            CONSTRAINT [DF_EPCISEvent_Queue_Processed] DEFAULT ((0)) NOT NULL,
    [Error]              BIT            CONSTRAINT [DF_EPCISEvent_Queue_Error] DEFAULT ((0)) NOT NULL,
    [EPCISEventOriginal] XML            NULL,
    CONSTRAINT [PK_EPCISEvent_Queue] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO

CREATE TRIGGER [Import].[Tr_EPCISEvent_Queue]
ON [Import].[EPCISEvent_Queue]
FOR INSERT
AS
BEGIN
	SET NoCount ON;

	UPDATE u
	SET u.[EPCISEventOriginal] = u.[EPCISEvent]
	FROM [Import].[EPCISEvent_Queue] u
	JOIN inserted i on i.ID = u.ID;

END
