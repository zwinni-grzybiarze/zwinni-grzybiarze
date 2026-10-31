using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using OS.Entities;

namespace OS.Repository.Configurations;

internal sealed class GrzybobranieEntityConfiguration : IEntityTypeConfiguration<GrzybobranieEntity>
{
    // SQLite stores timestamps as text without a time zone, so values are read back as UTC.
    private static readonly ValueConverter<DateTime, DateTime> UtcConverter = new(
        value => value,
        value => DateTime.SpecifyKind(value, DateTimeKind.Utc));

    public void Configure(EntityTypeBuilder<GrzybobranieEntity> builder)
    {
        builder.ToTable("Grzybobrania");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Nazwa).IsRequired().HasMaxLength(200);
        builder.Property(e => e.Opis);
        builder.Property(e => e.Lokalizacja).IsRequired().HasMaxLength(500);
        builder.Property(e => e.DataOd).HasConversion(UtcConverter);
        builder.Property(e => e.DataDo).HasConversion(UtcConverter);
        builder.Property(e => e.Status).HasConversion<string>().HasMaxLength(20);
    }
}
