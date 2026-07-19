using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeacherTracker.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddPerformanceIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Posts_AuthorUserId",
                table: "Posts");

            migrationBuilder.DropIndex(
                name: "IX_Assignments_ClassroomId",
                table: "Assignments");

            migrationBuilder.CreateIndex(
                name: "IX_Posts_AuthorUserId_Id",
                table: "Posts",
                columns: new[] { "AuthorUserId", "Id" });

            migrationBuilder.CreateIndex(
                name: "IX_Posts_Subject_Id",
                table: "Posts",
                columns: new[] { "Subject", "Id" });

            migrationBuilder.CreateIndex(
                name: "IX_Assignments_ClassroomId_CreatedAt",
                table: "Assignments",
                columns: new[] { "ClassroomId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Assignments_DueDate",
                table: "Assignments",
                column: "DueDate");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Posts_AuthorUserId_Id",
                table: "Posts");

            migrationBuilder.DropIndex(
                name: "IX_Posts_Subject_Id",
                table: "Posts");

            migrationBuilder.DropIndex(
                name: "IX_Assignments_ClassroomId_CreatedAt",
                table: "Assignments");

            migrationBuilder.DropIndex(
                name: "IX_Assignments_DueDate",
                table: "Assignments");

            migrationBuilder.CreateIndex(
                name: "IX_Posts_AuthorUserId",
                table: "Posts",
                column: "AuthorUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Assignments_ClassroomId",
                table: "Assignments",
                column: "ClassroomId");
        }
    }
}
