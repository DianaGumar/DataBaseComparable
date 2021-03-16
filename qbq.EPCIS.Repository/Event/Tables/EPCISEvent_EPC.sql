CREATE TABLE [Event].[EPCISEvent_EPC] (
    [ID]           BIGINT IDENTITY (1, 1) NOT NULL,
    [EPCISEventID] BIGINT NOT NULL,
    [EPCID]        BIGINT NOT NULL,
    [IsParentID]   BIT    NOT NULL,
    [IsInput]      BIT    CONSTRAINT [DF_EPCISEvent_EPC_IsInput] DEFAULT ((0)) NOT NULL,
    [IsOutput]     BIT    CONSTRAINT [DF_EPCISEvent_EPC_IsOutput] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EPCISEvent_EPC] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_EPCISEvent_EPC_EPC] FOREIGN KEY ([EPCID]) REFERENCES [Event].[EPC] ([ID]),
    CONSTRAINT [FK_EPCISEvent_EPCISEvent_EPC] FOREIGN KEY ([EPCISEventID]) REFERENCES [Event].[EPCISEvent] ([ID]) ON DELETE CASCADE
);


GO
ALTER TABLE [Event].[EPCISEvent_EPC] NOCHECK CONSTRAINT [FK_EPCISEvent_EPC_EPC];


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_EPCISEvent_EPC]
    ON [Event].[EPCISEvent_EPC]([EPCISEventID] ASC, [EPCID] ASC, [IsParentID] ASC, [IsInput] ASC)
    INCLUDE([IsOutput]);


GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [Event].[Delete_EPC_For_EPCISEvent_EPC] 
   ON  [Event].[EPCISEvent_EPC] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	declare @rc int
	DELETE Event.EPC
	FROM Event.EPC epc
	INNER JOIN deleted d
		ON epc.ID = d.EPCID

	set @rc = @@ROWCOUNT

	IF OBJECT_ID('tempdb..#DebugInfo', 'U') IS NOT NULL
	BEGIN
		INSERT INTO #DebugInfo
		VALUES (
			'Delete EPC'
			,cast(@rc AS VARCHAR)
			)
	END
END
