CREATE TABLE [Vocabulary].[VocabularyChildren] (
    [ID]                BIGINT IDENTITY (1, 1) NOT NULL,
    [VocabularyID]      BIGINT NOT NULL,
    [ChildVocabularyID] BIGINT NOT NULL,
    [Deleted]           BIT    CONSTRAINT [DF_VocabularyChildren_DELETED] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VocabularyChildren] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Vocabulary_VocabularyChildren] FOREIGN KEY ([VocabularyID]) REFERENCES [Vocabulary].[Vocabulary] ([ID]),
    CONSTRAINT [FK_Vocabulary_VocabularyChildren_Child] FOREIGN KEY ([ChildVocabularyID]) REFERENCES [Vocabulary].[Vocabulary] ([ID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_VocabularyChildren]
    ON [Vocabulary].[VocabularyChildren]([VocabularyID] ASC, [ChildVocabularyID] ASC);

