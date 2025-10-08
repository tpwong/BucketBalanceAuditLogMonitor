-- ====================================================================
-- Step 1: Safely drop the old parent table and all its child partitions
-- Using CASCADE will remove all dependent objects, ensuring complete cleanup
-- ====================================================================
DROP TABLE IF EXISTS earning.bucket_balance_audit_log CASCADE;

-- ====================================================================
-- Step 2: Recreate the partitioned parent table, including operator_account field
-- ====================================================================
CREATE TABLE earning.bucket_balance_audit_log (
    -- Unique ID for the audit log itself
    id bigserial NOT NULL,
    
    -- Timestamp when the audit event occurred, this will be our partition key
    audit_timestamp timestamptz NOT NULL DEFAULT now(),
    
    -- Operation type (INSERT, UPDATE, DELETE)
    action varchar(10) NOT NULL,
    
    -- Primary key of the audited record (bucket_balance.id)
    record_id bigint NOT NULL,
    
    -- Record balance before change
    old_balance numeric(19, 9),
    
    -- Record balance after change
    new_balance numeric(19, 9),
    
    -- Difference amount for this change
    delta_balance numeric(19, 9) NOT NULL,
    
    -- Source table name that triggered this balance change
    source_table_name varchar(100),
    
    -- Primary key of the source table record
    source_record_pk jsonb,

    -- Operator account that performed this change
    operator_account varchar(100),

    -- Define primary key constraint at the end, including partition key
    PRIMARY KEY (id, audit_timestamp)
)
PARTITION BY RANGE (audit_timestamp);

CREATE INDEX idx_bbal_record_id ON earning.bucket_balance_audit_log (record_id);
CREATE INDEX idx_bbal_source_pk_gin ON earning.bucket_balance_audit_log USING gin (source_record_pk);
CREATE INDEX idx_bbal_operator_account ON earning.bucket_balance_audit_log (operator_account);

COMMENT ON TABLE earning.bucket_balance_audit_log IS '[Partitioned Parent Table] Audit log recording changes to bucket_balances table. Data is stored monthly in child partitions.';
COMMENT ON COLUMN earning.bucket_balance_audit_log.audit_timestamp IS 'Audit event timestamp, also the partition key for this table.';
COMMENT ON COLUMN earning.bucket_balance_audit_log.source_table_name IS 'Name of the source table that triggered this balance change.';
COMMENT ON COLUMN earning.bucket_balance_audit_log.source_record_pk IS 'Primary key of the source table record (usually in JSONB format).';
COMMENT ON COLUMN earning.bucket_balance_audit_log.operator_account IS 'Operator account that performed this change (e.g., backend admin ID or system process name).';


-- ====================================================================
-- Step 3: Automated script to create all monthly partitions from 2025-06 to 2030-12
-- ====================================================================
DO $$
DECLARE
    -- Set start and end months for partition creation (using first day of month)
    v_start_month date := '2025-06-01';
    v_end_month   date := '2030-12-01';
    
    -- Loop variables
    v_current_month date := v_start_month;
    v_partition_name text;
    v_partition_start text;
    v_partition_end text;
BEGIN
    RAISE NOTICE 'Starting creation of monthly partitions from % to %...', to_char(v_start_month, 'YYYY-MM'), to_char(v_end_month, 'YYYY-MM');

    -- Loop through each month
    WHILE v_current_month <= v_end_month LOOP
        -- Generate partition name in format: bbal_log_YYYYMM (e.g., bbal_log_202506)
        v_partition_name := 'bbal_log_' || to_char(v_current_month, 'YYYYMM');
        
        -- Define partition start range (inclusive)
        v_partition_start := to_char(v_current_month, 'YYYY-MM-DD');
        
        -- Define partition end range (exclusive), first day of next month
        v_partition_end := to_char(v_current_month + interval '1 month', 'YYYY-MM-DD');
        
        -- Output information about partition being created
        RAISE NOTICE '  -> Creating partition earning.% FOR VALUES FROM ''%'' TO ''%'';', v_partition_name, v_partition_start, v_partition_end;
        
        -- Use format() function to safely execute dynamic SQL
        EXECUTE format(
            'CREATE TABLE earning.%I PARTITION OF earning.bucket_balance_audit_log FOR VALUES FROM (%L) TO (%L);',
            v_partition_name,
            v_partition_start,
            v_partition_end
        );
        
        -- Advance current month to first day of next month
        v_current_month := v_current_month + interval '1 month';
    END LOOP;

    RAISE NOTICE 'All monthly partitions created successfully!';
END;
$$;