CREATE TABLE [Callback].[Schedule] (
    [ID]             BIGINT        IDENTITY (1, 1) NOT NULL,
    [SubscriptionID] BIGINT        NOT NULL,
    [NextRun]        DATETIME2 (0) DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Schedule_ToSubscription] FOREIGN KEY ([SubscriptionID]) REFERENCES [Callback].[Subscription] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [AK_Schedule_Subscription_ID] UNIQUE NONCLUSTERED ([SubscriptionID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Schedule_NextRun]
    ON [Callback].[Schedule]([SubscriptionID] ASC, [NextRun] ASC);

