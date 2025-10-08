-- 新的、簡化的函式，只負責寫入日誌
CREATE OR REPLACE FUNCTION earning.log_balance_change_with_context()
RETURNS TRIGGER AS $$
DECLARE
    v_record_id BIGINT;
    v_delta_balance NUMERIC(19, 9);
    v_source_info JSONB;
    v_source_table_name TEXT;
    v_source_pk JSONB;
BEGIN
    -- 確定被操作的紀錄ID
    IF (TG_OP = 'DELETE') THEN
        v_record_id := OLD.id;
    ELSE
        v_record_id := NEW.id;
    END IF;

    -- 計算餘額變化量
    v_delta_balance := COALESCE(NEW.total, 0) - COALESCE(OLD.total, 0);

    -- 嘗試讀取事務級別的變數 (讀取 "紙條")
    v_source_info := current_setting('my_app.source_info', true)::JSONB;

    -- 從變數中解析來源表名和主鍵
    IF v_source_info IS NOT NULL THEN
        v_source_table_name := v_source_info ->> 'source_table';
        v_source_pk := v_source_info -> 'source_pk';
    END IF;

    -- *** 核心職責：將所有資訊寫入稽核日誌表 ***
    -- PostgreSQL 會自動將這筆紀錄插入到正確的日期子分區中
    INSERT INTO earning.bucket_balance_audit_log (
        action,
        record_id,
        old_balance,
        new_balance,
        delta_balance,
        source_table_name,
        source_record_pk
    ) VALUES (
        TG_OP,
        v_record_id,
        OLD.total,
        NEW.total,
        v_delta_balance,
        v_source_table_name, -- 如果沒有來源，這裡會是 NULL
        v_source_pk          -- 如果沒有來源，這裡會是 NULL
    );

    -- 通知邏輯已完全移除

    -- 返回以完成觸發器操作
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