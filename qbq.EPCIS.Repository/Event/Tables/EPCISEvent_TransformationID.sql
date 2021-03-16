CREATE TABLE [Event].[EPCISEvent_TransformationID] (
    [ID]                 BIGINT IDENTITY (1, 1) NOT NULL,
    [EPCISEventID]       BIGINT NOT NULL,
    [TransformationIDID] BIGINT NOT NULL,
    CONSTRAINT [PK_EPCISEvent_TransformationID] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Event_EPCISEvent_TransformationID] FOREIGN KEY ([EPCISEventID]) REFERENCES [Event].[EPCISEvent] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_TransformationID_EPCISEvent_TransformationID] FOREIGN KEY ([TransformationIDID]) REFERENCES [Event].[TransformationID] ([ID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_EPCISEvent_TransformationID]
    ON [Event].[EPCISEvent_TransformationID]([EPCISEventID] ASC, [TransformationIDID] ASC);

