CREATE TABLE [Vocabulary].[Vocabulary] (
    [ID]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [ClientID]         BIGINT         NOT NULL,
    [VocabularyTypeID] BIGINT         NOT NULL,
    [URN]              NVARCHAR (512) NOT NULL,
    [Deleted]          BIT            CONSTRAINT [DF_Vocabulary_DELETED] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Vocabulary] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Vocabulary_Vocabulary] FOREIGN KEY ([ClientID]) REFERENCES [Vocabulary].[Vocabulary] ([ID]),
    CONSTRAINT [FK_VocabularyType_Vocabulary] FOREIGN KEY ([VocabularyTypeID]) REFERENCES [Vocabulary].[VocabularyType] ([ID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Vocabulary]
    ON [Vocabulary].[Vocabulary]([URN] ASC, [VocabularyTypeID] ASC, [ClientID] ASC);

