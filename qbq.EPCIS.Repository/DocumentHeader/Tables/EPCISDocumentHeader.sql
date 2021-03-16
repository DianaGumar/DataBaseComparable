CREATE TABLE [DocumentHeader].[EPCISDocumentHeader] (
    [ID]                  BIGINT    IDENTITY (1, 1) NOT NULL,
    [HeaderVersion]       CHAR (10) NOT NULL,
    [EPCISDocumentHeader] XML       NOT NULL,
    CONSTRAINT [PK_EPCISDocumentHeader] PRIMARY KEY CLUSTERED ([ID] ASC)
);

