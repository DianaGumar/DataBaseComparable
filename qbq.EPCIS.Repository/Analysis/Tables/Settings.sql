CREATE TABLE [Analysis].[Settings] (
    [ID]       NVARCHAR (50)  NOT NULL,
    [Value]    NVARCHAR (500) NOT NULL,
    [ClientID] BIGINT         NOT NULL,
    CONSTRAINT [PK_Analysis_Settings] PRIMARY KEY CLUSTERED ([ID] ASC, [ClientID] ASC),
    CONSTRAINT [FK_Vocabulary_Analysis_Settings_ClientID] FOREIGN KEY ([ClientID]) REFERENCES [Vocabulary].[Vocabulary] ([ID])
);

