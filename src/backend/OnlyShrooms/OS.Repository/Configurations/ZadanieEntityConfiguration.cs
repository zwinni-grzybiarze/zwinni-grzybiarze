using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using OS.Entities;

namespace OS.Repository.Configurations;

internal sealed class ZadanieEntityConfiguration : IEntityTypeConfiguration<ZadanieEntity>
{
    public void Configure(EntityTypeBuilder<ZadanieEntity> builder)
    {
        builder.ToTable("Zadania");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Nazwa).IsRequired().HasMaxLength(200);
        builder.Property(e => e.Opis);
        builder.Property(e => e.Status).HasConversion<string>().HasMaxLength(50);
        builder
            .HasOne<GrzybobranieEntity>()
            .WithMany()
            .HasForeignKey(e => e.GrzybobranieId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
