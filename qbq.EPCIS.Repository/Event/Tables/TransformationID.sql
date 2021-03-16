CREATE TABLE [Event].[TransformationID] (
    [ID]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [URN] NVARCHAR (512) NOT NULL,
    CONSTRAINT [PK_TransformationID] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_TransformationID]
    ON [Event].[TransformationID]([URN] ASC);

