using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace OS.Repository.Migrations
{
    /// <inheritdoc />
    public partial class AddGrzybiarzAuthFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "EmailConfirmed",
                table: "Grzybiarze",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "PasswordHash",
                table: "Grzybiarze",
                type: "TEXT",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EmailConfirmationTokenHash",
                table: "Grzybiarze",
                type: "TEXT",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EmailConfirmationTokenExpiresUtc",
                table: "Grzybiarze",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PasswordResetTokenHash",
                table: "Grzybiarze",
                type: "TEXT",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PasswordResetTokenExpiresUtc",
                table: "Grzybiarze",
                type: "TEXT",
                nullable: true);

            // Existing Google users are treated as confirmed.
            migrationBuilder.Sql("UPDATE Grzybiarze SET EmailConfirmed = 1;");
            // Deduplicate any legacy case/whitespace-only duplicates before creating the unique index,
            // keeping the earliest row so MigrateOsDatabaseAsync never crashes on existing volumes.
            migrationBuilder.Sql(
                """
                DELETE FROM Grzybiarze
                WHERE Id NOT IN (
                    SELECT MIN(Id)
                    FROM Grzybiarze
                    GROUP BY lower(trim(Email))
                );
                """);
            // Match runtime NormalizeEmail (Trim + ToLowerInvariant) before unique index.
            migrationBuilder.Sql("UPDATE Grzybiarze SET Email = lower(trim(Email));");

            migrationBuilder.CreateIndex(
                name: "IX_Grzybiarze_Email",
                table: "Grzybiarze",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Grzybiarze_EmailConfirmationTokenHash",
                table: "Grzybiarze",
                column: "EmailConfirmationTokenHash");

            migrationBuilder.CreateIndex(
                name: "IX_Grzybiarze_PasswordResetTokenHash",
                table: "Grzybiarze",
                column: "PasswordResetTokenHash");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Grzybiarze_Email",
                table: "Grzybiarze");

            migrationBuilder.DropIndex(
                name: "IX_Grzybiarze_EmailConfirmationTokenHash",
                table: "Grzybiarze");

            migrationBuilder.DropIndex(
                name: "IX_Grzybiarze_PasswordResetTokenHash",
                table: "Grzybiarze");

            migrationBuilder.DropColumn(
                name: "EmailConfirmed",
                table: "Grzybiarze");

            migrationBuilder.DropColumn(
                name: "PasswordHash",
                table: "Grzybiarze");

            migrationBuilder.DropColumn(
                name: "EmailConfirmationTokenHash",
                table: "Grzybiarze");

            migrationBuilder.DropColumn(
                name: "EmailConfirmationTokenExpiresUtc",
                table: "Grzybiarze");

            migrationBuilder.DropColumn(
                name: "PasswordResetTokenHash",
                table: "Grzybiarze");

            migrationBuilder.DropColumn(
                name: "PasswordResetTokenExpiresUtc",
                table: "Grzybiarze");
        }
    }
}
