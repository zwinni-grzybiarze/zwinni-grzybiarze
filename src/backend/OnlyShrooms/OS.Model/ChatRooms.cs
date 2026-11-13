namespace OS.Model;

public static class ChatRooms
{
    public const string Global = "global";

    public const int MaxRoomIdLength = 100;

    public const int MaxBodyLength = 2000;

    public const int DefaultHistoryLimit = 50;

    public const int MaxHistoryLimit = 100;

    public static string NormalizeRoomId(string? roomId)
    {
        var value = roomId?.Trim();
        if (string.IsNullOrEmpty(value))
        {
            throw new ValidationFailedException("RoomId is required.");
        }

        if (value.Length > MaxRoomIdLength)
        {
            throw new ValidationFailedException("RoomId is too long.");
        }

        return value;
    }

    public static DateTime NormalizeUtc(DateTime value) =>
        value.Kind == DateTimeKind.Unspecified
            ? DateTime.SpecifyKind(value, DateTimeKind.Utc)
            : value.ToUniversalTime();

    public static DateTime? NormalizeUtc(DateTime? value) =>
        value.HasValue ? NormalizeUtc(value.Value) : null;
}
