CREATE TABLE [Event].[BusinessTransactionID] (
    [ID]                        BIGINT         IDENTITY (1, 1) NOT NULL,
    [URN]                       NVARCHAR (512) NOT NULL,
    [BusinessTransactionTypeID] BIGINT         NOT NULL,
    CONSTRAINT [PK_BusinessTransactionID] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Vocabulary_BusinessTransactionID] FOREIGN KEY ([BusinessTransactionTypeID]) REFERENCES [Vocabulary].[Vocabulary] ([ID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_BusinessTransactionID]
    ON [Event].[BusinessTransactionID]([URN] ASC, [BusinessTransactionTypeID] ASC);

