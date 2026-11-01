using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace OS.Repository.Migrations
{
    /// <inheritdoc />
    public partial class AddGrzybiarze : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Grzybiarze",
                columns: table => new
                {
                    KeycloakId = table.Column<string>(type: "TEXT", nullable: false),
                    Email = table.Column<string>(type: "TEXT", maxLength: 200, nullable: true),
                    Imie = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    Nazwisko = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Grzybiarze", x => x.KeycloakId);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Grzybiarze");
        }
    }
}
