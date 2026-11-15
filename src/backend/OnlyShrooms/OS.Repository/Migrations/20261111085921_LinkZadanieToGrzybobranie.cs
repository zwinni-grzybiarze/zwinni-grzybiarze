using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace OS.Repository.Migrations
{
    /// <inheritdoc />
    public partial class LinkZadanieToGrzybobranie : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "GrzybobranieId",
                table: "Zadania",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Zadania_GrzybobranieId",
                table: "Zadania",
                column: "GrzybobranieId");

            migrationBuilder.AddForeignKey(
                name: "FK_Zadania_Grzybobrania_GrzybobranieId",
                table: "Zadania",
                column: "GrzybobranieId",
                principalTable: "Grzybobrania",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Zadania_Grzybobrania_GrzybobranieId",
                table: "Zadania");

            migrationBuilder.DropIndex(
                name: "IX_Zadania_GrzybobranieId",
                table: "Zadania");

            migrationBuilder.DropColumn(
                name: "GrzybobranieId",
                table: "Zadania");
        }
    }
}
