using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using OS.Entities;

namespace OS.Repository.Configurations;

internal sealed class ChatMessageEntityConfiguration : IEntityTypeConfiguration<ChatMessageEntity>
{
    private static readonly ValueConverter<DateTime, DateTime> UtcConverter = new(
        value => value,
        value => DateTime.SpecifyKind(value, DateTimeKind.Utc));

    public void Configure(EntityTypeBuilder<ChatMessageEntity> builder)
    {
        builder.ToTable("ChatMessages");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.RoomId).IsRequired().HasMaxLength(100);
        builder.Property(e => e.SenderId).IsRequired().HasMaxLength(100);
        builder.Property(e => e.SenderName).IsRequired().HasMaxLength(200);
        builder.Property(e => e.Body).IsRequired().HasMaxLength(2000);
        builder.Property(e => e.SentAt).HasConversion(UtcConverter);

        builder.HasIndex(e => new { e.RoomId, e.SentAt });
    }
}
