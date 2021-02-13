

/****** Object:  StoredProcedure [dbo].[usp_emailMorningDBStatus]    Script Date: 2/13/2021 12:14:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_emailMorningDBStatus] 
AS

/*******************************************************************
--
--Create 3/29/2020 JMcBratnie
-- Email the results of checks on the database nightly
--
********************************************************************/
BEGIN
declare @output NVARCHAR(MAX); 
declare @Prior tinyint;
declare @O_Priority tinyint;
declare @body NVARCHAR(MAX);
declare @subject NVARCHAR(MAX);

-- initialize vars
select @output = N'';
select @body = N'';
select @subject = N'';

	-- Temp table to store the data.
	CREATE TABLE #MorningRPT
	( 
	myid int identity(1,1),
	msg nvarchar(max),
	output_priority tinyint
	);


-- Get any databases that are not in a good state
exec [IT.Macomb_DBA].[dbo].[usp_GetDBHealth] @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END
	
-- Get nightly failed login attempts 
exec [IT.Macomb_DBA].dbo.usp_GetFailedLogins @TXTOUT = @output output, @O_Priority = @Prior output;
--store it for email
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END

-- What services are running and not
exec [IT.Macomb_DBA].dbo.usp_GetServices @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END

--Who is an admin of the server
exec [IT.Macomb_DBA].dbo.usp_Getadmins @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END


-- Did sql puke on me
exec [IT.Macomb_DBA].dbo.usp_Getdumps @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END

-- What servers are linked to this server
exec [IT.Macomb_DBA].dbo.usp_GetLinked @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END

--Are the backups old?
exec [IT.Macomb_DBA].dbo.usp_Getstalebackups @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END

-- what precedures are running on start (might haveduplicates here)
-- Also, might want to check jobs for start up
exec [IT.Macomb_DBA].dbo.usp_GetStartups @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END

-- Might want to list jobs that failed in the past 24 hours

-- Who needs a fill tactor adjustment
exec [IT.Macomb_DBA].dbo.usp_GetFILLFactor @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END

-- What jobs failed
exec [IT.Macomb_DBA].dbo.usp_GetJobsFailed @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END
select @output = cast('' AS NVARCHAR(MAX));


--What jobs are not enabled
exec [IT.Macomb_DBA].dbo.usp_GetJobsNotEnabled @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END

-- Enabled but scheduled not enabled
exec [IT.Macomb_DBA].dbo.usp_GetJobsscheduleNotEnabled @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END

-- Enabled jobs with not schedule
exec [IT.Macomb_DBA].dbo.usp_GetJobsnotscheduled @TXTOUT = @output output, @O_Priority = @Prior output;
if @output IS NOT NULL 
	BEGIN
		select @body = @body + @output;
		select @output =N'';

		INSERT INTO #MorningRPT
		(msg, output_priority)
		SELECT @output, @Prior ;

	END 

/*--What does the body look like?  Comment this out on production
select @body;
--*/
SELECT @body = @body + msg from #MorningRPT order by output_priority;


Select @subject = cast('Morning issue report - ' AS NVARCHAR(Max)) + @@SERVERNAME;


-- Finally, Send Email
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'SMTP',
@recipients = 'Macomb DBA <macomb-dba@macombgov.org>',
@subject = @subject, 
@body = @body,
@body_format = 'HTML',
@from_address='<NOREPLY@macombgov.org>';
--*/
end
GO

