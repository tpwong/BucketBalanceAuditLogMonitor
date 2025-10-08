using BucketBalanceAuditLogMonitor.Model;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Npgsql;
using System.Text.Json;

namespace BucketBalanceAuditLogMonitor.BackgroundServices;


public class BalanceMonitorWorker : BackgroundService
{
    private readonly ILogger<BalanceMonitorWorker> _logger;
    private readonly string _connectionString;
    private const string NotificationChannel = "table_changes";

    public BalanceMonitorWorker(ILogger<BalanceMonitorWorker> logger, IConfiguration configuration)
    {
        _logger = logger;
        _connectionString = configuration.GetConnectionString("PostgresDb")
                            ?? throw new InvalidOperationException("連線字串 'PostgresDb' 找不到。");
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Bucket Balance 監聽服務啟動於: {time}", DateTimeOffset.Now);

        await using var connection = new NpgsqlConnection(_connectionString);

        // 設定通知事件的處理函式
        connection.Notification += OnNotificationReceived;
        // 當連線狀態改變時記錄日誌，方便偵錯
        connection.StateChange += (sender, args) => _logger.LogInformation("連線狀態改變: {state}", args.CurrentState);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogInformation("正在開啟資料庫連線並開始監聽...");
                await connection.OpenAsync(stoppingToken);

                // 執行 LISTEN 命令來訂閱頻道
                await using (var cmd = new NpgsqlCommand($"LISTEN {NotificationChannel}", connection))
                {
                    await cmd.ExecuteNonQueryAsync(stoppingToken);
                }

                _logger.LogInformation("成功監聽頻道 '{channel}'。等待通知...", NotificationChannel);

                // 進入等待迴圈，`WaitAsync` 會非同步地等待，直到有通知或 CancellationToken 被觸發
                while (!stoppingToken.IsCancellationRequested)
                {
                    await connection.WaitAsync(stoppingToken);
                }
            }
            catch (OperationCanceledException)
            {
                // 當服務被要求停止時，會觸發此異常，這是正常流程
                _logger.LogInformation("監聽服務已取消，正在關閉。");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "監聽過程中發生未預期的錯誤。將在 5 秒後重試...");
                // 發生錯誤時，等待一段時間再重試，避免快速連續失敗導致資源耗盡
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
            finally
            {
                // 確保連線在迴圈結束或重試前關閉
                if (connection.State == System.Data.ConnectionState.Open)
                {
                    await connection.CloseAsync();
                }
            }
        }
    }

    // 在 BalanceMonitorWorker.cs 內的 OnNotificationReceived 方法
    private void OnNotificationReceived(object? sender, NpgsqlNotificationEventArgs e)
    {
        _logger.LogInformation("收到來自頻道 '{channel}' 的通知！", e.Channel);
        _logger.LogDebug("原始 Payload: {payload}", e.Payload);

        try
        {
            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true // 這個選項可以處理大部分情況，但用 JsonPropertyName 更明確
            };

            var payload = JsonSerializer.Deserialize<NotificationPayload>(e.Payload, options);

            if (payload == null)
            {
                _logger.LogWarning("無法反序列化通知 payload。");
                return;
            }

            // --- 新的處理邏輯 ---
            if (!string.IsNullOrEmpty(payload.SourceTable) && payload.SourcePk.HasValue)
            {
                // 如果有來源交易資訊，記錄下來
                _logger.LogInformation(
                    "偵測到 Bucket Balance 變更 (ID: {BalanceId})，由來源交易觸發 -> 來源表: {SourceTable}, 來源PK: {SourcePkJson}",
                    payload.Id,
                    payload.SourceTable,
                    payload.SourcePk.Value.GetRawText() // 將 PK 的 JSON 直接輸出
                );

                // 在這裡，您可以根據 payload.SourceTable 和 payload.SourcePk 做更複雜的處理
                // 例如，您可以將 SourcePk 反序列化為對應的 PK 模型
            }
            else
            {
                // 如果沒有來源交易資訊，表示是直接修改餘額
                _logger.LogInformation(
                    "偵測到獨立的 Bucket Balance 變更 -> 表: {Schema}.{Table}, 操作: {Action}, 紀錄ID: {Id}",
                    payload.Schema, payload.Table, payload.Action, payload.Id
                );
            }

            // 您原有的業務邏輯可以繼續放在這裡
            // 例如：清除快取、更新儀表板等
            var updatedBalance = payload.NewData?.Deserialize<BucketBalance>(options);
            if (updatedBalance != null)
            {
                _logger.LogInformation("更新後的餘額: 帳號={acct}, 總額={total}", updatedBalance.Acct, updatedBalance.Total);
            }
        }
        catch (JsonException jsonEx)
        {
            _logger.LogError(jsonEx, "解析通知 JSON payload 失敗。");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "處理通知時發生錯誤。");
        }
    }
}
