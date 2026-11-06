using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace OS.Repository.Migrations
{
    /// <inheritdoc />
    public partial class UpdateZadanie : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Tytuł",
                table: "Zadania",
                newName: "Nazwa");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Nazwa",
                table: "Zadania",
                newName: "Tytuł");
        }
    }
}
