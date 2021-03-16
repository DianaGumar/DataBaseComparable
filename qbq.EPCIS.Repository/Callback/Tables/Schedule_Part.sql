CREATE TABLE [Callback].[Schedule_Part] (
    [ScheduleID] BIGINT   NOT NULL,
    [DatePart]   CHAR (2) NOT NULL,
    [Value]      TINYINT  NOT NULL,
    CONSTRAINT [PK_Schedule_Part] PRIMARY KEY CLUSTERED ([ScheduleID] ASC, [DatePart] ASC, [Value] ASC),
    CONSTRAINT [CK_Schedule_Part] CHECK ([Callback].[svf_Check_Schedule_Part]([DatePart],[Value])=(1)),
    CONSTRAINT [FK_Schedule_Part_ToSchedule] FOREIGN KEY ([ScheduleID]) REFERENCES [Callback].[Schedule] ([ID]) ON DELETE CASCADE
);

