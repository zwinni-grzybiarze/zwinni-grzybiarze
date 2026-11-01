using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using OS.Entities;

namespace OS.Repository.Configurations;

public class GrzybiarzEntityConfiguration : IEntityTypeConfiguration<GrzybiarzEntity>
{
    public void Configure(EntityTypeBuilder<GrzybiarzEntity> builder)
    {
        builder.ToTable("Grzybiarze");
        builder.HasKey(e => e.KeycloakId);

        builder.Property(e => e.Email).HasMaxLength(200);
        builder.Property(e => e.Imie).IsRequired().HasMaxLength(100);
        builder.Property(e => e.Nazwisko).IsRequired().HasMaxLength(100);
    }
}
