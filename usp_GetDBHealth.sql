

/****** Object:  StoredProcedure [dbo].[usp_GetDBHealth]    Script Date: 2/13/2021 12:14:25 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[usp_GetDBHealth] (
 --@output char(1),  -- Not needed on this style.
 @TXTOUT NVARCHAR(MAX) OUTPUT,
 @O_Priority tinyint OUTPUT
 )
AS
/*******************************************************************
--
--Create 8/3/2020 JmcBratnie
-- What databases are in a bad state
--
********************************************************************/

BEGIN

	set nocount on
	
	-- Temp table to store the data.
	CREATE TABLE #DBHealthStatus
	( 
	myid int identity(1,1),
	ord tinyint,
	msg nvarchar(128)
	);

	INSERT INTO #DBHealthStatus
	(ord, msg)
	SELECT 2, N'<li>' + COALESCE(name, N' Database ID ' + CAST(database_id AS NVARCHAR(10))) COLLATE SQL_Latin1_General_CP1_CI_AS + N' state: ' + state_desc + N'</li>'
	FROM sys.databases
	WHERE state NOT IN (0, 1, 7, 10);

	IF (SELECT count(1) FROM #DBHealthStatus) > 0 
		BEGIN
			INSERT INTO #DBHealthStatus
			(ord, msg)
			SELECT 1 AS Orderby, N'<h1>Databases all NOT online;</h1><ul>';
			INSERT INTO #DBHealthStatus
			(ord, msg)
			SELECT 3 AS Orderby, N'</ul>';
		END
	ELSE
		BEGIN
			INSERT INTO #DBHealthStatus
			(ord, msg)
			select 1, N'<h1>All databases okay.</h1>';
		END;
	select @TXTOUT = @TXTOUT + msg from #DBHealthStatus order by ord;
	select @O_Priority = 10;

	drop table #DBHealthStatus

END;
GO

