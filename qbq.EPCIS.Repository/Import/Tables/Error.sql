CREATE TABLE [Import].[Error] (
    [ErrorID]               BIGINT          IDENTITY (1, 1) NOT NULL,
    [TimeStampGeneration]   DATETIME        CONSTRAINT [DF_Error_TimeStampGeneration] DEFAULT (getdate()) NOT NULL,
    [AdditionalInformation] NVARCHAR (2048) CONSTRAINT [DF_Error_AdditionalInformation] DEFAULT ('no Information') NOT NULL,
    [ErrorNumber]           INT             CONSTRAINT [DF_Error_ErrorNumber] DEFAULT ((0)) NOT NULL,
    [ErrorSeverity]         INT             CONSTRAINT [DF_Error_ErrorSeverity] DEFAULT ((0)) NOT NULL,
    [ErrorProcedure]        NVARCHAR (126)  CONSTRAINT [DF_Error_ErrorProcedure] DEFAULT ('') NOT NULL,
    [ErrorMessage]          NVARCHAR (2048) CONSTRAINT [DF_Error_ErrorMessage] DEFAULT ('') NOT NULL,
    [ErrorLine]             INT             CONSTRAINT [DF_Error_ErrorLine] DEFAULT ((0)) NOT NULL,
    [ErrorState]            INT             CONSTRAINT [DF_Error_ErrorState] DEFAULT ((0)) NOT NULL,
    [ObjectID]              BIGINT          DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Error] PRIMARY KEY CLUSTERED ([ErrorID] ASC) WITH (FILLFACTOR = 80)
);

