namespace BucketBalanceAuditLogMonitor.Model;

public class BucketBalance
{
    public long Id { get; set; }
    public string Acct { get; set; }
    public string BucketType { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public decimal Total { get; set; }
    public DateTime LastModifiedDate { get; set; }
    public string BucketName { get; set; }
    public bool IsForfeit { get; set; }
}