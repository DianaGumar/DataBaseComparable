-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Helper.usp_Get_Record_Per_Minute 
	-- Add the parameters for the stored procedure here
	@STARTDATE DATE,
        @ENDDATE DATE,
		@TopCount INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT TOP(@TopCount) COUNT(*) AS Anzahl, FORMAT([RecordTime],'yyyy-MM-dd hh:mm') AS [Minuten]

  
  FROM [Event].[EPCISEvent]
  WHERE [RecordTime] BETWEEN @STARTDATE AND @ENDDATE
  GROUP BY FORMAT([RecordTime],'yyyy-MM-dd hh:mm')
  ORDER BY Anzahl DESC
  
END