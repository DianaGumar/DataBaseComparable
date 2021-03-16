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
CREATE FUNCTION [Callback].[tvf_get_Next_Time]
(
	@ScheduleID  bigint,
	@DatePart    char(2),
	@Carry       bit,
	@RefValue    tinyint
)
RETURNS @retTable TABLE
(
	Value      tinyint,
	Carry      bit,
	MinValue   tinyint,
	OutOfRange bit
)
AS
BEGIN
	DECLARE 
		@Value		   tinyint,
		@TotalMinValue tinyint,
		@NewCarry	   bit,
		@ValidValue    bit = 0;

	SET @NewCarry = 0;

	-- check if a value exists in Shedule_Part for DatePart
	-- if yes then calculate by existing Schedule_Part values
	-- if no then +1 if Carry=1
	SELECT 
		@TotalMinValue = min([Value])
	FROM [Callback].[Schedule_Part]
	WHERE [DatePart] = @DatePart and [ScheduleID] = @ScheduleID;

	-- Proof if Value is Valid
	IF @TotalMinValue is null or exists (
								SELECT 
									TOP 1 1
								FROM [Callback].[Schedule_Part]
								WHERE [DatePart] = @DatePart and [Value] = @RefValue and [ScheduleID] = @ScheduleID)
	BEGIN
		SET @ValidValue = 1;
	END;

	IF @TotalMinValue is null and @Carry = 1
	BEGIN
		-- + 1 (with Overflow)
		SET @Value = [Callback].[svf_Get_Next_DatePart_Value] (@DatePart, @RefValue)		
				
		IF @Value < @RefValue
			SET @NewCarry = 1;
	END
	ELSE IF @Carry = 1
	BEGIN
		-- check if we are at starting position
		IF @TotalMinValue > @RefValue
		BEGIN
			SET @Value = @TotalMinValue;
		END
		ELSE
		BEGIN
			-- get smallest but greater than current value (next value)
			SELECT 
				@Value = min([Value])
			FROM [Callback].[Schedule_Part]
			WHERE [DatePart] = @DatePart and [Value] > @RefValue and [ScheduleID] = @ScheduleID;

			-- if this doesn't exist there is only one value next time interval
			IF @Value IS NULL
			BEGIN
				SET @Value = @TotalMinValue;
				SET @NewCarry = 1;
			END
			ELSE
			BEGIN
				SET @NewCarry = 0;
			END;
		END;
	END
	ELSE IF @Carry = 0
	BEGIN
		-- 
		IF @ValidValue = 0
		BEGIN
			-- get smallest but greater than current value (next value)
			SELECT 
				@Value = min([Value])
			FROM [Callback].[Schedule_Part]
			WHERE [DatePart] = @DatePart and [Value] > @RefValue and [ScheduleID] = @ScheduleID;

			IF @Value IS NULL
			BEGIN
				SET @Value = @TotalMinValue;
			END;

			IF @Value < @RefValue
			BEGIN
				SET @NewCarry = 1;
			END
			ELSE
			BEGIN
				SET @NewCarry = 0;
			END;
		END
		ELSE
		BEGIN
			SET @Value = @RefValue;
		END;
	END;
	
	-- MinValue berechnen
	IF @TotalMinValue is null 
	BEGIN
		IF @DatePart in ('ss', 'mi', 'hh')
			SET @TotalMinValue = 0;
		IF @DatePart in ('dd', 'mm', 'dw')
			SET @TotalMinValue = 1;
	END;

	INSERT @retTable (Value, Carry, MinValue, OutOfRange) VALUES(@Value, @NewCarry, @TotalMinValue, ~@ValidValue);

	RETURN;
END;