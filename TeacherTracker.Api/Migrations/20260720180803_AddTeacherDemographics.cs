using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeacherTracker.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddTeacherDemographics : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "City",
                table: "Teachers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "District",
                table: "Teachers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EducationLevel",
                table: "Teachers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SchoolType",
                table: "Teachers",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Teachers_City",
                table: "Teachers",
                column: "City");

            migrationBuilder.CreateIndex(
                name: "IX_Teachers_City_District",
                table: "Teachers",
                columns: new[] { "City", "District" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Teachers_City",
                table: "Teachers");

            migrationBuilder.DropIndex(
                name: "IX_Teachers_City_District",
                table: "Teachers");

            migrationBuilder.DropColumn(
                name: "City",
                table: "Teachers");

            migrationBuilder.DropColumn(
                name: "District",
                table: "Teachers");

            migrationBuilder.DropColumn(
                name: "EducationLevel",
                table: "Teachers");

            migrationBuilder.DropColumn(
                name: "SchoolType",
                table: "Teachers");
        }
    }
}
