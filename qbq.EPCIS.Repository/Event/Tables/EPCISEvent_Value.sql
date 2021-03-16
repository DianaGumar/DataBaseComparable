CREATE TABLE [Event].[EPCISEvent_Value] (
    [ID]           BIGINT IDENTITY (1, 1) NOT NULL,
    [EPCISEventID] BIGINT NOT NULL,
    [ValueTypeID]  BIGINT NOT NULL,
    [DataTypeID]   BIGINT NOT NULL,
    CONSTRAINT [PK_EPCISEvent_Value] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_EPCISEvent_EPCISEvent_Value_EPCISEvent_ID] FOREIGN KEY ([EPCISEventID]) REFERENCES [Event].[EPCISEvent] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_Vocabulary_EPCISEvent_Value_DataType] FOREIGN KEY ([DataTypeID]) REFERENCES [Vocabulary].[Vocabulary] ([ID]),
    CONSTRAINT [FK_Vocabulary_EPCISEvent_Value_ValueType] FOREIGN KEY ([ValueTypeID]) REFERENCES [Vocabulary].[Vocabulary] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_DataTypeID]
    ON [Event].[EPCISEvent_Value]([DataTypeID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_EPCISEventID]
    ON [Event].[EPCISEvent_Value]([EPCISEventID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_ValueTypeID]
    ON [Event].[EPCISEvent_Value]([ValueTypeID] ASC)
    INCLUDE([DataTypeID]);

