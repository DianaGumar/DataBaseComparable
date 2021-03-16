CREATE TABLE [Vocabulary].[VocabularyType] (
    [ID]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [URN]         NVARCHAR (512) NOT NULL,
    [Description] NVARCHAR (50)  NOT NULL,
    [MaxOccurs]   INT            NOT NULL,
    CONSTRAINT [PK_VocabularyType] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_VocabularyType]
    ON [Vocabulary].[VocabularyType]([URN] ASC);

