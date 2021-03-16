CREATE TABLE [Vocabulary].[AttributeType] (
    [ID]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [URN]           NVARCHAR (512) NOT NULL,
    [Description]   NVARCHAR (50)  NOT NULL,
    [ContentTypeID] BIGINT         NOT NULL,
    CONSTRAINT [PK_AttributeType] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_ContentType_Vocabulary] FOREIGN KEY ([ContentTypeID]) REFERENCES [Vocabulary].[Vocabulary] ([ID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_AttributeType_URN]
    ON [Vocabulary].[AttributeType]([URN] ASC);

