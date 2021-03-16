-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Helper.usp_Get_Record_Per_Hour 
	-- Add the parameters for the stored procedure here
	@STARTDATE DATE,
        @ENDDATE DATE,
		@AMOUNT INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT TOP(@AMOUNT) COUNT(*) AS Anzahl, FORMAT([RecordTime],'yyyy-MM-dd hh') AS [Stunden]

  
  FROM [EPCIS_E].[Event].[EPCISEvent]
  WHERE [RecordTime] BETWEEN @STARTDATE AND @ENDDATE
  GROUP BY FORMAT([RecordTime],'yyyy-MM-dd hh')
  ORDER BY Anzahl DESC
  
END