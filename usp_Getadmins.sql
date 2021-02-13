

/****** Object:  StoredProcedure [dbo].[usp_Getadmins]    Script Date: 2/13/2021 12:14:39 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_Getadmins] (
 --@output char(1),  -- Not needed on this style.
 @TXTOUT NVARCHAR(MAX) OUTPUT,
 @O_Priority tinyint OUTPUT
 )
AS
/*******************************************************************
--
--Create 3/29/2020 JmcBratnie
-- Who has sysadmin or security Admin rights
--Update Corrected <h2>Title</h2> 
--
-- Modified 
-- JMcBratnie 10/26/2020 Fixed column width of dates 
								 and scoped results to create or updates
								 in past 24 hours
********************************************************************/

BEGIN
	select @O_Priority = 90;

    -- if no data skip the output
    IF NOT EXISTS(SELECT 'x'
					FROM sys.server_role_members rm
						,sys.server_principals sp
					WHERE rm.role_principal_id = SUSER_ID('Sysadmin')
						AND rm.member_principal_id = sp.principal_id
						AND ( sp.modify_date >= dateadd(DD,-1,getdate())
							OR sp.create_date >= dateadd(DD,-1,getdate())
							 )
				  UNION
				  SELECT 'x'
					FROM sys.server_role_members rm
						,sys.server_principals sp
					WHERE rm.role_principal_id = SUSER_ID('Securityadmin')
						AND rm.member_principal_id = sp.principal_id
						AND ( sp.modify_date >= dateadd(DD,-1,getdate())
							OR sp.create_date >= dateadd(DD,-1,getdate())
							 )
					)
		BEGIN
			select @TXTOUT =  cast('<h2> NO NEW SYSADMINs or SecurityAdmins </h2>' as NVARCHAR(MAX));

			PRINT 'No matching row exists'
		END
	ELSE
		BEGIN
		-- Generate the output 	
		select @TXTOUT =  cast('<h2> Users with elevated privileges: </h2>' as NVARCHAR(MAX));
		select @TXTOUT = @TXTOUT + cast('<table border="1" width="100%" style="border-collapse:collapse;">
		<caption style="caption-side:bottom; text-align:right">* denotes disabled accounts</caption>
		<col style="width:15%">
		<col style="width:20%">
		<col style="width:17%">
		<col style="width:17%">
		<col style="width:31%">
		
		<tr>
		<th>Access</th>
		<th>User</th>
		<th>Created</th>
		<th>Modified</th>
		<th></th>
		</tr>' as NVARCHAR(MAX));

                -- sysadmin
		select @TXTOUT = @TXTOUT +cast('<tr><td>' as NVARCHAR(MAX)) 
		  + cast(x.ACCESS as NVARCHAR(MAX)) + cast('</td><td>' as NVARCHAR(MAX)) 
		  + cast(x.Name as NVARCHAR(MAX)) + cast('</td><td>' as NVARCHAR(MAX)) 
		  + x.create_date+ cast('</td><td>' as NVARCHAR(MAX)) 
		  + x.Modifed_Date + cast('</td><td>' as NVARCHAR(MAX)) 
		  + cast(x.is_disabled as NVARCHAR(MAX)) 
		  + cast('</td></tr>' as NVARCHAR(Max))
		from (
		SELECT 1 as ord
			, 'SYSADMIN' AS 'ACCESS'
			, sp.NAME as 'Name'
			, CONVERT(nvarchar(20), sp.create_date, 22) AS Create_Date
			, CONVERT(nvarchar(20), sp.modify_date, 22) AS Modifed_Date
			, CASE sp.is_disabled 
			  WHEN 1 THEN '*'
			  WHEN 0 THEN ''
			  ELSE 'E'
			  END AS [Is_disabled]

		FROM sys.server_role_members rm
			,sys.server_principals sp
		WHERE rm.role_principal_id = SUSER_ID('Sysadmin')
			AND rm.member_principal_id = sp.principal_id
			AND ( sp.modify_date >= dateadd(DD,-1,getdate())
				OR sp.create_date >= dateadd(DD,-1,getdate())
			    )
		UNION
                -- Security admins
		SELECT 2 as ord
			, 'SECURITYADMIN' AS 'ACCESS'
			, sp.NAME as 'Name'
			, CONVERT(nvarchar(20), sp.create_date, 22) AS Create_Date
			, CONVERT(nvarchar(20), sp.modify_date, 22) AS Modifed_Date
			, CASE sp.is_disabled 
			  WHEN 1 THEN '*'
			  WHEN 0 THEN ''
			  ELSE 'E'
			  END AS [Is_disabled]
		FROM sys.server_role_members rm
			,sys.server_principals sp
		WHERE rm.role_principal_id = SUSER_ID('Securityadmin')
			AND rm.member_principal_id = sp.principal_id
			AND ( sp.modify_date >= dateadd(DD,-1,getdate())
				OR sp.create_date >= dateadd(DD,-1,getdate())
			    )

		) x
		Order by x.ord, x.Name

--		select @TXTOUT = @TXTOUT + cast('</table><p>* denotes disabled accounts</p>' as NVARCHAR(MAX));
		select @TXTOUT = @TXTOUT + cast('</table>' as NVARCHAR(MAX));
	END
END
GO

