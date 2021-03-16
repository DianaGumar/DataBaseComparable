-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 15.07.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE FUNCTION [Callback].[svf_Calc_Next_Run]
(
	@ScheduleID		 bigint,
	@ReferenceDate	 datetime2(0)
)
RETURNS DATETIME2(0)
AS
BEGIN

	-- Dateparts of Reference Date
	DECLARE
		@RefSecond		tinyint = CAST(DATEPART(ss, @ReferenceDate) as tinyint),
		@RefMinute		tinyint = CAST(DATEPART(mi, @ReferenceDate) as tinyint),
		@RefHour		tinyint = CAST(DATEPART(hh, @ReferenceDate) as tinyint),
		@RefDayOfMonth  tinyint = CAST(DATEPART(dd, @ReferenceDate) as tinyint),
		@RefMonth		tinyint = CAST(DATEPART(mm, @ReferenceDate) as tinyint),
		@RefWeekDay		tinyint = CAST(DATEPART(dw, @ReferenceDate) as tinyint),
		@RefYear        int     = CAST(DATEPART(yy, @ReferenceDate) as int),
		@MinSecond		tinyint,
		@MinMinute		tinyint,
		@MinHour		tinyint,
		@MinDayOfMonth  tinyint,
		@MinMonth		tinyint,
		@OutOfRange     bit = 0,
		@Carry          bit,
		@Second         tinyint,
		@Minute         tinyint,
		@Hour           tinyint,
		@DayOfMonth     tinyint,
		@NewDayOfMonth  tinyint,
		@Month          tinyint,
		@Year           int,
		@WeekDay        tinyint,
		@DateString     char(10),
		@Weekdaydate    datetime2(0),
		@ResultDate     datetime2(0);

	--***************************************************************
	-- Schedule-Werte ermitteln
	--***************************************************************

	-- Sekunden
	SET @Carry		= 1;	-- Sonst keine Weiterschaltung der Werte
	SELECT TOP 1 
		@Second = Value, @Carry = Carry, @MinSecond = MinValue, @OutOfRange = OutOfRange
	FROM [Callback].[tvf_get_Next_Time] (@ScheduleID, 'ss', @Carry, @RefSecond);

	-- Minuten
	SELECT TOP 1 
		@Minute = Value, @Carry = Carry, @MinMinute = MinValue, @OutOfRange = OutOfRange
	FROM [Callback].[tvf_get_Next_Time] (@ScheduleID, 'mi', @Carry, @RefMinute);

	IF @OutOfRange = 1
	BEGIN
		SET @Second = @MinSecond;
	END;

	-- Stunden
	SELECT TOP 1 
		@Hour = Value, @Carry = Carry, @MinHour = MinValue, @OutOfRange = OutOfRange
	FROM [Callback].[tvf_get_Next_Time] (@ScheduleID, 'hh', @Carry, @RefHour);

	IF @OutOfRange = 1
	BEGIN
		SET @Second = @MinSecond;SET @Minute = @MinMinute;
	END;

	-- Tag
	SELECT TOP 1 
		@DayOfMonth = Value, @Carry = Carry, @MinDayOfMonth = MinValue, @OutOfRange = OutOfRange
	FROM [Callback].[tvf_get_Next_Time] (@ScheduleID, 'dd', @Carry, @RefDayOfMonth);
	
	SET @DayOfMonth = [Callback].[svf_Check_Month_Day] (@DayOfMonth, @RefMonth, @RefYear);
	
	IF @DayOfMonth < @RefDayOfMonth 
	BEGIN
		SET @DayOfMonth = @MinDayOfMonth;
		SET @Carry = 1;
	END;

	IF @OutOfRange = 1
	BEGIN
		SET @Second = @MinSecond;SET @Minute = @MinMinute;SET @Hour = @MinHour;
	END;

	-- Monat
	SELECT TOP 1 
		@Month = Value, @Carry = Carry, @MinMonth = MinValue, @OutOfRange = OutOfRange
	FROM [Callback].[tvf_get_Next_Time]  (@ScheduleID, 'mm', @Carry, @RefMonth);

	IF @OutOfRange = 1
	BEGIN
		SET @Second = @MinSecond;SET @Minute = @MinMinute;SET @Hour = @MinHour;SET @DayOfMonth = @MinDayOfMonth;
	END;

	-- Jahr 
	IF @Carry = 1
	BEGIN
		SET @Year = @RefYear + 1;
	END
	ELSE
	BEGIN
		SET @Year = @RefYear;
	END;

	-- Nochmalige Prüfung des Tages
	SET @NewDayOfMonth = [Callback].[svf_Check_Month_Day] (@DayOfMonth, @Month, @Year);

	IF @NewDayOfMonth <> @DayOfMonth
	BEGIN
		-- Auf letzten gültigen Tag zurückrechnen und svf_Calc_Next_Run aufrufen.
		SET @DateString = CAST(@Year as char(4)) + '-' + CAST(@Month as char(2))+ '-' + CAST(@DayOfMonth as char(2));
		WHILE ISDATE(@DateString) = 0
		BEGIN
			SET @DayOfMonth = @DayOfMonth - 1;
			SET @DateString = CAST(@Year as char(4)) + '-' + CAST(@Month as char(2))+ '-' + CAST(@DayOfMonth as char(2));
		END;

		-- Recursion
		SET @ResultDate = DATETIME2FROMPARTS ( @Year, @Month, @DayOfMonth, @Hour, @Minute, @Second, 0, 0 );
		SET @ResultDate = [Callback].[svf_Calc_Next_Run] ( @ScheduleID, @ResultDate );
	END
	ELSE
	BEGIN

		-- Ergebnis berechnen
		SET @ResultDate = DATETIME2FROMPARTS ( @Year, @Month, @DayOfMonth, @Hour, @Minute, @Second, 0, 0 );

	END;


	-- Wenn Wochentag Einschränkung vorhanden
	IF exists (
			SELECT 
				1
			FROM [Callback].[Schedule_Part]
			WHERE [DatePart] = 'dw' and [ScheduleID] = @ScheduleID
		)
	BEGIN
		-- Wochentag prüfen
		SET @WeekDay = CAST(DATEPART(dw, @ResultDate) as tinyint);
		SET @Weekdaydate = @ResultDate;

		-- Auf nächsten gültigen Wochentag iterieren
		WHILE not exists (
			SELECT 
				1
			FROM [Callback].[Schedule_Part]
			WHERE [DatePart] = 'dw' and [Value] = @WeekDay and [ScheduleID] = @ScheduleID
		) 
		BEGIN
			SET @Weekdaydate = DATEADD(dd, 1, @Weekdaydate);
			SET @WeekDay    = CAST(DATEPART(dw, @Weekdaydate) as tinyint);
		END;

		-- Wenn Weekaydate und ResultDate sich unterscheiden dann auf Vortag 23:59:59 gehen und nächstes Zeitinterval berechnen
		IF @Weekdaydate <> @ResultDate
		BEGIN
			SET @Month      = CAST(DATEPART(mm, @Weekdaydate) as tinyint);
			SET @DayOfMonth = CAST(DATEPART(dd, @Weekdaydate) as tinyint);
			SET @ResultDate = DATETIME2FROMPARTS ( @Year, @Month, @DayOfMonth, 0, 0, 0, 0, 0 );
			SET @ResultDate = DATEADD(ss, -1, @ResultDate);
			SET @ResultDate = [Callback].[svf_Calc_Next_Run] ( @ScheduleID, @ResultDate );
		END;
	END;

	RETURN @ResultDate;
END;