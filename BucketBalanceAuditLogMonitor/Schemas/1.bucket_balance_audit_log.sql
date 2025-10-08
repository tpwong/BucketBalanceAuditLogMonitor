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

COMMENT ON TABLE earning.bucket_balance_audit_log IS '���օ^����ӛ� bucket_balances ��׃���Ļ������I���Y�ϰ��Ճ������ӷօ^�С�';
COMMENT ON COLUMN earning.bucket_balance_audit_log.audit_timestamp IS '�����¼��r�g����ͬ�rҲ�Ǵ˱�ķօ^�I��';
