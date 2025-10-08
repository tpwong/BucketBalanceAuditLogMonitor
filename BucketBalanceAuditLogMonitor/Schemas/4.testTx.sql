BEGIN;

-- ���E 1: ����һ�P adjust ���׼o�
INSERT INTO earning.bucket_adjust_transactions 
    (id, gaming_dt, amount, reason) 
VALUES 
    (9001, now()::date, -50.00, '�����e�`���c');
-- >> �˕r��adjust_store_source_trigger �|�l��

-- ���E 2: �������� bucket balance
UPDATE earning.bucket_balances 
SET total = total - 50.00 
WHERE id = 123;
-- >> �˕r��log_balance_change_with_context �|�l��

COMMIT;





BEGIN;

-- ���E 1: ����һ�P earned ���׼o�
INSERT INTO earning.bucket_earned_transactions 
    (tran_id, bucket_type, main_id, earning_rule_id, gaming_dt, amount) 
VALUES 
    ('EARN-001', 'GENERAL', 999, 88, now()::date, 150.00);
-- >> �˕r��earned_store_source_trigger �|�l������Դ�YӍ������׃����

-- ���E 2: �������� bucket balance
UPDATE earning.bucket_balances 
SET total = total + 150.00 
WHERE id = 123;
-- >> �˕r��log_balance_change_with_context �|�l���xȡ��׃���K����������I��

COMMIT;





BEGIN;

-- ֱ�Ӹ����N�~���]��ǰ�õā�Դ����
UPDATE earning.bucket_balances 
SET total = total + 25.00 -- ���O��һ�PС�~�a��
WHERE id = 123;
-- >> �˕r��log_balance_change_with_context �|�l�������Ҳ�����׃����

COMMIT;