using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using OS.Entities;

namespace OS.Repository.Configurations;

internal sealed class WeatherForecastEntityConfiguration : IEntityTypeConfiguration<WeatherForecastEntity>
{
    public void Configure(EntityTypeBuilder<WeatherForecastEntity> builder)
    {
        builder.ToTable("WeatherForecasts");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Summary).HasMaxLength(200);
    }
}
