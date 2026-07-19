using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace TeacherTracker.Api.Migrations
{
    /// <inheritdoc />
    public partial class HybridStudentOnboarding : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Email",
                table: "Users",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AddColumn<string>(
                name: "AccessCode",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AccessQrTokenHash",
                table: "Users",
                type: "text",
                nullable: true);

            // Existing students predate the hybrid flows → they're TeacherManaged.
            // Use the enum name (stored as text) so EF materializes them cleanly.
            migrationBuilder.AddColumn<string>(
                name: "RegistrationType",
                table: "Students",
                type: "text",
                nullable: false,
                defaultValue: "TeacherManaged");

            migrationBuilder.AddColumn<string>(
                name: "ClassCode",
                table: "Classrooms",
                type: "text",
                nullable: false,
                defaultValue: "");

            // Backfill a unique code for every pre-existing classroom BEFORE the
            // unique index is created — otherwise they'd all share "" and collide.
            migrationBuilder.Sql(
                "UPDATE \"Classrooms\" " +
                "SET \"ClassCode\" = upper(substr(md5(random()::text || \"Id\"::text), 1, 6)) " +
                "WHERE \"ClassCode\" = '';");

            migrationBuilder.CreateTable(
                name: "ClassJoinRequests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    StudentId = table.Column<int>(type: "integer", nullable: false),
                    ClassroomId = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DecidedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DecidedByTeacherId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClassJoinRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ClassJoinRequests_Classrooms_ClassroomId",
                        column: x => x.ClassroomId,
                        principalTable: "Classrooms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ClassJoinRequests_Students_StudentId",
                        column: x => x.StudentId,
                        principalTable: "Students",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Users_AccessCode",
                table: "Users",
                column: "AccessCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_AccessQrTokenHash",
                table: "Users",
                column: "AccessQrTokenHash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Classrooms_ClassCode",
                table: "Classrooms",
                column: "ClassCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ClassJoinRequests_ClassroomId_Status",
                table: "ClassJoinRequests",
                columns: new[] { "ClassroomId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_ClassJoinRequests_StudentId",
                table: "ClassJoinRequests",
                column: "StudentId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ClassJoinRequests");

            migrationBuilder.DropIndex(
                name: "IX_Users_AccessCode",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Users_AccessQrTokenHash",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Classrooms_ClassCode",
                table: "Classrooms");

            migrationBuilder.DropColumn(
                name: "AccessCode",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "AccessQrTokenHash",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "RegistrationType",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "ClassCode",
                table: "Classrooms");

            migrationBuilder.AlterColumn<string>(
                name: "Email",
                table: "Users",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);
        }
    }
}
