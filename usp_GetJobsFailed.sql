
/****** Object:  StoredProcedure [dbo].[usp_GetJobsFailed]    Script Date: 2/13/2021 12:12:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- jobs that failed in the past 24 hours.  
-- Need to convert this to generate an html email and email the DBA group
CREATE PROC [dbo].[usp_GetJobsFailed] (
 --@output char(1),  -- Not needed on this style.
 @TXTOUT NVARCHAR(MAX) OUTPUT,
 @O_Priority TINYINT OUTPUT
 )
AS
/*******************************************************************
--
--Create 4/1/2020 JmcBratnie
-- jobs that failed in the past 24 hours.
--
********************************************************************/

BEGIN
	SELECT @O_Priority = 51;

    -- if no data skip output file
    IF NOT EXISTS(SELECT 'X'
						FROM msdb..sysjobhistory T1 
						  INNER JOIN msdb..sysjobs T2 ON T1.job_id = T2.job_id
						WHERE T1.run_status NOT IN (1, 4)
						  AND T1.step_id != 0
						  AND run_date >= CONVERT(CHAR(8), (SELECT DATEADD (DAY,(-1), GETDATE())), 112)  )
		BEGIN
			PRINT 'No matching row exists'
			SELECT @TXTOUT =  cast('<h2>NO Jobs Failed: </h2>' as NVARCHAR(MAX));
			SELECT @TXTOUT = N'';
		END
	ELSE
		BEGIN
			-- Generate the output 	
			select @TXTOUT =  cast('<h2>Failed Jobs:</h2>' as NVARCHAR(MAX));
			select @TXTOUT = @TXTOUT + cast('<table  border="1" width="100%" style="border-collapse:collapse;">
				<col style="width:10%">
				<col style="width:5%">
				<col style="width:10%">
				<col style="width:10%">
				<col style="width:12%">
				<col style="width:12%">
				<col style="width:10%">    
				<col style="width:33%">
				<tr>
				<th>Server Name</th>
				<th>Step ID</th>
				<th>Step Name</th>
				<th>Job Name</th>
				<th>Run Date</th>
				<th>Duration</th>
				<th>Status</th>
				<th>Message</th></tr>' as NVARCHAR(MAX));

			SELECT DISTINCT @TXTOUT = @TXTOUT + cast('<tr><td>' as NVARCHAR(MAX)) + cast(T1.server as NVARCHAR(MAX)) + cast('</td><td>'  as NVARCHAR(MAX))
				+ convert(NVARCHAR(MAX),T1.step_id) 
				+ cast('</td><td>' + T1.step_name + '</td><td>'
				+ SUBSTRING(T2.name,1,140) + '</td><td>' as NVARCHAR(MAX)) 
				+ convert(NVARCHAR(MAX), msdb.dbo.agent_datetime(run_date, run_time), 22)
				+ cast('</td><td>' as NVARCHAR(MAX))
				+ convert(NVARCHAR(MAX), T1.run_duration) 
				+ cast('</td><td>' 
				+ CASE T1.run_status
					WHEN 0 THEN 'Failed'
					WHEN 1 THEN 'Succeeded'
					WHEN 2 THEN 'Retry'
					WHEN 3 THEN 'Cancelled'
					WHEN 4 THEN 'In Progress'
					END +'</td><td>'
				+ T1.message + '</td></tr>' as NVARCHAR(MAX))
			FROM
			msdb..sysjobhistory T1 INNER JOIN msdb..sysjobs T2 ON T1.job_id = T2.job_id
			WHERE
			T1.run_status NOT IN (1, 4)
			AND T1.step_id != 0
			AND run_date >= CONVERT(CHAR(8), (SELECT DATEADD (DAY,(-1), GETDATE())), 112)
			select @TXTOUT = @TXTOUT + cast('</table>' as NVARCHAR(MAX));

		END
END
GO

