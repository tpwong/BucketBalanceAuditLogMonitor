namespace BucketBalanceAuditLogMonitor.Model;

public class BucketRedeemTransaction
{
    /// <summary>
    /// 對應資料庫中的 'id' (uuid) 欄位。
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// 對應資料庫中的 'acct' (varchar) 欄位。
    /// </summary>
    public string Acct { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'prize_code' (varchar) 欄位。
    /// </summary>
    public string PrizeCode { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'gaming_dt' (date) 欄位。
    /// </summary>
    public DateTime GamingDt { get; set; }

    /// <summary>
    /// 對應資料庫中的 'bucket_type' (varchar) 欄位。
    /// </summary>
    public string BucketType { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'quantity' (int4) 欄位。
    /// </summary>
    public int Quantity { get; set; }

    /// <summary>
    /// 對應資料庫中的 'amount' (numeric) 欄位。
    /// </summary>
    public decimal Amount { get; set; }

    /// <summary>
    /// 對應資料庫中的 'related_id' (varchar) 欄位。
    /// </summary>
    public string RelatedId { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'post_dtm' (timestamp) 欄位。
    /// </summary>
    public DateTime PostDtm { get; set; }

    /// <summary>
    /// 對應資料庫中的 'created_by' (varchar) 欄位。
    /// </summary>
    public string CreatedBy { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'remark' (text) 欄位。
    /// </summary>
    public string Remark { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'is_void' (bool) 欄位。
    /// </summary>
    public bool IsVoid { get; set; }

    /// <summary>
    /// 對應資料庫中的 'last_modified_date' (timestamp) 欄位。
    /// </summary>
    public DateTime LastModifiedDate { get; set; }

    /// <summary>
    /// 對應資料庫中的 'casino_code' (varchar) 欄位。
    /// </summary>
    public string CasinoCode { get; set; } = string.Empty;

    /// <summary>
    /// 對應資料庫中的 'locn_code' (varchar) 欄位。
    /// </summary>
    public string LocnCode { get; set; } = string.Empty;
}