-- Updated function with added logic to read and write operator account
CREATE OR REPLACE FUNCTION earning.log_balance_change_with_context()
RETURNS TRIGGER AS $$
DECLARE
    v_record_id BIGINT;
    v_delta_balance NUMERIC(19, 9);
    v_source_info JSONB;
    v_source_table_name TEXT;
    v_source_pk JSONB;
    -- New variable to store operator account
    v_operator_account TEXT; 
BEGIN
    -- Determine the record ID being operated on
    IF (TG_OP = 'DELETE') THEN
        v_record_id := OLD.id;
    ELSE
        v_record_id := NEW.id;
    END IF;

    -- Calculate balance change amount
    v_delta_balance := COALESCE(NEW.total, 0) - COALESCE(OLD.total, 0);

    -- Attempt to read transaction-level variable (source transaction info)
    v_source_info := current_setting('earning_module.source_info', true)::JSONB;

    -- *** NEW LOGIC: Attempt to read operator account ***
    -- We use a new key 'earning_module.operator_account'
    v_operator_account := current_setting('earning_module.operator_account', true); -- true means no error if not set

    -- Parse source table name and primary key from the variable
    IF v_source_info IS NOT NULL THEN
        v_source_table_name := v_source_info ->> 'source_table';
        v_source_pk := v_source_info -> 'source_pk';
    END IF;

    BEGIN
        -- Attempt to write to audit log
        INSERT INTO earning.bucket_balance_audit_log (
            action,
            record_id,
            old_balance,
            new_balance,
            delta_balance,
            source_table_name,
            source_record_pk,
            operator_account
        ) VALUES (
            TG_OP,
            v_record_id,
            OLD.total,
            NEW.total,
            v_delta_balance,
            v_source_table_name,
            v_source_pk,
            v_operator_account
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'AUDIT LOGGING FAILED: Could not write to bucket_balance_audit_log. Error: [%], Message: [%]', SQLSTATE, SQLERRM;
            RAISE NOTICE 'AUDIT DATA (Lost): record_id=%, delta=%, source_table=%, source_pk=%, operator=%', v_record_id, v_delta_balance, v_source_table_name, v_source_pk, v_operator_account;
    END;

    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- 2. Create trigger on bucket_balances table pointing to the new, simplified logging function
DROP TRIGGER IF EXISTS bucket_balances_audit_trigger ON earning.bucket_balances;
CREATE TRIGGER bucket_balances_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON earning.bucket_balances
FOR EACH ROW EXECUTE FUNCTION earning.log_balance_change_with_context();