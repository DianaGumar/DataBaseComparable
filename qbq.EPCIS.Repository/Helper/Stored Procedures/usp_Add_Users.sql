CREATE PROCEDURE [Helper].[usp_Add_Users]
	@mandantURN VARCHAR(128),
	@newUsers xml
AS
BEGIN

	DECLARE @xmlValue XML
	DECLARE @xmlTemp XML
	DECLARE @strvalue VARCHAR(500)

	-- aktuelle UserListe holen
	SELECT @xmlValue = va.Value
	FROM [Vocabulary].[VocabularyAttribute] va
	INNER JOIN [Vocabulary].[AttributeType] at ON va.AttributeTypeID = at.ID
		AND at.URN = N'urn:quibiq:epcis:atype:masteruser'
	INNER JOIN [Vocabulary].[Vocabulary] v ON v.ID = va.VocabularyID
	INNER JOIN [Vocabulary].[VocabularyType] vt ON v.VocabularyTypeID = vt.ID
		AND vt.URN = N'urn:quibiq:epcis:vtype:client'
		AND v.URN = @mandantURN

	-- Temp Tables wenn vorhanden löschen
	IF OBJECT_ID('tempdb..#oldT') IS NOT NULL
		DROP TABLE #oldT

	IF OBJECT_ID('tempdb..#newT') IS NOT NULL
		DROP TABLE #newT

	-- temporäre Tabelle für aktuelle User erstellen
	CREATE TABLE #oldT (
		x XML
		,username NVARCHAR(100)
		)
	
	-- aktuelle User als Xml und Text in intemporäre Tabelle
	INSERT INTO #oldT
	SELECT x.query('.')
		,x.value('.', 'nvarchar(100)') username
	FROM @xmlValue.nodes('/Value/*') AS XTbl(x)

	-- temporäre Tabelle für aktuelle User erstellen
	CREATE TABLE #newT (
		x XML
		,username NVARCHAR(100)
		)

	-- -- neue User als Xml und Text in intemporäre Tabelle
	INSERT INTO #newT
	SELECT x.query('.')
		,x.value('.', 'nvarchar(100)') username
	FROM @newUsers.nodes('*') AS XTbl(x)

	SET @strvalue = ''

	-- nur neue (nocht nicht verrechtet) selektieren und in einem String speichern
	SELECT @strvalue = @strvalue + COALESCE(cast(n.x AS VARCHAR(100)), '')
	FROM #newT n
	LEFT JOIN #oldT o ON n.username = o.username
	WHERE o.username IS NULL

	-- xmlString in XML convertieren
	SELECT @xmlTemp = cast(@strvalue AS XML)

	-- neue User zu den aktuellen Usern hinzufügen
	SET @xmlValue.modify('insert sql:variable("@xmlTemp") as last into (/Value)[1]')

	--SELECT @xmlValue

	-- aktuelles Attribut mit der neuen User Liste aktualisieren
	UPDATE va
	SET Value = @xmlValue
	FROM [Vocabulary].[VocabularyAttribute] va
	INNER JOIN [Vocabulary].[AttributeType] at ON va.AttributeTypeID = at.ID
		AND at.URN = N'urn:quibiq:epcis:atype:masteruser'
	INNER JOIN [Vocabulary].[Vocabulary] v ON v.ID = va.VocabularyID
	INNER JOIN [Vocabulary].[VocabularyType] vt ON v.VocabularyTypeID = vt.ID
		AND vt.URN = N'urn:quibiq:epcis:vtype:client'
		AND v.URN = @mandantURN

	RETURN 0
End