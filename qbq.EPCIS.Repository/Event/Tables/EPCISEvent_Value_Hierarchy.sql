CREATE TABLE [Event].[EPCISEvent_Value_Hierarchy] (
    [ID]                        BIGINT IDENTITY (1, 1) NOT NULL,
    [EPCISEvent_ValueID]        BIGINT NOT NULL,
    [Parent_EPCISEvent_ValueID] BIGINT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID]),
    CONSTRAINT [FK_EPCISEvent_Value_Hierarchy_EPCISEvent_Value] FOREIGN KEY ([EPCISEvent_ValueID]) REFERENCES [Event].[EPCISEvent_Value] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_EPCISEvent_Value_Hierarchy_Parent_EPCISEvent_Value] FOREIGN KEY ([Parent_EPCISEvent_ValueID]) REFERENCES [Event].[EPCISEvent_Value] ([ID])
);

