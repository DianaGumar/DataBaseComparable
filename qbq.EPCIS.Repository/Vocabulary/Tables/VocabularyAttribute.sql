CREATE TABLE [Vocabulary].[VocabularyAttribute] (
    [ID]              BIGINT IDENTITY (1, 1) NOT NULL,
    [VocabularyID]    BIGINT NOT NULL,
    [AttributeTypeID] BIGINT NOT NULL,
    [Value]           XML    NOT NULL,
    [Deleted]         BIT    CONSTRAINT [DF_VocabularyAttribute_DELETED] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VocabularyAttribute] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_AttributeType_VocabularyAttribute] FOREIGN KEY ([AttributeTypeID]) REFERENCES [Vocabulary].[AttributeType] ([ID]),
    CONSTRAINT [FK_Vocabulary_VocabularyAttribute] FOREIGN KEY ([VocabularyID]) REFERENCES [Vocabulary].[Vocabulary] ([ID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_VocabularyAttribute]
    ON [Vocabulary].[VocabularyAttribute]([VocabularyID] ASC, [AttributeTypeID] ASC);

