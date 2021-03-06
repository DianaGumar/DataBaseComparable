CREATE TABLE [Analysis].[Time] (
    [PK_Date]               DATE          NOT NULL,
    [Date_Name]             NVARCHAR (50) NULL,
    [Year]                  DATETIME      NULL,
    [Year_Name]             NVARCHAR (50) NULL,
    [Half_Year]             DATETIME      NULL,
    [Half_Year_Name]        NVARCHAR (50) NULL,
    [Quarter]               DATETIME      NULL,
    [Quarter_Name]          NVARCHAR (50) NULL,
    [Month]                 DATETIME      NULL,
    [Month_Name]            NVARCHAR (50) NULL,
    [Week]                  DATETIME      NULL,
    [Week_Name]             NVARCHAR (50) NULL,
    [Day_Of_Year]           INT           NULL,
    [Day_Of_Year_Name]      NVARCHAR (50) NULL,
    [Day_Of_Half_Year]      INT           NULL,
    [Day_Of_Half_Year_Name] NVARCHAR (50) NULL,
    [Day_Of_Quarter]        INT           NULL,
    [Day_Of_Quarter_Name]   NVARCHAR (50) NULL,
    [Day_Of_Month]          INT           NULL,
    [Day_Of_Month_Name]     NVARCHAR (50) NULL,
    [Day_Of_Week]           INT           NULL,
    [Day_Of_Week_Name]      NVARCHAR (50) NULL,
    [Week_Of_Year]          INT           NULL,
    [Month_Of_Year]         INT           NULL,
    [Month_Of_Half_Year]    INT           NULL,
    [Month_Of_Quarter]      INT           NULL,
    [Quarter_Of_Year]       INT           NULL,
    [Quarter_Of_Half_Year]  INT           NULL,
    [Half_Year_Of_Year]     INT           NULL,
    CONSTRAINT [PK_Analysis_Time] PRIMARY KEY CLUSTERED ([PK_Date] ASC)
);

