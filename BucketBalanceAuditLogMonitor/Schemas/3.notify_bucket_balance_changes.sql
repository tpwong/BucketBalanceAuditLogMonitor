-- 更新後的函式，增加了讀取和寫入操作人帳號的邏輯
CREATE OR REPLACE FUNCTION public.log_balance_change_with_context()
RETURNS TRIGGER AS $$
DECLARE
    v_record_id BIGINT;
    v_delta_balance NUMERIC(19, 9);
    v_source_info JSONB;
    v_source_table_name TEXT;
    v_source_pk JSONB;
    -- 新增變數來儲存操作人帳號
    v_operator_account TEXT; 
BEGIN
    -- 確定被操作的紀錄ID
    IF (TG_OP = 'DELETE') THEN
        v_record_id := OLD.id;
    ELSE
        v_record_id := NEW.id;
    END IF;

    -- 計算餘額變化量
    v_delta_balance := COALESCE(NEW.total, 0) - COALESCE(OLD.total, 0);

    -- 嘗試讀取事務級別的變數 (來源交易資訊)
    v_source_info := current_setting('my_app.source_info', true)::JSONB;

    -- *** 新增邏輯：嘗試讀取操作人帳號 ***
    -- 我們使用一個新的鍵 'my_app.operator_account'
    v_operator_account := current_setting('my_app.operator_account', true); -- true 表示如果沒設定也不會報錯

    -- 從變數中解析來源表名和主鍵
    IF v_source_info IS NOT NULL THEN
        v_source_table_name := v_source_info ->> 'source_table';
        v_source_pk := v_source_info -> 'source_pk';
    END IF;

    BEGIN
        -- 嘗試寫入稽核日誌
        INSERT INTO earning.bucket_balance_audit_log (
            action,
            record_id,
            old_balance,
            new_balance,
            delta_balance,
            source_table_name,
            source_record_pk,
            operator_account -- 新增欄位
        ) VALUES (
            TG_OP,
            v_record_id,
            OLD.total,
            NEW.total,
            v_delta_balance,
            v_source_table_name,
            v_source_pk,
            v_operator_account -- 新增的值
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


-- 2. 在 bucket_balances 表上建立觸發器，並指向新的、簡化的日誌函式
DROP TRIGGER IF EXISTS bucket_balances_audit_trigger ON earning.bucket_balances;
CREATE TRIGGER bucket_balances_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON earning.bucket_balances
FOR EACH ROW EXECUTE FUNCTION earning.log_balance_change_with_context();