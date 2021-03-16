CREATE TABLE [Event].[QuantityElement] (
    [ID]         BIGINT     IDENTITY (1, 1) NOT NULL,
    [EPCClassID] BIGINT     NOT NULL,
    [Quantity]   FLOAT (53) NOT NULL,
    [UOM]        NCHAR (3)  NOT NULL,
    CONSTRAINT [PK_QuantityElement] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_VocabularyElement_QuantityElement] FOREIGN KEY ([EPCClassID]) REFERENCES [Vocabulary].[Vocabulary] ([ID]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_QuantityElement]
    ON [Event].[QuantityElement]([EPCClassID] ASC, [Quantity] ASC, [UOM] ASC);

