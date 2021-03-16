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
-- 05.09.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Helper].[usp_Proof_Duplicates]
	@ShowDuplicates   bit = 1,
	@DeleteDuplicates bit = 0,
	@RecordTimeFrom   datetime2(0) = NULL,
	@RecordTimeUntil  datetime2(0) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRANSACTION;

	IF @RecordTimeFrom  is null SET @RecordTimeFrom  = CAST(N'0001-01-01 00:00:00' as datetime2(0));
	IF @RecordTimeUntil is null SET @RecordTimeUntil = CAST(N'9999-12-31 23:59:59' as datetime2(0));

	-- Ermittle alle Doppler
	select
		ev.ID,
		ev.EventTime,
		ev.RecordTime,
		CASE @ShowDuplicates
			WHEN 0 THEN N'<e/>'
			WHEN 1 THEN ev.XmlRepresentation
		END as XmlRepresentation,
		Checksu
	into #tempEPCIS
	from Event.EPCISEvent ev
	join
	(
		select
			EventTime,
			Checksu
		from
		(	select 
				EventTime, 
				CHECKSUM (CAST (XmlRepresentation as VARBINARY(MAX))) as Checksu
			from Event.EPCISEvent
			where RecordTime between @RecordTimeFrom and @RecordTimeUntil
		) as re		
		group by EventTime, Checksu
		having count(*) > 1
	) as re 
	on		re.EventTime = ev.EventTime 
		and re.Checksu   = CHECKSUM (CAST (ev.XmlRepresentation as VARBINARY(MAX)))
	where ev.RecordTime between @RecordTimeFrom and @RecordTimeUntil;

	-- Zeige alle Doppler an
	IF @ShowDuplicates = 1
	BEGIN
		select 
			 ID
			,EventTime
			,RecordTime
			,XmlRepresentation
		from #tempEPCIS;
	END;

	-- Loesche jüngsten Eintrag
	delete #tempEPCIS
	from #tempEPCIS ts
	join (
		select 
			min(RecordTime) as RecordTime,
			EventTime,
			Checksu
		from #tempEPCIS
			group by EventTime, Checksu
		) as valid on valid.EventTime = ts.EventTime and valid.Checksu = ts.Checksu and valid.RecordTime = ts.RecordTime;


	-- Restliche Events sind doppler und können gelöscht werden
	IF @DeleteDuplicates = 1 
	BEGIN
		delete Event.EPCISEvent
		from Event.EPCISEvent e
		join #tempEPCIS te on te.ID = e.ID;
	END;

	-- CLEANUP
	drop table #tempEPCIS;

	COMMIT TRANSACTION;

END;