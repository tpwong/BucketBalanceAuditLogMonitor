CREATE OR REPLACE FUNCTION earning.store_source_info_from_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_pk_info JSONB;
    v_pk_columns TEXT[] := TG_ARGV; -- ֱ�ӫ@ȡ���Ѕ��������λ�����
BEGIN
    -- �ӑB�؏� NEW �o��У���������ę�λ���б�����һ�� JSON ���
    SELECT jsonb_object_agg(key, value)
    INTO v_pk_info
    FROM jsonb_each_text(to_jsonb(NEW)) AS j(key, value)
    WHERE j.key = ANY(v_pk_columns);

    -- ����ɹ��a���� JSON�����O����׃��
    IF v_pk_info IS NOT NULL AND v_pk_info != '{}'::jsonb THEN
        PERFORM set_config('my_app.source_info', jsonb_build_object(
            'source_table', TG_TABLE_NAME, -- ӛ䛌��H���ӱ������@�ܺã�
            'source_pk', v_pk_info
        )::text, false);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;




-- 1. ��������Դ���Ͻ����|�l��
-- �� bucket_earned_transactions �����|�l��
DROP TRIGGER IF EXISTS trigger_store_source_earned ON earning.bucket_earned_transactions;
CREATE TRIGGER trigger_store_source_earned
BEFORE INSERT ON earning.bucket_earned_transactions
FOR EACH ROW
EXECUTE FUNCTION earning.store_source_info_from_trigger(
    'tran_id', 'bucket_type', 'main_id', 'earning_rule_id', 'gaming_dt'
);

-- �� bucket_redeem_transactions �����|�l��
DROP TRIGGER IF EXISTS trigger_store_source_redeem ON earning.bucket_redeem_transactions;
CREATE TRIGGER trigger_store_source_redeem
BEFORE INSERT ON earning.bucket_redeem_transactions
FOR EACH ROW
EXECUTE FUNCTION earning.store_source_info_from_trigger(
    'id', 'gaming_dt'
);

-- �� bucket_adjust_transactions �����|�l��
DROP TRIGGER IF EXISTS trigger_store_source_adjust ON earning.bucket_adjust_transactions;
CREATE TRIGGER trigger_store_source_adjust
BEFORE INSERT ON earning.bucket_adjust_transactions
FOR EACH ROW
EXECUTE FUNCTION earning.store_source_info_from_trigger(
    'id', 'gaming_dt'
);