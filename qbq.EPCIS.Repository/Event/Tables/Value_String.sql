CREATE TABLE [Event].[Value_String] (
    [ID]    BIGINT          IDENTITY (1, 1) NOT NULL,
    [Value] NVARCHAR (1024) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Value_String_Value]
    ON [Event].[Value_String]([Value] ASC);

