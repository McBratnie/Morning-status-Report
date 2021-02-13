
/****** Object:  StoredProcedure [dbo].[usp_GetStartups]    Script Date: 2/13/2021 12:09:36 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_GetStartups] (
 --@output char(1),  -- Not needed on this style.
 @TXTOUT NVARCHAR(MAX) OUTPUT,
 @O_Priority TINYINT OUTPUT
 )
AS
/*******************************************************************
--
--Create 3/29/2020 JmcBratnie
-- email a script what runs at start up.
-- Might need to be adjusted to handle the jobs that run at startup.
--
********************************************************************/

BEGIN
	SELECT @O_Priority = 92;
	-- resolve issue with collation on the databases. Why we cant standize this??
	CREATE TABLE [dbo].[#TMP] 
	(
		[ord]             INT,
		[NAME]          NVARCHAR(256) NULL,
		[type_desc]       NVARCHAR(MAX) NULL,
		[Create_Date]     NVARCHAR(22) NULL,
		[Modify_Date]     NVARCHAR(22) NULL 
	);

    IF NOT EXISTS(SELECT 'x'
						  FROM master.sys.procedures
						WHERE is_auto_executed = 1
						union 
						select 'x' 
						FROM sysobjects
						WHERE type = 'P'
						  AND OBJECTPROPERTY(id, 'ExecIsStartUp') = 1
						union 
						SELECT 'x'
							FROM msdb.dbo.sysschedules sched
							  JOIN msdb.dbo.sysjobschedules jsched 
								 ON sched.schedule_id = jsched.schedule_id
							  JOIN msdb.dbo.sysjobs j 
								 ON jsched.job_id = j.job_id
							WHERE sched.freq_type = 64)
		BEGIN
			SELECT @TXTOUT =  cast('<h2> NO Procedures that run at start-up: </h2>' as NVARCHAR(MAX));
			SELECT @TXTOUT = N'';
			PRINT 'No matching row exists'
		END
	ELSE
		BEGIN

			INSERT INTO #TMP
				SELECT 1, cast(name as NVARCHAR(MAX)) as name, cast(type_desc as NVARCHAR(MAX)) as type_desc, convert(NVARCHAR(MAX),create_date,22), convert(NVARCHAR(MAX),modify_date,22)
				FROM Master.sys.procedures
				WHERE is_auto_executed = 1
				Order by 3,2;

			INSERT INTO #TMP
				SELECT 2, [name] , cast('Stored Proc' as NVARCHAR(MAX)), cast('' as NVARCHAR(MAX)),cast('' as NVARCHAR(MAX))
				FROM sysobjects
				WHERE type = 'P'
				  AND OBJECTPROPERTY(id, 'ExecIsStartUp') = 1
				Order by 3,2;

			INSERT INTO #TMP
				SELECT 3,cast(j.name as NVARCHAR(MAX)) , cast('JOB' as NVARCHAR(MAX)) , cast('' as NVARCHAR(MAX)),cast('' as NVARCHAR(MAX)) 
					FROM msdb.dbo.sysschedules sched
					  JOIN msdb.dbo.sysjobschedules jsched 
						 ON sched.schedule_id = jsched.schedule_id
					  JOIN msdb.dbo.sysjobs j 
						 ON jsched.job_id = j.job_id
					WHERE sched.freq_type = 64
					Order by 3,2;

		END

		IF (select count('X') from #TMP)>0 
		BEGIN
					-- Generate the output 	
			select @TXTOUT =  cast('<h2>Procedures that run at start-up: </h2>' as NVARCHAR(MAX));
			select @TXTOUT = @TXTOUT + cast('<table border="1" width="100%" style="border-collapse:collapse;">
				<col style="width:20%">
				<col style="width:56%">
				<col style="width:12%">
				<col style="width:12%">
				<tr><th>Job Name</th><th>Object Type</th><th>Create Date</th><th>Modified Date</th></tr>' as NVARCHAR(MAX));

			select @TXTOUT = @TXTOUT 
				+ cast('<tr><td>' as NVARCHAR(MAX)) 
				+ tt.NAME + cast('</td><td>' as NVARCHAR(MAX)) 
				+ tt.type_desc + cast('</td><td>' as NVARCHAR(MAX)) 
				+ tt.Create_Date + cast('</td><td>' as NVARCHAR(MAX)) 
				+ tt.Modify_Date + cast('</td></tr>' as NVARCHAR(MAX)) 
			FROM #TMP tt 
			order by tt.ord, tt.type_desc, tt.NAME;

			select @TXTOUT = @TXTOUT + cast('</table><P>May include duplicates</p>' as NVARCHAR(MAX));

		END
	DROP TABLE #TMP
END
GO

