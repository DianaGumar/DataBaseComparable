CREATE TABLE [Event].[EPCISEvent_BusinessTransactionID] (
    [ID]                      BIGINT IDENTITY (1, 1) NOT NULL,
    [EPCISEventID]            BIGINT NOT NULL,
    [BusinessTransactionIDID] BIGINT NOT NULL,
    CONSTRAINT [PK_EPCISEvent_BusinessTransactionID] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_BusinessTransactionID_EPCISEvent_BusinessTransactionID] FOREIGN KEY ([BusinessTransactionIDID]) REFERENCES [Event].[BusinessTransactionID] ([ID]),
    CONSTRAINT [FK_EPCISEvent_EPCISEvent_BusinessTransactionID] FOREIGN KEY ([EPCISEventID]) REFERENCES [Event].[EPCISEvent] ([ID]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_EPCISEvent_BusinessTransactionID_EPCISEventID]
    ON [Event].[EPCISEvent_BusinessTransactionID]([EPCISEventID] ASC, [BusinessTransactionIDID] ASC);

