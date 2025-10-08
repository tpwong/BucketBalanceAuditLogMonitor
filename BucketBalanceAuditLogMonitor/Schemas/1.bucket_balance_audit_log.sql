-- ====================================================================
-- 步驟一：建立分區父表 (若您已執行過，可跳過此部分)
-- ====================================================================

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

COMMENT ON TABLE earning.bucket_balance_audit_log IS '【分區父表】記錄 bucket_balances 表變更的稽核日誌。資料按月儲存在子分區中。';
COMMENT ON COLUMN earning.bucket_balance_audit_log.audit_timestamp IS '稽核事件時間戳，同時也是此表的分區鍵。';

RAISE NOTICE '父表 earning.bucket_balance_audit_log 建立完成。';


-- ====================================================================
-- 步驟二：自動化腳本，建立從 2025-06 到 2030-12 的所有月度分區
-- ====================================================================
DO $$
DECLARE
    -- 設定要建立分區的起始與結束月份 (取月份的第一天)
    v_start_month date := '2025-06-01';
    v_end_month   date := '2030-12-01';
    
    -- 用於迴圈的變數
    v_current_month date := v_start_month;
    v_partition_name text;
    v_partition_start text;
    v_partition_end text;
BEGIN
    RAISE NOTICE '開始建立從 % 到 % 的月度分區...', to_char(v_start_month, 'YYYY-MM'), to_char(v_end_month, 'YYYY-MM');

    -- 迴圈遍歷每個月
    WHILE v_current_month <= v_end_month LOOP
        -- 產生分區的名稱，格式為：bbal_log_YYYYMM (例如：bbal_log_202506)
        v_partition_name := 'bbal_log_' || to_char(v_current_month, 'YYYYMM');
        
        -- 定義分區的起始範圍 (包含)
        v_partition_start := to_char(v_current_month, 'YYYY-MM-DD');
        
        -- 定義分區的結束範圍 (不包含)，即下個月的第一天
        v_partition_end := to_char(v_current_month + interval '1 month', 'YYYY-MM-DD');
        
        -- 輸出正在建立的分區資訊
        RAISE NOTICE '  -> 正在建立分區 earning.% FOR VALUES FROM ''%'' TO ''%'';', v_partition_name, v_partition_start, v_partition_end;
        
        -- 使用 format() 函數安全地執行動態 SQL
        EXECUTE format(
            'CREATE TABLE earning.%I PARTITION OF earning.bucket_balance_audit_log FOR VALUES FROM (%L) TO (%L);',
            v_partition_name,
            v_partition_start,
            v_partition_end
        );
        
        -- 將當前月份推進到下個月的第一天
        v_current_month := v_current_month + interval '1 month';
    END LOOP;

    RAISE NOTICE '所有月度分區建立完成！';
END;
$$;