BEGIN;
-- 步驟 2: 插入一筆 adjust 交易紀錄
INSERT INTO earning.bucket_adjust_transactions
    (acct, gaming_dt, bucket_name, bucket_type, amount, remark)
VALUES
    ('ACCT-12345', now()::date, 'General Points', 'POINTS', 25.00, '客戶投訴補償');
-- >> trigger_store_source_adjust 觸發。

-- 步驟 3: 更新對應的 bucket balance
UPDATE earning.bucket_balances 
SET total = total + 25.00 
WHERE acct = 'ACCT-12345' 
  AND bucket_type = 'POINTS' 
  AND bucket_name = 'General Points'
  AND expiry_date IS NULL;
-- >> trigger_log_balance_change 觸發。

COMMIT;


BEGIN;
-- 步驟 2: 插入一筆 redeem 交易紀錄
-- redeem 表中的 amount 通常記錄為正數，表示兌換的價值
INSERT INTO earning.bucket_redeem_transactions
    (id, acct, prize_code, gaming_dt, bucket_type, amount, post_dtm)
VALUES
    (uuid_generate_v4(), 'ACCT-12345', 'PRIZE-COFFEE', now()::date, 'POINTS', 50.00, now());
-- >> trigger_store_source_redeem 觸發。

-- 步驟 3: 更新對應的 bucket balance (扣除點數)
UPDATE earning.bucket_balances 
SET total = total - 50.00 
WHERE acct = 'ACCT-12345' 
  AND bucket_type = 'POINTS' 
  AND bucket_name = 'General Points'
  AND expiry_date IS NULL;
-- >> trigger_log_balance_change 觸發。

COMMIT;










BEGIN;
-- 步驟 2: 插入一筆 earned 交易紀錄
-- 注意：這裡的欄位完全對應您提供的 schema
INSERT INTO earning.bucket_earned_transactions 
    (tran_id, bucket_type, category, gaming_dt, acct, earned, main_id, earning_rule_id) 
VALUES 
    (1001, 'POINTS', 'BONUS', now()::date, 'ACCT-12345', 150.00, 'MAIN-999', 'RULE-WELCOME-BONUS');
-- >> trigger_store_source_earned 觸發，將這筆交易的複合主鍵寫入事務變數。

-- 步驟 3: 更新對應的 bucket balance
UPDATE earning.bucket_balances 
SET total = total + 150.00 
WHERE acct = 'ACCT-12345' 
  AND bucket_type = 'POINTS' 
  AND bucket_name = 'General Points'
  AND expiry_date IS NULL; -- 使用唯一約束的欄位來精確定位
-- >> trigger_log_balance_change 觸發，讀取事務變數並寫入稽核日誌。

COMMIT;