USE [FinalProject]
GO

/****** Object:  UserDefinedFunction [dbo].[is_valid_iranian_national_code]    Script Date: 1/25/2024 11:00:14 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[is_valid_iranian_national_code](@input NVARCHAR(10))
RETURNS BIT AS
BEGIN
  DECLARE @i INT = 1, @s INT = 0, @check INT, @result BIT;
  
  IF NOT @input LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' 
    SET @result = 0;
  ELSE
    BEGIN
      WHILE @i < 10
      BEGIN
        SET @s = @s + (11 - @i) * CAST(SUBSTRING(@input, @i, 1) AS INT);
        SET @i = @i + 1;
      END;
      SET @s = @s % 11;
      SET @check = CAST(SUBSTRING(@input, LEN(@input), 1) AS INT);
      IF @s < 2 
        SET @result = CASE WHEN @check = @s THEN 1 ELSE 0 END;
      ELSE
        SET @result = CASE WHEN @check + @s = 11 THEN 1 ELSE 0 END;
    END
  RETURN @result;
END;
GO


