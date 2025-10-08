-- 為了確保是全新的開始，先刪除舊表和相關函式
DROP TABLE IF EXISTS earning.bucket_balance_audit_log;

-- 建立分區父表 (Partitioned Table)
CREATE TABLE earning.bucket_balance_audit_log (
    -- 稽核日誌自身的唯一ID
    id bigserial NOT NULL,
    
    -- 稽核事件發生的時間，這將是我們的分區鍵 (Partition Key)
    audit_timestamp timestamptz NOT NULL DEFAULT now(),
    
    -- 操作類型 (INSERT, UPDATE, DELETE)
    action varchar(10) NOT NULL,
    
    -- 被稽核的紀錄的主鍵 (bucket_balance.id)
    record_id bigint NOT NULL,
    
    -- 紀錄變更前的金額
    old_balance numeric(19, 9),
    
    -- 紀錄變更後的金額
    new_balance numeric(19, 9),
    
    -- 紀錄此次變更的差額
    delta_balance numeric(19, 9) NOT NULL,
    
    -- 觸發此次餘額變動的來源資料表名稱
    source_table_name varchar(100),
    
    -- 來源資料表紀錄的主鍵
    source_record_pk jsonb,

    -- 將主鍵約束定義在最後，並包含分區鍵
    PRIMARY KEY (id, audit_timestamp)
)
PARTITION BY RANGE (audit_timestamp);

-- 建立索引 (這些索引會自動應用到所有子分區)
CREATE INDEX idx_bbal_record_id ON earning.bucket_balance_audit_log (record_id);
CREATE INDEX idx_bbal_source_pk_gin ON earning.bucket_balance_audit_log USING gin (source_record_pk);

COMMENT ON TABLE earning.bucket_balance_audit_log IS '【分區父表】記錄 bucket_balances 表變更的稽核日誌。資料按日儲存在子分區中。';
COMMENT ON COLUMN earning.bucket_balance_audit_log.audit_timestamp IS '稽核事件時間戳，同時也是此表的分區鍵。';
