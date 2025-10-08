using System.Text.Json;
using System.Text.Json.Serialization;

namespace BucketBalanceAuditLogMonitor.Model;

public class NotificationPayload
{
    public long Txid { get; set; }
    public string Schema { get; set; }
    public string Table { get; set; }
    public string Action { get; set; }
    public long Id { get; set; }

    public JsonElement? OldData { get; set; }
    public JsonElement? NewData { get; set; }

    // --- 新增的屬性 ---
    /// <summary>
    /// 如果存在，表示觸發此次餘額變動的來源資料表名稱。
    /// (例如 "bucket_earned_transactions")
    /// </summary>
    [JsonPropertyName("source_table")] // 明確對應 JSON 中的 snake_case
    public string? SourceTable { get; set; }

    /// <summary>
    /// 如果存在，表示來源資料表變動紀錄的主鍵 (PK)。
    /// </summary>
    [JsonPropertyName("source_pk")]
    public JsonElement? SourcePk { get; set; }
}