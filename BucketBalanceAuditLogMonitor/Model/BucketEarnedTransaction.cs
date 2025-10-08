namespace BucketBalanceAuditLogMonitor.Model;

public class BucketEarnedTransaction
{
    /// <summary>
    /// 對應資料庫中的 'tran_id' (int8/bigint) 欄位。
    /// </summary>
    public long TranId { get; set; }

    /// <summary>
    /// 對應資料庫中的 'bucket_type' (varchar) 欄位。
    /// </summary>
    public string BucketType { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'category' (varchar) 欄位。
    /// </summary>
    public string Category { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'gaming_dt' (date) 欄位。
    /// </summary>
    public DateTime GamingDt { get; set; }

    /// <summary>
    /// 對應資料庫中的 'acct' (varchar) 欄位。
    /// </summary>
    public string Acct { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'earned' (numeric) 欄位。
    /// </summary>
    public decimal Earned { get; set; }

    /// <summary>
    /// 對應資料庫中的 'expiry_date' (date) 欄位，此欄位可為 NULL。
    /// </summary>
    public DateTime? ExpiryDate { get; set; }

    /// <summary>
    /// 對應資料庫中的 'last_modified_date' (timestamp) 欄位。
    /// </summary>
    public DateTime LastModifiedDate { get; set; }

    /// <summary>
    /// 對應資料庫中的 'main_id' (varchar) 欄位。
    /// </summary>
    public string MainId { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'earning_rule_id' (varchar) 欄位。
    /// </summary>
    public string EarningRuleId { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'is_void' (bool) 欄位。
    /// </summary>
    public bool IsVoid { get; set; }

    /// <summary>
    /// 對應資料庫中的 'hub_tran_id' (int8/bigint) 欄位。
    /// </summary>
    public long HubTranId { get; set; }

    /// <summary>
    /// 對應資料庫中的 'hub_is_synced' (varchar) 欄位。
    /// </summary>
    public string HubIsSynced { get; set; } = string.Empty;
}