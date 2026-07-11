using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeacherTracker.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddTeacherProfileImages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AvatarFileObjectId",
                table: "Teachers",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CoverFileObjectId",
                table: "Teachers",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Teachers_AvatarFileObjectId",
                table: "Teachers",
                column: "AvatarFileObjectId");

            migrationBuilder.CreateIndex(
                name: "IX_Teachers_CoverFileObjectId",
                table: "Teachers",
                column: "CoverFileObjectId");

            migrationBuilder.AddForeignKey(
                name: "FK_Teachers_Files_AvatarFileObjectId",
                table: "Teachers",
                column: "AvatarFileObjectId",
                principalTable: "Files",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Teachers_Files_CoverFileObjectId",
                table: "Teachers",
                column: "CoverFileObjectId",
                principalTable: "Files",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Teachers_Files_AvatarFileObjectId",
                table: "Teachers");

            migrationBuilder.DropForeignKey(
                name: "FK_Teachers_Files_CoverFileObjectId",
                table: "Teachers");

            migrationBuilder.DropIndex(
                name: "IX_Teachers_AvatarFileObjectId",
                table: "Teachers");

            migrationBuilder.DropIndex(
                name: "IX_Teachers_CoverFileObjectId",
                table: "Teachers");

            migrationBuilder.DropColumn(
                name: "AvatarFileObjectId",
                table: "Teachers");

            migrationBuilder.DropColumn(
                name: "CoverFileObjectId",
                table: "Teachers");
        }
    }
}
