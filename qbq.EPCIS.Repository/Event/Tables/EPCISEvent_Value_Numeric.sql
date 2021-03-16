CREATE TABLE [Event].[EPCISEvent_Value_Numeric] (
    [EPCISEvent_ValueID] BIGINT     NOT NULL,
    [Value]              FLOAT (53) NOT NULL,
    PRIMARY KEY CLUSTERED ([EPCISEvent_ValueID] ASC),
    CONSTRAINT [FK_EPCISEvent_Value_Numeric_EPCISEvent_Value] FOREIGN KEY ([EPCISEvent_ValueID]) REFERENCES [Event].[EPCISEvent_Value] ([ID]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_Value_Numeric_Value]
    ON [Event].[EPCISEvent_Value_Numeric]([Value] ASC);

