-- ====================================================================
-- ���Eһ�������օ^���� (�����ш����^�������^�˲���)
-- ====================================================================

-- ���˴_����ȫ�µ��_ʼ���Ȅh���f������P��ʽ
DROP TABLE IF EXISTS earning.bucket_balance_audit_log;

-- �����օ^���� (Partitioned Table)
CREATE TABLE earning.bucket_balance_audit_log (
    -- �������I�����ΨһID
    id bigserial NOT NULL,
    
    -- �����¼��l���ĕr�g���@�����҂��ķօ^�I (Partition Key)
    audit_timestamp timestamptz NOT NULL DEFAULT now(),
    
    -- ������� (INSERT, UPDATE, DELETE)
    action varchar(10) NOT NULL,
    
    -- �����˵ļo䛵����I (bucket_balance.id)
    record_id bigint NOT NULL,
    
    -- �o�׃��ǰ�Ľ��~
    old_balance numeric(19, 9),
    
    -- �o�׃����Ľ��~
    new_balance numeric(19, 9),
    
    -- �o䛴˴�׃���Ĳ��~
    delta_balance numeric(19, 9) NOT NULL,
    
    -- �|�l�˴��N�~׃�ӵā�Դ�Y�ϱ����Q
    source_table_name varchar(100),
    
    -- ��Դ�Y�ϱ�o䛵����I
    source_record_pk jsonb,

    -- �����I�s�����x�����ᣬ�K�����օ^�I
    PRIMARY KEY (id, audit_timestamp)
)
PARTITION BY RANGE (audit_timestamp);

-- �������� (�@Щ�������Ԅӑ��õ������ӷօ^)
CREATE INDEX idx_bbal_record_id ON earning.bucket_balance_audit_log (record_id);
CREATE INDEX idx_bbal_source_pk_gin ON earning.bucket_balance_audit_log USING gin (source_record_pk);

COMMENT ON TABLE earning.bucket_balance_audit_log IS '���օ^����ӛ� bucket_balances ��׃���Ļ������I���Y�ϰ��������ӷօ^�С�';
COMMENT ON COLUMN earning.bucket_balance_audit_log.audit_timestamp IS '�����¼��r�g����ͬ�rҲ�Ǵ˱�ķօ^�I��';

RAISE NOTICE '���� earning.bucket_balance_audit_log ������ɡ�';


-- ====================================================================
-- ���E�����Ԅӻ��_���������� 2025-06 �� 2030-12 �������¶ȷօ^
-- ====================================================================
DO $$
DECLARE
    -- �O��Ҫ�����օ^����ʼ�c�Y���·� (ȡ�·ݵĵ�һ��)
    v_start_month date := '2025-06-01';
    v_end_month   date := '2030-12-01';
    
    -- ���ޒȦ��׃��
    v_current_month date := v_start_month;
    v_partition_name text;
    v_partition_start text;
    v_partition_end text;
BEGIN
    RAISE NOTICE '�_ʼ������ % �� % ���¶ȷօ^...', to_char(v_start_month, 'YYYY-MM'), to_char(v_end_month, 'YYYY-MM');

    -- ޒȦ��vÿ����
    WHILE v_current_month <= v_end_month LOOP
        -- �a���օ^�����Q����ʽ�飺bbal_log_YYYYMM (���磺bbal_log_202506)
        v_partition_name := 'bbal_log_' || to_char(v_current_month, 'YYYYMM');
        
        -- ���x�օ^����ʼ���� (����)
        v_partition_start := to_char(v_current_month, 'YYYY-MM-DD');
        
        -- ���x�օ^�ĽY������ (������)�������µĵ�һ��
        v_partition_end := to_char(v_current_month + interval '1 month', 'YYYY-MM-DD');
        
        -- ݔ�����ڽ����ķօ^�YӍ
        RAISE NOTICE '  -> ���ڽ����օ^ earning.% FOR VALUES FROM ''%'' TO ''%'';', v_partition_name, v_partition_start, v_partition_end;
        
        -- ʹ�� format() ������ȫ�؈��ЄӑB SQL
        EXECUTE format(
            'CREATE TABLE earning.%I PARTITION OF earning.bucket_balance_audit_log FOR VALUES FROM (%L) TO (%L);',
            v_partition_name,
            v_partition_start,
            v_partition_end
        );
        
        -- ����ǰ�·����M�����µĵ�һ��
        v_current_month := v_current_month + interval '1 month';
    END LOOP;

    RAISE NOTICE '�����¶ȷօ^������ɣ�';
END;
$$;