CREATE TABLE [Event].[EPCISEvent_Vocabulary] (
    [ID]           BIGINT IDENTITY (1, 1) NOT NULL,
    [EPCISEventID] BIGINT NOT NULL,
    [VocabularyID] BIGINT NOT NULL,
    CONSTRAINT [PK_EPCISEvent_Vocabulary] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_EPCISEvent_EPCISEvent_Vocabulary] FOREIGN KEY ([EPCISEventID]) REFERENCES [Event].[EPCISEvent] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_Vocabulary_EPCISEvent_Vocabulary] FOREIGN KEY ([VocabularyID]) REFERENCES [Vocabulary].[Vocabulary] ([ID]),
    CONSTRAINT [AK_EPCISEvent_Vocabulary_EPCISEventID_VocabularyID] UNIQUE NONCLUSTERED ([EPCISEventID] ASC, [VocabularyID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_EPCISEventID]
    ON [Event].[EPCISEvent_Vocabulary]([EPCISEventID] ASC)
    INCLUDE([VocabularyID]);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_VocabularyID]
    ON [Event].[EPCISEvent_Vocabulary]([VocabularyID] ASC)
    INCLUDE([EPCISEventID]);

