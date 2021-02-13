
/****** Object:  StoredProcedure [dbo].[usp_GetJobsNotEnabled]    Script Date: 2/13/2021 12:12:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_GetJobsNotEnabled] (
 --@output char(1),  -- Not needed on this style.
 @TXTOUT NVARCHAR(MAX) OUTPUT,
 @O_Priority TINYINT OUTPUT
 )
AS
/*******************************************************************
--
--Create 4/1/2020 JmcBratnie
-- jobs that are not enabled potentially are useless
-- Too many cooks in the kitchen
--
********************************************************************/

BEGIN
	SELECT @O_Priority = 93;
    -- if no data skip output file
    IF NOT EXISTS(SELECT 'X'
						FROM MSDB.DBO.sysjobs sj2
							right join (
								SELECT sj.job_id, 'Job not enabled' as issue
								FROM MSDB.DBO.sysjobs sj
								WHERE sj.enabled = 0  )
							 jj ON jj.job_id = sj2.job_id )
		BEGIN
			PRINT 'No matching row exists'
			SELECT @TXTOUT =  cast('<h2>ALL jobs are enabled:</h2>' as NVARCHAR(MAX));
			SELECT @TXTOUT = N'';
		END
	ELSE
		BEGIN
			-- Generate the output 	
			select @TXTOUT =  cast('<h2>Jobs that are not enabled (Paused): </h2>' as NVARCHAR(MAX));
			select @TXTOUT = @TXTOUT + cast('<table  border="1" width="100%" style="border-collapse:collapse;">
				<col style="width:15%">
				<col style="width:65%">
				<col style="width:10%">
				<col style="width:10%">
				<tr>
				<th>Job Name</th>
				<th>Description</th>
				<th>Created</th>
				<th>Modified</th>
				</tr>' as NVARCHAR(MAX));

			SELECT @TXTOUT = @TXTOUT + cast('<tr><td>' 
												+ sj2.name + '</td><td>' 
												+ sj2.description + '</td><td>' as NVARCHAR(MAX)) 
											+ convert(NVARCHAR(MAX), sj2.date_created,22) + cast('</td><td>' as NVARCHAR(MAX))
											+ convert(NVARCHAR(MAX), sj2.date_modified,22) + cast('</td></tr>' as NVARCHAR(MAX))
			FROM MSDB.DBO.sysjobs sj2
				right join (
					SELECT sj.job_id, 'Jobs not enabled' as issue
					FROM MSDB.DBO.sysjobs sj
					WHERE sj.enabled = 0
				) jj ON jj.job_id = sj2.job_id
				order by issue, name, date_modified

			select @TXTOUT = @TXTOUT + cast('</table>' as NVARCHAR(MAX));

		END
END
GO

