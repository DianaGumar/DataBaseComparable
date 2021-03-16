
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Helper].[usp_ManualCleanUp_Repository]
	-- Add the parameters for the stored procedure here
	@DaysToKeep INT = 30
	,@BatchSize INT = 50
	,@DebugMode bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-----------------------------------------------------------------------------------------
	-- Projekt:  EPCIS (CleanUp Repository Procedure)
	-- Firma:    QUIBIQ
	-- (c) 2016  QUIBIQ Schweiz AG
	-----------------------------------------------------------------------------------------
	--
	-- 
	-- 
	-- Datum      | Version | Autor               | Kommentar
	--------------|---------|---------------------|------------------------------------------
	-- 25.04.2016 | 1.1.0.0 | Andreas Conrad      | Erstellt.
	--------------|---------|---------------------|------------------------------------------
	-- 08.07.2019 | 1.2.0.0 | Stephan Kelso       | Alle Events älter als 30 Tage werden
	--            |         |                     | gelöscht.
	-----------------------------------------------------------------------------------------

	DECLARE @msg VARCHAR(1000)
	DECLARE @delcount INT
	DECLARE @epcCount int
	-- Zeitraum ältesten Eintragag bis heute minus @DaysToKeep Tage
	DECLARE @FromTimeStamp DATETIME2 = (
			SELECT ISNULL(max(RecordTime), N'1900-01-01')
			FROM [Event].[EPCISEvent] WITH (READUNCOMMITTED)
			)
	-- Zeitraum zum aufräumen: alle Events die älter als heute minus @DaysToKeep Tage sind
	DECLARE @ToTimeStamp DATETIME2

	SET @ToTimeStamp = DATEADD(day, - 1 * @DaysToKeep, GETDATE())

	-- Ermitteln der zu löschenden Events und Ausgabe als Information im Windows Eventlog
	SET @delcount = (
			SELECT count(*)
			FROM [Event].[EPCISEvent] WITH (READUNCOMMITTED)
			WHERE RecordTime <= @ToTimeStamp
			)

	SET @msg = 'Events to delete: ' + ltrim(convert(VARCHAR, @delcount))

	--EXEC xp_logevent 51000
	--	,@msg
	--	,informational;

------------------------ Temporäre EPC-Tabelle füllen

			IF OBJECT_ID('tempdb..#TempEEPC','U') is not null
				Drop Table #TempEEPC

			select distinct eepc.EPCID , eepc.EPCISEventID
			into #TempEEPC
			from [Event].EPCISEvent_EPC eepc WITH (READUNCOMMITTED)
			inner join 
				(
					select *
					FROM [Event].[EPCISEvent] WITH (READUNCOMMITTED)
					WHERE RecordTime <= @ToTimeStamp
				) e
			on eepc.EPCISEventID = e.ID
			
		
			set @epcCount= (
				select count(*)
				from Event.EPC epc WITH (READUNCOMMITTED)
				inner join #TempEEPC eepc
				on epc.ID = eepc.EPCID
			)

		SELECT @FromTimeStamp AS 'From'
			,@ToTimeStamp AS 'To'
			,DATEDIFF(day,@FromTimeStamp,@ToTimeStamp) as Days
			,@delcount as Events
			,@epcCount as EPCCount

			select * from #TempEEPC

---------------------
--------------------- Vorbereitung Debug Mode
	IF OBJECT_ID('tempdb..#DebugInfo','U') is not null
		Drop Table #DebugInfo

	create Table #DebugInfo
		(
			Object varchar(50)
			,Rows int
		)
	Insert into #DebugInfo Values('Start CleanUp',0) 
-----------------------------------------------

	-- Batchgröße: Anzahl Zeilen (ab 5000 verhängt die Databaseengine eine exklusive Tabellensperre über alle beteiligten Tabellen,
	--                            was zu einer DeadLock-Situation mit anderen Prozessen führen kann)
	-- wird vor jeder Schleife gesetzt 
	DECLARE @rc INT = @BatchSize

	WHILE @rc > 0
	BEGIN
		-- Bei Fehler -> Abbruch des gesamten Vorgangs
		BEGIN TRY
			BEGIN TRAN

			-- der Tabellenhinweis WITH (ROWLOCK) empfiehlt der Databaseengine nur die von der Löschung betroffenen Zeilen für andere Transaktionen
			-- zu sperren. 
			DELETE TOP (@rc) [Event].[EPCISEvent] WITH (ROWLOCK)
			FROM [Event].[EPCISEvent] e
			inner join #TempEEPC te
			on e.ID = te.EPCISEventID
			--WHERE RecordTime <= @ToTimeStamp
			--	AND ID IN (
			--		SELECT EPCISEventID 
			--		FROM #TempEEPC 
			--		)

			-- zuweisen der von der Löschabfrage betroffenen Zeilen an die Bedingungsvariable
			-- wenn keine Zeilen mehr gelöscht worden sind (@rc = 0), wird die Schleife verlassen
			SET @rc = @@ROWCOUNT
			insert into #DebugInfo Values ('Delete [EPCISEvent]',@rc)
			COMMIT
		END TRY

		BEGIN CATCH
			-- Speichern der Fehlernachricht
			SET @msg = 'Table: EPCISEvent -- CleanUp Repository Error: ' + ERROR_MESSAGE();

			-- Ausgabe der Nachricht im Windows EventLog als ERROR
			--EXEC xp_logevent 51000
			--	,@msg
			--	,error;

			-- Löschungen Rückgängig machen
			ROLLBACK;

			-- gesamten Vorgang abbrechen
			throw;
		END CATCH
	END

	-- Die obigen Erläuterungen gelten für alle folgenden Löschabfragen
	--SET @rc = @BatchSize

	--WHILE @rc > 0
	--BEGIN
	--	BEGIN TRAN

	--	DELETE TOP (@rc) [Event].[EPC] WITH (ROWLOCK)
	--	FROM [Event].[EPC] epc
	--	inner join #TempEEPC te
	--		on epc.ID = te.EPCID 
	--	--WHERE ID IN (
	--	--		SELECT EPCID
	--	--		FROM #TempEEPC WITH (READUNCOMMITTED)
	--	--		)

	--	SET @rc = @@ROWCOUNT
	--	insert into #DebugInfo Values ('Delete EPC',@rc)
		
	--	COMMIT
	--END

	SET @rc = @BatchSize

	WHILE @rc > 0
	BEGIN
		BEGIN TRAN

		DELETE TOP (@rc)
		FROM [Event].[BusinessTransactionID] WITH (ROWLOCK)
		WHERE ID NOT IN (
				SELECT BusinessTransactionIDID
				FROM [Event].[EPCISEvent_BusinessTransactionID] WITH (READUNCOMMITTED)
				)

		SET @rc = @@ROWCOUNT
		insert into #DebugInfo Values ('Delete [BusinessTransactionID]',@rc)

		COMMIT
	END
------------------------Debug
	select *
	from Event.EPC epc
	inner join #TempEEPC
	on  epc.ID = #TempEEPC.EPCID

------------------------

	SET @rc = @BatchSize

	WHILE @rc > 0
	BEGIN
		BEGIN TRAN

		DELETE TOP (@rc)
		FROM [Event].[Value_String] WITH (ROWLOCK)
		WHERE ID NOT IN (
				SELECT Value_StringID
				FROM [Event].[EPCISEvent_Value_String] WITH (READUNCOMMITTED)
				)

		SET @rc = @@ROWCOUNT
		insert into #DebugInfo Values ('Delete [Value_String]',@rc)
		COMMIT
	END

	SET @rc = @BatchSize

	WHILE @rc > 0
	BEGIN
		BEGIN TRAN

		DELETE TOP (@rc)
		FROM Vocabulary.VocabularyChildren WITH (ROWLOCK)
		WHERE Deleted = 1

		SET @rc = @@ROWCOUNT
		insert into #DebugInfo Values ('Delete VocabularyChildren',@rc)

		COMMIT
	END

	SET @rc = @BatchSize

	WHILE @rc > 0
	BEGIN
		BEGIN TRAN

		DELETE TOP (@rc)
		FROM Vocabulary.VocabularyAttribute WITH (ROWLOCK)
		WHERE Deleted = 1

		SET @rc = @@ROWCOUNT
		insert into #DebugInfo Values ('Delete VocabularyAttribute',@rc)

		COMMIT
	END

	SET @rc = @BatchSize

	WHILE @rc > 0
	BEGIN
		BEGIN TRAN

		DELETE TOP (@rc)
		FROM Vocabulary.Vocabulary WITH (ROWLOCK)
		WHERE NOT EXISTS (
				SELECT 1
				FROM Event.EPCISEvent_Vocabulary WITH (READUNCOMMITTED)
				WHERE VocabularyID = Vocabulary.Vocabulary.ID
				)
			AND NOT EXISTS (
				SELECT 1
				FROM Event.BusinessTransactionID WITH (READUNCOMMITTED)
				WHERE BusinessTransactionTypeID = Vocabulary.Vocabulary.ID
				)
			AND NOT EXISTS (
				SELECT 1
				FROM Event.EPCISEvent_Value WITH (READUNCOMMITTED)
				WHERE DataTypeID = Vocabulary.Vocabulary.ID
				)
			AND NOT EXISTS (
				SELECT 1
				FROM Event.EPCISEvent_Value WITH (READUNCOMMITTED)
				WHERE ValueTypeID = Vocabulary.Vocabulary.ID
				)
			AND NOT EXISTS (
				SELECT 1
				FROM Event.EPCISEvent WITH (READUNCOMMITTED)
				WHERE ClientID = Vocabulary.Vocabulary.ID
				)
			AND NOT EXISTS (
				SELECT 1
				FROM Vocabulary.AttributeType WITH (READUNCOMMITTED)
				WHERE ContentTypeID = Vocabulary.Vocabulary.ID
				)
			AND NOT EXISTS (
				SELECT 1
				FROM Vocabulary.VocabularyAttribute WITH (READUNCOMMITTED)
				WHERE VocabularyID = Vocabulary.Vocabulary.ID
				)
			AND NOT EXISTS (
				SELECT 1
				FROM Vocabulary.VocabularyChildren WITH (READUNCOMMITTED)
				WHERE VocabularyID = Vocabulary.Vocabulary.ID
				)
			AND NOT EXISTS (
				SELECT 1
				FROM Vocabulary.VocabularyChildren WITH (READUNCOMMITTED)
				WHERE ChildVocabularyID = Vocabulary.Vocabulary.ID
				)
			AND Deleted = 1

		SET @rc = @@ROWCOUNT
		insert into #DebugInfo Values ('Delete Vocabulary',@rc)

		COMMIT
	END

	SET @rc = @BatchSize

	WHILE @rc > 0
	BEGIN
		BEGIN TRAN

		DELETE TOP (@rc)
		FROM Vocabulary.VocabularyType_Client WITH (ROWLOCK)
		WHERE NOT EXISTS (
				SELECT 1
				FROM Vocabulary.VocabularyType WITH (READUNCOMMITTED)
				WHERE ID = VocabularyTypeID
				)
			AND Deleted = 1

		SET @rc = @@ROWCOUNT
		insert into #DebugInfo Values ('Delete VocabularyType_Client',@rc)

		COMMIT
	END

	SET @rc = @BatchSize

	WHILE @rc > 0
	BEGIN
		BEGIN TRAN

		DELETE TOP (@rc)
		FROM Vocabulary.VocabularyType WITH (ROWLOCK)
		WHERE NOT EXISTS (
				SELECT 1
				FROM Vocabulary.VocabularyType_Client WITH (READUNCOMMITTED)
				WHERE VocabularyTypeID = ID
				)
			AND NOT EXISTS (
				SELECT 1
				FROM Vocabulary.Vocabulary WITH (READUNCOMMITTED)
				WHERE VocabularyTypeID = ID
				)

		SET @rc = @@ROWCOUNT
		insert into #DebugInfo Values ('Delete VocabularyType',@rc)

		COMMIT
	END
------------------------------------Ausgabe DebugInfo	
	select *
	from #DebugInfo
----------------------------------------
END

