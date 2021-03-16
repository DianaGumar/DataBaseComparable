CREATE TABLE [Event].[EPCISEvent_Value_String] (
    [ID]                 BIGINT IDENTITY (1, 1) NOT NULL,
    [EPCISEvent_ValueID] BIGINT NOT NULL,
    [Value_StringID]     BIGINT NOT NULL,
    CONSTRAINT [PK_EPCISEvent_Value_String] PRIMARY KEY CLUSTERED ([ID]),
    CONSTRAINT [FK_EPCISEvent_Value_String_EPCISEvent_Value] FOREIGN KEY ([EPCISEvent_ValueID]) REFERENCES [Event].[EPCISEvent_Value] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_EPCISEvent_Value_String_String_Value] FOREIGN KEY ([Value_StringID]) REFERENCES [Event].[Value_String] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_Value_String]
    ON [Event].[EPCISEvent_Value_String]([Value_StringID] ASC)
    INCLUDE([EPCISEvent_ValueID]);

