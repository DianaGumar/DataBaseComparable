CREATE TABLE [Callback].[Subscription] (
    [ID]                  BIGINT         IDENTITY (1, 1) NOT NULL,
    [ClientID]            BIGINT         NOT NULL,
    [Username]            NVARCHAR (512) NOT NULL,
    [Subscription]        NVARCHAR (512) NOT NULL,
    [Query]               XML            NOT NULL,
    [DestinationEndpoint] NVARCHAR (512) NOT NULL,
    [InitialRecordTime]   DATETIME2 (0)  NOT NULL,
    [LastRecordTime]      DATETIME2 (0)  NOT NULL,
    [ReportIfEmpty]       BIT            NOT NULL,
    [Active]              BIT            CONSTRAINT [DF_Subscription_Active] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Subscription] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Subscription_Vocabulary] FOREIGN KEY ([ClientID]) REFERENCES [Vocabulary].[Vocabulary] ([ID]),
    CONSTRAINT [AK_Subscription_Subscription] UNIQUE NONCLUSTERED ([Subscription] ASC)
);

