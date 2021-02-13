
/****** Object:  StoredProcedure [dbo].[usp_Getdumps]    Script Date: 2/13/2021 12:14:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_Getdumps] (
 --@output char(1),  -- Not needed on this style.
 @TXTOUT NVARCHAR(MAX) OUTPUT,
 @O_Priority tinyint OUTPUT
 )
AS
/*******************************************************************
--
--Create 3/29/2020 JmcBratnie
-- Did SQL server have major issues and create a dump file
--
********************************************************************/

BEGIN
	select @O_Priority = 11;
    -- if not data skip the output file
    IF NOT EXISTS(SELECT 'X' 
					FROM sys.dm_server_memory_dumps SMD
					WHERE SMD.creation_time > getdate() - 1)
		BEGIN
			PRINT 'No matching row exists'
			select @TXTOUT =  cast('<h2> NO Dumps have occured: </h2>' as NVARCHAR(MAX));
			select @TXTOUT = N'';
		END
	ELSE
		BEGIN
			-- Generate the output 	
			select @TXTOUT =  cast('<h2> Dumps have occured: </h2>' as NVARCHAR(MAX));
		select @TXTOUT = @TXTOUT + cast('<table border="1" width="100%" style="border-collapse:collapse;">
		<col style="width:12%">
		<col style="width:12%">
		<col style="width:76%">
		
		<tr>
		<th>Occured</th>
		<th>Size</th>
		<th>File Name</th>
		<th></th>
		</tr>' as NVARCHAR(MAX));



			/*select @TXTOUT = @TXTOUT + cast('<ul>' as NVARCHAR(MAX)); -- not needed any longer*/

			SELECT @TXTOUT = @TXTOUT +cast('<tr><td>' as NVARCHAR(MAX)) + CONVERT(nvarchar(20), SMD.creation_time, 22) + cast('</td><td>' as NVARCHAR(MAX)) + cast(SMD.size_in_bytes as NVARCHAR(MAX)) + cast('</td><td>' as NVARCHAR(MAX)) + CAST(SMD.filename as NVARCHAR(MAX)) + cast('</td></tr>' as NVARCHAR(Max))
			FROM sys.dm_server_memory_dumps SMD
			WHERE SMD.creation_time > getdate() - 1

			select @TXTOUT = @TXTOUT + cast('</table>' as NVARCHAR(MAX));

		END
END 
GO

