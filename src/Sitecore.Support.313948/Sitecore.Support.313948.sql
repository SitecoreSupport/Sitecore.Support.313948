SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Add_Personalization]
  @Date DATE,
  @RuleSetId UNIQUEIDENTIFIER,
  @RuleId UNIQUEIDENTIFIER,
  @TestSetId UNIQUEIDENTIFIER,
  @TestValues BINARY (16),
  @Visits BIGINT,
  @Value BIGINT,
  @Visitors BIGINT,
  @IsDefault BIT 
WITH EXECUTE AS OWNER
AS
BEGIN

  SET NOCOUNT ON;
  
  BEGIN TRY

  MERGE
    [Fact_Personalization] AS [target]
  USING
  (
    VALUES
    (
      @Date,
      @RuleSetId,
      @RuleId,
      @TestSetId,
      @TestValues,
      @Visits,
      @Value,
      @Visitors,
	  @IsDefault
    )
  )
  AS [source]
  (
    [Date],
    [RuleSetId],
    [RuleId],
    [TestSetId],
    [TestValues],
    [Visits],
    [Value],
    [Visitors],
	[IsDefault]
  )
  ON
    ([target].[Date] = [source].[Date]) AND
    ([target].[RuleSetId] = [source].[RuleSetId]) AND
    ([target].[RuleId] = [source].[RuleId]) AND
    ([target].[TestSetId] = [source].[TestSetId]) AND
	([target].[TestValues] = [source].[TestValues]) and
	([target].[IsDefault] = [source].[IsDefault])

  WHEN MATCHED THEN
    UPDATE
      SET
        [target].[Visits] = ([target].[Visits] + [source].[Visits]),
        [target].[Value] = ([target].[Value] + [source].[Value]),
        [target].[Visitors] = ([target].[Visitors] + [source].[Visitors])

  WHEN NOT MATCHED THEN
    INSERT
    (
      [Date],
      [RuleSetId],
      [RuleId],
      [TestSetId],
      [TestValues],
      [Visits],
      [Value],
      [Visitors],
	  [IsDefault]
    )
    VALUES
    (
      [source].[Date],
      [source].[RuleSetId],
      [source].[RuleId],
      [source].[TestSetId],
      [source].[TestValues],
      [source].[Visits],
      [source].[Value],
      [source].[Visitors],
	  [source].[IsDefault]
    );
  END TRY
  BEGIN CATCH

    DECLARE @error_number INTEGER = ERROR_NUMBER();
    DECLARE @error_severity INTEGER = ERROR_SEVERITY();
    DECLARE @error_state INTEGER = ERROR_STATE();
    DECLARE @error_message NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @error_procedure SYSNAME = ERROR_PROCEDURE();
    DECLARE @error_line INTEGER = ERROR_LINE();

    IF( @error_number = 2627 )
    BEGIN

      UPDATE
        [dbo].[Fact_Personalization]
      SET
        [Visits] = ([Visits] + @Visits),
        [Value] = ([Value] + @Value),
        [Visitors] = ([Visitors] + @Visitors)
      WHERE
        ([Date] = @Date) AND
		([RuleSetId] = @RuleSetId) AND
		([RuleId] = @RuleId) AND
		([TestSetId] = @TestSetId) AND
		([TestValues] = @TestValues) AND
	    ([IsDefault] = @IsDefault);

      IF( @@ROWCOUNT != 1 )
      BEGIN
        RAISERROR( 'Failed to insert or update rows in the [Fact_Personalization] table.', 18, 1 ) WITH NOWAIT;
      END

    END
    ELSE
    BEGIN

      RAISERROR( N'T-SQL ERROR %d, SEVERITY %d, STATE %d, PROCEDURE %s, LINE %d, MESSAGE: %s', @error_severity, 1, @error_number, @error_severity, @error_state, @error_procedure, @error_line, @error_message ) WITH NOWAIT;

    END;
  
  END CATCH;

END;