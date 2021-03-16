CREATE TABLE [Event].[EPCISEvent_Value_Datetime] (
    [EPCISEvent_ValueID] BIGINT             NOT NULL,
    [Value]              DATETIMEOFFSET (7) NOT NULL,
    PRIMARY KEY CLUSTERED ([EPCISEvent_ValueID] ASC),
    CONSTRAINT [FK_EPCISEvent_Value_Datetime_EPCISEvent_Value] FOREIGN KEY ([EPCISEvent_ValueID]) REFERENCES [Event].[EPCISEvent_Value] ([ID]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_Value_Datetime_Value]
    ON [Event].[EPCISEvent_Value_Datetime]([Value] ASC);

