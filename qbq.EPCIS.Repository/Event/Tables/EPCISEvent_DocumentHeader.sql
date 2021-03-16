CREATE TABLE [Event].[EPCISEvent_DocumentHeader] (
    [ID]               BIGINT IDENTITY (1, 1) NOT NULL,
    [EPCISEventID]     BIGINT NOT NULL,
    [DocumentHeaderID] BIGINT NOT NULL,
    CONSTRAINT [PK_EPCISEvent_DocumentHeader] PRIMARY KEY CLUSTERED ([ID]),
    CONSTRAINT [FK_EPCISDocumentHeader_EPCISEvent_DocumentHeader] FOREIGN KEY ([DocumentHeaderID]) REFERENCES [DocumentHeader].[EPCISDocumentHeader] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_EPCISEvent_EPCISEvent_DocumentHeader] FOREIGN KEY ([EPCISEventID]) REFERENCES [Event].[EPCISEvent] ([ID]) ON DELETE CASCADE
);

