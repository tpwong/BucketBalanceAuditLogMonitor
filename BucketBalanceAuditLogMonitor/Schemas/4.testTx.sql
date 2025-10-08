BEGIN;

-- 步驟 1: 插入一筆 adjust 交易紀錄
INSERT INTO earning.bucket_adjust_transactions 
    (id, gaming_dt, amount, reason) 
VALUES 
    (9001, now()::date, -50.00, '修正錯誤派點');
-- >> 此時，adjust_store_source_trigger 觸發。

-- 步驟 2: 更新對應的 bucket balance
UPDATE earning.bucket_balances 
SET total = total - 50.00 
WHERE id = 123;
-- >> 此時，log_balance_change_with_context 觸發。

COMMIT;





BEGIN;

-- 步驟 1: 插入一筆 earned 交易紀錄
INSERT INTO earning.bucket_earned_transactions 
    (tran_id, bucket_type, main_id, earning_rule_id, gaming_dt, amount) 
VALUES 
    ('EARN-001', 'GENERAL', 999, 88, now()::date, 150.00);
-- >> 此時，earned_store_source_trigger 觸發，將來源資訊寫入事務變數。

-- 步驟 2: 更新對應的 bucket balance
UPDATE earning.bucket_balances 
SET total = total + 150.00 
WHERE id = 123;
-- >> 此時，log_balance_change_with_context 觸發，讀取事務變數並寫入稽核日誌。

COMMIT;





BEGIN;

-- 直接更新餘額，沒有前置的來源交易
UPDATE earning.bucket_balances 
SET total = total + 25.00 -- 假設是一筆小額補償
WHERE id = 123;
-- >> 此時，log_balance_change_with_context 觸發，但它找不到事務變數。

COMMIT;