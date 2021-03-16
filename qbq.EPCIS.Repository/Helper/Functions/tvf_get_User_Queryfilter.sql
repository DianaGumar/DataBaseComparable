-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- Ermittelt zu einem Usernamen alle Queryfilter
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 06.09.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE FUNCTION [Helper].[tvf_get_User_Queryfilter]
(
	@Client   nvarchar(512),
    @Username nvarchar(512) = null
)
RETURNS @returntable TABLE
(
	Username      nvarchar(512) NOT NULL,
	receiverGLN   nvarchar(512) NOT NULL
)
AS
BEGIN

	-- Normale User / ClientStammdaten
	INSERT INTO @returntable (
		Username,
		receiverGLN
	)
	select 
		Username,
		GLN as receiverGLN
	from [Helper].[tvf_get_Partner_Settings]( @Client, @Username )
	where Atype = N'urn:quibiq:epcis:atype:username';

	-- Master User / Systemstammdaten
	merge into @returntable as target
			using (
				SELECT
					Username,
					receiverGLN
				FROM (
					SELECT
						Loc.value('.', N'nvarchar(512)') as Username,
						N'all' as receiverGLN
					FROM [Helper].[tvf_get_Client_Settings] ( @Client, N'urn:quibiq:epcis:atype:masteruser' ) t
					CROSS APPLY t.Value.nodes(N'declare namespace rl="urn:quibiq:epcis:atype:username"; /Value/rl:username/text()') as T2(Loc)
				) as Masterusers
				WHERE Username = @Username or @Username is null
			) as source
		on target.Username = source.Username
		when not matched by target then
			insert (Username, receiverGLN)
				values (source.Username, source.receiverGLN)
		when matched then
			update set receiverGLN = source.receiverGLN;


	RETURN;
END;