CREATE TABLE [Event].[EPCISEvent_SourceDestination] (
    [ID]                      BIGINT IDENTITY (1, 1) NOT NULL,
    [IsSource]                BIT    NOT NULL,
    [EPCISEventID]            BIGINT NOT NULL,
    [SourceDestinationID]     BIGINT NOT NULL,
    [SourceDestinationTypeID] BIGINT NOT NULL,
    CONSTRAINT [PK_EPCISEvent_SourceDestination] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_EPCISEvent_EPCISEvent_SourceDestination] FOREIGN KEY ([EPCISEventID]) REFERENCES [Event].[EPCISEvent] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_SourceDestinationID_EPCISEvent_SourceDestination] FOREIGN KEY ([SourceDestinationID]) REFERENCES [Vocabulary].[Vocabulary] ([ID]),
    CONSTRAINT [FK_SourceDestinationTypeID_EPCISEvent_SourceDestination] FOREIGN KEY ([SourceDestinationTypeID]) REFERENCES [Vocabulary].[Vocabulary] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_SourceDestination]
    ON [Event].[EPCISEvent_SourceDestination]([EPCISEventID] ASC, [SourceDestinationID] ASC, [SourceDestinationTypeID] ASC)
    INCLUDE([IsSource]);

