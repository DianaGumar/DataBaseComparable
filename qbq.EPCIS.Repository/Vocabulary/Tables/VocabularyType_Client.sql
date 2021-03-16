CREATE TABLE [Vocabulary].[VocabularyType_Client] (
    [ClientID]         BIGINT NOT NULL,
    [VocabularyTypeID] BIGINT NOT NULL,
    [Deleted]          BIT    CONSTRAINT [DF_VocabularyType_Client_DELETED] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VocabularyType_Client] PRIMARY KEY CLUSTERED ([ClientID] ASC, [VocabularyTypeID] ASC),
    CONSTRAINT [FK_VocabularyType_Client_Vocabulary] FOREIGN KEY ([ClientID]) REFERENCES [Vocabulary].[Vocabulary] ([ID]),
    CONSTRAINT [FK_VocabularyType_Client_VocabularyClient] FOREIGN KEY ([VocabularyTypeID]) REFERENCES [Vocabulary].[VocabularyType] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_VocabularyType_Client]
    ON [Vocabulary].[VocabularyType_Client]([VocabularyTypeID] ASC)
    INCLUDE([ClientID]);

