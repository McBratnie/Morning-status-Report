

/****** Object:  StoredProcedure [dbo].[usp_Getservices]    Script Date: 2/13/2021 12:10:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_Getservices] (
 --@output char(1),  -- Not needed on this style.
 @TXTOUT NVARCHAR(MAX) OUTPUT,
 @O_Priority tinyint OUTPUT
 )
AS
/*******************************************************************
--
--Create 3/29/2020 JmcBratnie
-- What services are active and are they running
--
********************************************************************/

BEGIN

	set nocount on
	
	-- Temp table to store the data.
	CREATE TABLE #ServicesStatus
	( 
	myid int identity(1,1),
	serverName nvarchar(100) default @@serverName,
	serviceName varchar(100),
	Status varchar(50),
	checkdatetime datetime default (getdate())
	)
	
	select @O_Priority = 12;

	-- Collect the data
	INSERT #ServicesStatus (Status)
	EXEC xp_servicecontrol N'QUERYSTATE',N'MSSQLServer'
	update #ServicesStatus set serviceName = 'MSSQLServer' where myid = @@identity
	INSERT #ServicesStatus (Status)
	EXEC xp_servicecontrol N'QUERYSTATE',N'SQLServerAGENT'
	update #ServicesStatus set serviceName = 'SQLServerAGENT' where myid = @@identity
	INSERT #ServicesStatus (Status)
	EXEC xp_servicecontrol N'QUERYSTATE',N'msdtc';
	update #ServicesStatus set serviceName = 'msdtc' where myid = @@identity;
	INSERT #ServicesStatus (Status)
	EXEC xp_servicecontrol N'QUERYSTATE',N'sqlbrowser'
	update #ServicesStatus set serviceName = 'sqlbrowser' where myid = @@identity

    -- Generate the output 	
	select @TXTOUT =  cast('<h2> SQL Services: </h2>' as NVARCHAR(MAX));
	select @TXTOUT = @TXTOUT + cast('<ol>' as NVARCHAR(MAX));
	select @TXTOUT = @TXTOUT + cast('<li>' as NVARCHAR(MAX)) + cast(serverName as NVARCHAR(MAX)) + cast(' (' as NVARCHAR(MAX)) + cast(serviceName as NVARCHAR(MAX)) + cast(') : ' as NVARCHAR(MAX)) + cast(status as NVARCHAR(MAX)) + cast('</li>' as NVARCHAR(MAX))
	  from #ServicesStatus; 
	select @TXTOUT = @TXTOUT + cast('</ol>' as NVARCHAR(MAX));

	drop table #ServicesStatus
END;
GO

