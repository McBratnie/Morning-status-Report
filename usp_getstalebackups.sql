
/****** Object:  StoredProcedure [dbo].[usp_Getstalebackups]    Script Date: 2/13/2021 12:10:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------- 
--Databases Missing a Data (aka Full) Back-Up Within Past 24 Hours 
------------------------------------------------------------------------------------------- 
--Databases with data backup over 24 hours old 
CREATE PROC [dbo].[usp_Getstalebackups] (
 --@output char(1),  -- Not needed on this style.
 @TXTOUT NVARCHAR(MAX) OUTPUT,
 @O_Priority TINYINT OUTPUT
 )
AS
/*******************************************************************
--
--Create 3/29/2020 JmcBratnie
-- Check all the database for old backups that have not ran.
--
********************************************************************/

BEGIN
	SELECT @O_Priority = 13;
    -- only create data if backup are old
    IF NOT EXISTS(SELECT 'X' 
					FROM    msdb.dbo.backupset 
					WHERE     msdb.dbo.backupset.type = 'D'  
					GROUP BY msdb.dbo.backupset.database_name 
					HAVING      (MAX(msdb.dbo.backupset.backup_finish_date) < DATEADD(hh, - 24, GETDATE()))  )
		BEGIN
			SELECT @TXTOUT =  cast('<h2> NO Stale Backups: </h2>' as NVARCHAR(MAX));
			SELECT @TXTOUT = N'';
			PRINT 'No matching row exists'
		END
	ELSE
		BEGIN
			-- Generate the output 	
			SELECT @TXTOUT =  cast('<h2> Stale Backups: </h2>' as NVARCHAR(MAX));
			SELECT @TXTOUT = @TXTOUT + cast('<ul>' as NVARCHAR(MAX));

			SELECT @TXTOUT = @TXTOUT +cast('<li>' as NVARCHAR(MAX)) + cast(x.server as NVARCHAR(MAX)) + cast(' ' as NVARCHAR(MAX)) +  cast(x.database_name as NVARCHAR(MAX)) + cast(' hours old: ' as NVARCHAR(MAX)) + convert(NVARCHAR(MAX),x.Backup_Age_hours) + cast('</li>' as NVARCHAR(Max))
			FROM (
				SELECT 
				   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
				   msdb.dbo.backupset.database_name, 
				   MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date, 
				   DATEDIFF(hh, MAX(msdb.dbo.backupset.backup_finish_date), GETDATE()) AS [Backup_Age_hours] 
				FROM    msdb.dbo.backupset 
				WHERE     msdb.dbo.backupset.type = 'D'  
				GROUP BY msdb.dbo.backupset.database_name 
				HAVING      (MAX(msdb.dbo.backupset.backup_finish_date) < DATEADD(hh, - 24, GETDATE()))  

				UNION  

				--Databases without any backup history 
				SELECT      
				   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,  
				   sd.NAME AS database_name,  
				   NULL AS [Last Data Backup Date],  
				   9999 AS [Backup Age (Hours)]  
				FROM 
				   master.dbo.sysdatabases sd LEFT JOIN msdb.dbo.backupset bs
					   ON sd.name  = bs.database_name 
				WHERE bs.database_name IS NULL AND sd.name <> 'tempdb' ) x
				ORDER BY  database_name;
				
   			select @TXTOUT = @TXTOUT + cast('</ul>' as NVARCHAR(MAX));

		END

END
GO

