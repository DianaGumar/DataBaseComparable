CREATE TABLE [Callback].[Subscription_Trigger] (
    [SubscriptionID] BIGINT NOT NULL,
    [TriggerID]      BIGINT NOT NULL,
    CONSTRAINT [PK_Subscription_Trigger] PRIMARY KEY CLUSTERED ([SubscriptionID] ASC, [TriggerID] ASC),
    CONSTRAINT [FK_Subscription_Trigger_ToSubscription] FOREIGN KEY ([SubscriptionID]) REFERENCES [Callback].[Subscription] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_Subscription_Trigger_ToTrigger] FOREIGN KEY ([TriggerID]) REFERENCES [Callback].[Trigger] ([ID])
);

