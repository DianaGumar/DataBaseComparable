CREATE TABLE [Event].[EPCISEvent_QuantityElement] (
    [ID]                BIGINT IDENTITY (1, 1) NOT NULL,
    [EPCISEventID]      BIGINT NOT NULL,
    [IsInput]           BIT    NOT NULL,
    [IsOutput]          BIT    NOT NULL,
    [QuantityElementID] BIGINT NOT NULL,
    CONSTRAINT [PK_EPCISEvent_QuantityElement] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_EPCISEvent_EPCISEvent_QuantityElement] FOREIGN KEY ([EPCISEventID]) REFERENCES [Event].[EPCISEvent] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_QuantityElement_EPCISEvent_QuantityElement] FOREIGN KEY ([QuantityElementID]) REFERENCES [Event].[QuantityElement] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_QuantityElement]
    ON [Event].[EPCISEvent_QuantityElement]([EPCISEventID] ASC, [QuantityElementID] ASC)
    INCLUDE([IsInput]);

