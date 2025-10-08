namespace BucketBalanceAuditLogMonitor.Model;

public class BucketAdjustTransaction
{
    /// <summary>
    /// 對應資料庫中的 'id' (serial4/int) 欄位。
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// 對應資料庫中的 'acct' (varchar) 欄位。
    /// </summary>
    public string Acct { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'gaming_dt' (date) 欄位。
    /// </summary>
    public DateTime GamingDt { get; set; }

    /// <summary>
    /// 對應資料庫中的 'bucket_name' (varchar) 欄位。
    /// </summary>
    public string BucketName { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'bucket_type' (varchar) 欄位。
    /// </summary>
    public string BucketType { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'amount' (numeric) 欄位。
    /// </summary>
    public decimal Amount { get; set; }

    /// <summary>
    /// 對應資料庫中的 'post_dtm' (timestamp) 欄位。
    /// </summary>
    public DateTime PostDtm { get; set; }

    /// <summary>
    /// 對應資料庫中的 'related_id' (varchar) 欄位。
    /// </summary>
    public string RelatedId { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'remark' (text) 欄位。
    /// </summary>
    public string Remark { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'is_void' (bool) 欄位。
    /// </summary>
    public bool IsVoid { get; set; }

    /// <summary>
    /// 對應資料庫中的 'after_adjust_amount' (numeric) 欄位。
    /// </summary>
    public decimal AfterAdjustAmount { get; set; }

    /// <summary>
    /// 對應資料庫中的 'last_modified_date' (timestamp) 欄位。
    /// </summary>
    public DateTime LastModifiedDate { get; set; }
}