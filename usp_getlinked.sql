
/****** Object:  StoredProcedure [dbo].[usp_GetLinked]    Script Date: 2/13/2021 12:10:38 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--------------------------------------------------------------------------------------- 
--Linked servers listing 
------------------------------------------------------------------------------------------- 
--Databases with data backup over 24 hours old 
CREATE PROC [dbo].[usp_GetLinked] (
 --@output char(1),  -- Not needed on this style.
 @TXTOUT NVARCHAR(MAX) OUTPUT,
 @O_Priority TINYINT OUTPUT
 )
AS
/*******************************************************************
--
--Create 3/29/2020 JmcBratnie
-- List of linked servers 
-- note two columns were null on my test might need to add them in
--
-- Modified
-- JMcBratnie 10/26/2020 Removed unused columns limit results to 
--                       new and updates linked servers
********************************************************************/

BEGIN
	SELECT @O_Priority = 91
    -- if no data skip output file
    IF NOT EXISTS(SELECT 'X'
					  FROM sys.Servers ss 
				 LEFT JOIN sys.linked_logins sl 
						ON ss.server_id = sl.server_id 
				 LEFT JOIN sys.server_principals ssp 
						ON ssp.principal_id = sl.local_principal_id  
				WHERE ss.modify_date >= DATEADD(DD,-1,GETDATE()))
		BEGIN
			PRINT 'No matching row exists'
			select @TXTOUT =  cast('<h2> NO NEW Linked Servers </h2>' as NVARCHAR(MAX));
		END
	ELSE
		BEGIN
			-- Generate the output 	
			select @TXTOUT =  cast('<h2>NEW Linked Servers: </h2>' as NVARCHAR(MAX));
			select @TXTOUT = @TXTOUT + cast('<table border="1" width="100%" style="border-collapse:collapse;">
				<col style="width:8%">
				<col style="width:20%">
				<col style="width:13%">
				<col style="width:12%">
				<col style="width:13%">
				<col style="width:7%">
				<col style="width:7%">
				<col style="width:20%">
				<tr><th>Server ID</th>
				<th>Name</th>
				<th>Type</th>
				<th>Product</th>
				<th>Login</th>
				<th>RPC Enabled</th>
				<th>Data Access</th>
				<th>Modified</th></tr>' as NVARCHAR(MAX));



			SELECT @TXTOUT = @TXTOUT + 
			cast('<tr><td>' as NVARCHAR(MAX)) 
			+ convert(NVARCHAR(MAX),ss.server_id) + cast('</td><td>' as NVARCHAR(MAX)) 
			+ cast(ss.name as NVARCHAR(MAX)) + cast('</td><td>' as NVARCHAR(MAX)) 
			+ cast(Case ss.Server_id 
						when 0 then 'Current Server' 
						else 'Remote Server' 
						end as NVARCHAR(MAX)) + cast('</td><td>' as NVARCHAR(MAX)) 
			+ cast(isnull(ss.product,' ') AS  NVARCHAR(MAX)) + cast('</td><td>' as NVARCHAR(MAX)) 
			+ cast(case isnull(sl.uses_self_credential, ' ') 
						when 1 then 'Uses Self Credentials (local)'
						when ' ' then cast(isnull(sl.remote_name, ' ')+'(remote)' AS NVARCHAR(MAX))
						else ssp.name 
						end AS NVARCHAR(MAX)) + cast('</td><td>' as NVARCHAR(MAX)) 
			+ cast(case ss.is_rpc_out_enabled 
						when 1 then 'True' 
						else 'False' 
						end  AS NVARCHAR(MAX)) + cast('</td><td>' as NVARCHAR(MAX)) 
			+ cast(case ss.is_data_access_enabled 
						when 1 then 'True' 
						else 'False' 
						end AS NVARCHAR(MAX))+ cast('</td><td>' as NVARCHAR(MAX)) 
			+ convert(NVARCHAR(MAX), ss.modify_date, 22) + cast('</td></tr>' as NVARCHAR(Max)) 
			FROM sys.Servers ss 
			 LEFT JOIN sys.linked_logins sl 
				ON ss.server_id = sl.server_id 
			 LEFT JOIN sys.server_principals ssp 
				ON ssp.principal_id = sl.local_principal_id
			--where is_linked = 1 -- Need to run this on a work server to see if it is needed
			WHERE ss.modify_date >= DATEADD(DD,-1,GETDATE());

		END

   	select @TXTOUT = @TXTOUT + cast('</table>' as NVARCHAR(MAX));
		print @TXTOUT



END
GO

