BEGIN;
-- ���E 2: ����һ�P adjust ���׼o�
INSERT INTO earning.bucket_adjust_transactions
    (acct, gaming_dt, bucket_name, bucket_type, amount, remark)
VALUES
    ('ACCT-12345', now()::date, 'General Points', 'POINTS', 25.00, '�͑�Ͷ�V�a��');
-- >> trigger_store_source_adjust �|�l��

-- ���E 3: �������� bucket balance
UPDATE earning.bucket_balances 
SET total = total + 25.00 
WHERE acct = 'ACCT-12345' 
  AND bucket_type = 'POINTS' 
  AND bucket_name = 'General Points'
  AND expiry_date IS NULL;
-- >> trigger_log_balance_change �|�l��

COMMIT;


BEGIN;
-- ���E 2: ����һ�P redeem ���׼o�
-- redeem ���е� amount ͨ��ӛ䛞���������ʾ���Q�ărֵ
INSERT INTO earning.bucket_redeem_transactions
    (id, acct, prize_code, gaming_dt, bucket_type, amount, post_dtm)
VALUES
    (uuid_generate_v4(), 'ACCT-12345', 'PRIZE-COFFEE', now()::date, 'POINTS', 50.00, now());
-- >> trigger_store_source_redeem �|�l��

-- ���E 3: �������� bucket balance (�۳��c��)
UPDATE earning.bucket_balances 
SET total = total - 50.00 
WHERE acct = 'ACCT-12345' 
  AND bucket_type = 'POINTS' 
  AND bucket_name = 'General Points'
  AND expiry_date IS NULL;
-- >> trigger_log_balance_change �|�l��

COMMIT;










BEGIN;
-- ���E 2: ����һ�P earned ���׼o�
-- ע�⣺�@�e�ę�λ��ȫ�������ṩ�� schema
INSERT INTO earning.bucket_earned_transactions 
    (tran_id, bucket_type, category, gaming_dt, acct, earned, main_id, earning_rule_id) 
VALUES 
    (1001, 'POINTS', 'BONUS', now()::date, 'ACCT-12345', 150.00, 'MAIN-999', 'RULE-WELCOME-BONUS');
-- >> trigger_store_source_earned �|�l�����@�P���׵��}�����I������׃����

-- ���E 3: �������� bucket balance
UPDATE earning.bucket_balances 
SET total = total + 150.00 
WHERE acct = 'ACCT-12345' 
  AND bucket_type = 'POINTS' 
  AND bucket_name = 'General Points'
  AND expiry_date IS NULL; -- ʹ��Ψһ�s���ę�λ���_��λ
-- >> trigger_log_balance_change �|�l���xȡ��׃���K����������I��

COMMIT;