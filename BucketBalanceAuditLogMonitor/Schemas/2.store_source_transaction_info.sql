CREATE OR REPLACE FUNCTION earning.store_source_info_from_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_pk_info JSONB;
    v_pk_columns TEXT[] := TG_ARGV; -- 直接獲取所有參數作為欄位名陣列
BEGIN
    -- 動態地從 NEW 紀錄中，根據傳入的欄位名列表，建立一個 JSON 物件
    SELECT jsonb_object_agg(key, value)
    INTO v_pk_info
    FROM jsonb_each_text(to_jsonb(NEW)) AS j(key, value)
    WHERE j.key = ANY(v_pk_columns);

    -- 如果成功產生了 JSON，才設定事務變數
    IF v_pk_info IS NOT NULL AND v_pk_info != '{}'::jsonb THEN
        PERFORM set_config('my_app.source_info', jsonb_build_object(
            'source_table', TG_TABLE_NAME, -- 記錄實際的子表名，這很好！
            'source_pk', v_pk_info
        )::text, false);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;




-- 1. 在三個來源表上建立觸發器
-- 為 bucket_earned_transactions 綁定觸發器
DROP TRIGGER IF EXISTS trigger_store_source_earned ON earning.bucket_earned_transactions;
CREATE TRIGGER trigger_store_source_earned
BEFORE INSERT ON earning.bucket_earned_transactions
FOR EACH ROW
EXECUTE FUNCTION earning.store_source_info_from_trigger(
    'tran_id', 'bucket_type', 'main_id', 'earning_rule_id', 'gaming_dt'
);

-- 為 bucket_redeem_transactions 綁定觸發器
DROP TRIGGER IF EXISTS trigger_store_source_redeem ON earning.bucket_redeem_transactions;
CREATE TRIGGER trigger_store_source_redeem
BEFORE INSERT ON earning.bucket_redeem_transactions
FOR EACH ROW
EXECUTE FUNCTION earning.store_source_info_from_trigger(
    'id', 'gaming_dt'
);

-- 為 bucket_adjust_transactions 綁定觸發器
DROP TRIGGER IF EXISTS trigger_store_source_adjust ON earning.bucket_adjust_transactions;
CREATE TRIGGER trigger_store_source_adjust
BEFORE INSERT ON earning.bucket_adjust_transactions
FOR EACH ROW
EXECUTE FUNCTION earning.store_source_info_from_trigger(
    'id', 'gaming_dt'
);