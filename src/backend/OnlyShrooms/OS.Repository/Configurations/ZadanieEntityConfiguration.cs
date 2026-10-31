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

        builder.Property(e => e.Tytuł).IsRequired().HasMaxLength(200);
        builder.Property(e => e.Opis);
    }
}
