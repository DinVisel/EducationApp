using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeacherTracker.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddSocialLoginSubjects : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AppleSubject",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "GoogleSubject",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_AppleSubject",
                table: "Users",
                column: "AppleSubject",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_GoogleSubject",
                table: "Users",
                column: "GoogleSubject",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Users_AppleSubject",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Users_GoogleSubject",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "AppleSubject",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "GoogleSubject",
                table: "Users");
        }
    }
}
