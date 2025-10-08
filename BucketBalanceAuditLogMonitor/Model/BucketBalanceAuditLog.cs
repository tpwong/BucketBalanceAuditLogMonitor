using System.Text.Json;

namespace BucketBalanceAuditLogMonitor.Model;

public class BucketBalanceAuditLog
{
    /// <summary>
    /// 稽核日誌的唯一標識符。
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// 稽核事件發生的時間戳 (帶時區)，也是資料庫中的分區鍵。
    /// </summary>
    public DateTimeOffset AuditTimestamp { get; set; }

    /// <summary>
    /// 操作類型 (INSERT, UPDATE, DELETE)。
    /// </summary>
    public string Action { get; set; } = string.Empty;

    /// <summary>
    /// 被稽核的 bucket_balances 紀錄的 ID。
    /// </summary>
    public long RecordId { get; set; }

    /// <summary>
    /// 變更前的餘額。對於 INSERT 操作，此值為 null。
    /// </summary>
    public decimal? OldBalance { get; set; }

    /// <summary>
    /// 變更後的餘額。對於 DELETE 操作，此值為 null。
    /// </summary>
    public decimal? NewBalance { get; set; }

    /// <summary>
    /// 餘額的變化量 (new_balance - old_balance)。
    /// </summary>
    public decimal DeltaBalance { get; set; }

    /// <summary>
    /// 觸發此次餘額變動的來源資料表名稱，如果沒有則為 null。
    /// </summary>
    public string? SourceTableName { get; set; }

    /// <summary>
    /// 來源紀錄的主鍵 (JSON)，如果沒有則為 null。
    /// </summary>
    public JsonElement? SourceRecordPk { get; set; }
}
