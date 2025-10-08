-- ��ʽ������Դ����YӍ���浽�ռ��e��׃����
-- �@����ʽ���ֲ�׃��������Ć�һ؟���úܺá�
CREATE OR REPLACE FUNCTION public.store_source_transaction_info()
RETURNS TRIGGER AS $$
DECLARE
    pk_json JSONB;
    payload JSONB;
BEGIN
    -- ������ͬ�ı�Y�������������� PK JSON ���
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

    -- ���������� payload
    payload := jsonb_build_object(
        'source_table', TG_TABLE_NAME,
        'source_pk', pk_json
    );

    -- �� payload �������� 'my_app.source_info' ���ռ��e׃����
    PERFORM set_config('my_app.source_info', payload::TEXT, true);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;




-- 1. ��������Դ���Ͻ����|�l��
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