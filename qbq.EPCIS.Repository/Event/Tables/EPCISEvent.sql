CREATE TABLE [Event].[EPCISEvent] (
    [ID]                  BIGINT             IDENTITY (1, 1) NOT NULL,
    [ClientID]            BIGINT             NOT NULL,
    [EventTime]           DATETIME2 (0)      NOT NULL,
    [RecordTime]          DATETIME2 (0)      NOT NULL,
    [EventTimeZoneOffset] DATETIMEOFFSET (7) NOT NULL,
    [XmlRepresentation]   XML                NOT NULL,
    [Error]               BIT                CONSTRAINT [DF_EPCISEvent_Error] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EPCISEvent] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Vocabulary_EPCISEvent] FOREIGN KEY ([ClientID]) REFERENCES [Vocabulary].[Vocabulary] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_ClientID]
    ON [Event].[EPCISEvent]([ClientID] ASC)
    INCLUDE([ID]);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_EventTime]
    ON [Event].[EPCISEvent]([EventTime] ASC)
    INCLUDE([ID], [ClientID], [RecordTime]);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_RecordTime]
    ON [Event].[EPCISEvent]([RecordTime] ASC)
    INCLUDE([ID], [ClientID], [EventTime]);


GO
CREATE NONCLUSTERED INDEX [IX_EPCISEvent_EventTimeZoneOffset]
    ON [Event].[EPCISEvent]([EventTimeZoneOffset] ASC)
    INCLUDE([ID], [ClientID], [RecordTime]);

