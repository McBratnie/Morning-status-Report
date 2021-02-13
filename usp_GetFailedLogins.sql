

/****** Object:  StoredProcedure [dbo].[usp_GetFailedLogins]    Script Date: 2/13/2021 12:13:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_GetFailedLogins] (
 @TXTOUT NVARCHAR(Max) OUTPUT,
 @O_Priority tinyint OUTPUT
  )
AS
/**********************************************************
--
-- Create 3/28/2020 JMCBRATNIE
-- List login attempts that failed inthe past day
--
-- Modified 10/26/2020 JMcBratnie Add message for no failed
***********************************************************/

BEGIN
   SET NOCOUNT ON

   DECLARE @ErrorLogCount INT 
   DECLARE @LastLogDate DATETIME
   DECLARE @TXTOUT2 NVARCHAR(MAX);
   DECLARE @serviceState NVARCHAR(512);


   DECLARE @ErrorLogInfo TABLE (
       LogDate DATETIME
      ,ProcessInfo NVARCHAR (50)
      ,[Text] NVARCHAR (MAX)
      )
   
   DECLARE @EnumErrorLogs TABLE (
       [Archive#] INT
      ,[Date] DATETIME
      ,LogFileSizeMB INT
      )

	select @O_Priority = 50;
   INSERT INTO @EnumErrorLogs
   EXEC sp_enumerrorlogs;

   SELECT @ErrorLogCount = MIN([Archive#]), @LastLogDate = MAX([Date])
   FROM @EnumErrorLogs
   WHILE @ErrorLogCount IS NOT NULL
   BEGIN

      INSERT INTO @ErrorLogInfo
      EXEC sp_readerrorlog @ErrorLogCount;

      SELECT @ErrorLogCount = MIN([Archive#]), @LastLogDate = MAX([Date])
      FROM @EnumErrorLogs
      WHERE [Archive#] > @ErrorLogCount
      AND @LastLogDate > getdate() - 1;
  
   END

   -- if not data then skip the output
   IF NOT EXISTS(SELECT * 
					FROM @ErrorLogInfo 
					WHERE ProcessInfo = 'Logon' 
					AND TEXT LIKE '%fail%' --+char(39)+"
					AND LogDate > getdate() - 1)
		BEGIN
			select @TXTOUT =  cast('<h2> NO Failed Logins attempts yesterday </h2>' as NVARCHAR(MAX));
			PRINT 'No matching row exists'
		END
	ELSE
        -- create the output in html format
		BEGIN
			select @TXTOUT =cast('<h2>Failed log on attempts: </h2><ul>' as NVARCHAR(max));

		select @TXTOUT = @TXTOUT + cast('<table border="1" width="100%" style="border-collapse:collapse;">
		<caption style="caption-side:bottom; text-align:right">* denotes disabled accounts</caption>
		<col style="width:15%">
		<col style="width:85%">
		<tr>
		<th>Appempts</th>
		<th>Details</th>
		</tr>' as NVARCHAR(MAX));


			SELECT @TXTOUT = @TXTOUT + cast('<tr><td>' as NVARCHAR(MAX))+convert(nvarchar(max), x.NumberOfAttempts)+cast('</td><td>' as NVARCHAR(MAX))+ details +cast('</td></tr>' as NVARCHAR(MAX))
			from (
			SELECT COUNT (TEXT) AS NumberOfAttempts, TEXT AS Details, MIN(LogDate) as MinLogDate, MAX(LogDate) as MaxLogDate
				FROM @ErrorLogInfo
				WHERE ProcessInfo = 'Logon' --+char(39)+"
				AND TEXT LIKE '%fail%' --+char(39)+"
				AND LogDate > getdate() - 1
				GROUP BY TEXT) x;
			
			select @TXTOUT = @TXTOUT+cast('</table>' as NVARCHAR(MAX));
		END
		

   SET NOCOUNT OFF
END              
GO

