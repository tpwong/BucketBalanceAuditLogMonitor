-- 函式：將來源表的資訊儲存到事務級別的變數中
-- 這個函式保持不變，因為它的單一職責做得很好。
CREATE OR REPLACE FUNCTION public.store_source_transaction_info()
RETURNS TRIGGER AS $$
DECLARE
    pk_json JSONB;
    payload JSONB;
BEGIN
    -- 根據不同的表結構，建立對應的 PK JSON 物件
    IF (TG_TABLE_NAME = 'bucket_earned_transactions') THEN
        pk_json := jsonb_build_object(
            'tran_id', NEW.tran_id,
            'bucket_type', NEW.bucket_type,
            'main_id', NEW.main_id,
            'earning_rule_id', NEW.earning_rule_id,
            'gaming_dt', NEW.gaming_dt
        );
    ELSIF (TG_TABLE_NAME = 'bucket_redeem_transactions') THEN
        pk_json := jsonb_build_object(
            'id', NEW.id,
            'gaming_dt', NEW.gaming_dt
        );
    ELSIF (TG_TABLE_NAME = 'bucket_adjust_transactions') THEN
        pk_json := jsonb_build_object(
            'id', NEW.id,
            'gaming_dt', NEW.gaming_dt
        );
    END IF;

    -- 建立完整的 payload
    payload := jsonb_build_object(
        'source_table', TG_TABLE_NAME,
        'source_pk', pk_json
    );

    -- 將 payload 存入名為 'my_app.source_info' 的事務級別變數中
    PERFORM set_config('my_app.source_info', payload::TEXT, true);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;




-- 1. 在三個來源表上建立觸發器
DROP TRIGGER IF EXISTS earned_store_source_trigger ON earning.bucket_earned_transactions;
CREATE TRIGGER earned_store_source_trigger
AFTER INSERT ON earning.bucket_earned_transactions
FOR EACH ROW EXECUTE FUNCTION public.store_source_transaction_info();

DROP TRIGGER IF EXISTS redeem_store_source_trigger ON earning.bucket_redeem_transactions;
CREATE TRIGGER redeem_store_source_trigger
AFTER INSERT ON earning.bucket_redeem_transactions
FOR EACH ROW EXECUTE FUNCTION public.store_source_transaction_info();

DROP TRIGGER IF EXISTS adjust_store_source_trigger ON earning.bucket_adjust_transactions;
CREATE TRIGGER adjust_store_source_trigger
AFTER INSERT ON earning.bucket_adjust_transactions
FOR EACH ROW EXECUTE FUNCTION public.store_source_transaction_info();