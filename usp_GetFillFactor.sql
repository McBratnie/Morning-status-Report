
/****** Object:  StoredProcedure [dbo].[usp_GetFillFactor]    Script Date: 2/13/2021 12:12:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_GetFillFactor] (
 --@output char(1),  -- Not needed on this style.
 @TXTOUT NVARCHAR(MAX) OUTPUT,
 @O_Priority TINYINT OUTPUT
 )
AS
/*******************************************************************
--
--Create 3/29/2020 JmcBratnie
-- email a script of indexes that need to have the fill factor adjusted
--
********************************************************************/

BEGIN
	SELECT @O_Priority = 75;
   declare @command Nvarchar(MAX);
	declare @rowcount as int;
        --this has to be ran on each db.  Store the results here
	CREATE TABLE [dbo].[#TMP] (
	[DBNAME]     NVARCHAR(256) NULL,
	[CMD]       NVARCHAR(MAX) NULL);


                -- the command to be ran on each db
                -- use ? is the current DB
                -- can the command be skiped for this db?
		select @command = 
/*		'USE [?] 
		IF NOT EXISTS(SELECT ''X''
		FROM sys.indexes i 
			join sys.objects o on i.object_id = o.object_id
			join sys.schemas s on o.schema_id = s.schema_id
			--join sys.databases d on i.object_id = d.
		WHERE fill_factor < 80 AND fill_factor <> 0
		AND is_disabled = 0 AND is_hypothetical = 0)
			BEGIN
				PRINT ''No matching row exists''
			END
		ELSE
			INSERT INTO #TMP 
			SELECT cast(''[''+DB_NAME()+'']'' as NVARCHAR(MAX)), CAST(''ALTER INDEX ''+i.name+ '' ON ''+s.name+ ''.''+o.name+'' REBUILD WITH (FILLFACTOR = 100);'' as NVARCHAR(MAX))
			FROM sys.indexes i 
				join sys.objects o on i.object_id = o.object_id
				join sys.schemas s on o.schema_id = s.schema_id
				--join sys.databases d on i.object_id = d.
			WHERE fill_factor < 80 AND fill_factor <> 0
			AND is_disabled = 0 AND is_hypothetical = 0;';
*/
			'USE [?] 
			DECLARE @idx SYSNAME
DECLARE @SQL NVARCHAR(300)
DECLARE cur_FillFactor CURSOR FOR
	SELECT 
      ''ALTER INDEX ''+i.name+ '' ON ''+s.name+''.''+o.name+ '' REBUILD WITH (FILLFACTOR = 100); ''
	FROM sys.indexes i 
		join sys.objects o on i.object_id = o.object_id
		join sys.schemas s on o.schema_id = s.schema_id
		--join sys.databases d on i.object_id = d.
	WHERE fill_factor < 80 AND fill_factor <> 0
	AND is_disabled = 0 AND is_hypothetical = 0

OPEN cur_FillFactor
  FETCH NEXT FROM cur_FillFactor INTO @idx

WHILE @@FETCH_STATUS = 0
   BEGIN
     SELECT @SQL = @idx
     EXEC sp_executesql @SQL
	  PRINT @SQL

     FETCH NEXT FROM cur_FillFactor INTO @idx
   END
CLOSE cur_FillFactor
DEALLOCATE cur_FillFactor 
PRINT ''Complete'' '


	EXEC sp_MSforeachdb @command
	-- 'ALTER INDEX '+i.name+ ' ON '+s.name+'.'+o.name+ 'REBUILD WITH (FILLFACTOR = 100); '

	-- Generate the output 	
	select @rowcount = count('x') from #TMP
	if @rowcount >0  
	BEGIN

		select @TXTOUT =  cast('<h2> FillFactor Repairs: </h2><ul style="list-style-type:none;">' as NVARCHAR(MAX));
		select @TXTOUT = @TXTOUT + cast('<li>' as NVARCHAR(MAX)) + tt.DBNAME + cast(' - ' as NVARCHAR(MAX)) + tt.CMD + cast('</li>' as NVARCHAR(MAX)) FROM #TMP tt;
		select @TXTOUT = @TXTOUT + '</ul>'

	END
	ELSE
	BEGIN
		select @TXTOUT =  cast('<h2> FillFactor Repairs: </h2><ul style="list-style-type:none;">' as NVARCHAR(MAX));
		select @TXTOUT = @TXTOUT + cast('<li>' as NVARCHAR(MAX)) + cast(' NONE ' as NVARCHAR(MAX)) + cast('</li>' as NVARCHAR(MAX)) ;
		select @TXTOUT = @TXTOUT + '</ul>';
		SELECT @TXTOUT = N'';
	END
	Print @TXTOUT
	drop table #TMP
END
GO

