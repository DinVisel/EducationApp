using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;
using NpgsqlTypes;

#nullable disable

namespace TeacherTracker.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddSharingAndSearch : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<NpgsqlTsVector>(
                name: "SearchVector",
                table: "Teachers",
                type: "tsvector",
                nullable: false)
                .Annotation("Npgsql:TsVectorConfig", "english")
                .Annotation("Npgsql:TsVectorProperties", new[] { "FirstName", "LastName" });

            migrationBuilder.AddColumn<NpgsqlTsVector>(
                name: "SearchVector",
                table: "Quizzes",
                type: "tsvector",
                nullable: false)
                .Annotation("Npgsql:TsVectorConfig", "english")
                .Annotation("Npgsql:TsVectorProperties", new[] { "Title", "Description" });

            migrationBuilder.AddColumn<string>(
                name: "GradeLevel",
                table: "Posts",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SharedQuizId",
                table: "Posts",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<NpgsqlTsVector>(
                name: "SearchVector",
                table: "Files",
                type: "tsvector",
                nullable: false)
                .Annotation("Npgsql:TsVectorConfig", "english")
                .Annotation("Npgsql:TsVectorProperties", new[] { "FileName" });

            migrationBuilder.CreateTable(
                name: "PostRatings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PostId = table.Column<int>(type: "integer", nullable: false),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    Value = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PostRatings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PostRatings_Posts_PostId",
                        column: x => x.PostId,
                        principalTable: "Posts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PostRatings_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Teachers_SearchVector",
                table: "Teachers",
                column: "SearchVector")
                .Annotation("Npgsql:IndexMethod", "GIN");

            migrationBuilder.CreateIndex(
                name: "IX_Quizzes_SearchVector",
                table: "Quizzes",
                column: "SearchVector")
                .Annotation("Npgsql:IndexMethod", "GIN");

            migrationBuilder.CreateIndex(
                name: "IX_Posts_SharedQuizId",
                table: "Posts",
                column: "SharedQuizId");

            migrationBuilder.CreateIndex(
                name: "IX_Files_SearchVector",
                table: "Files",
                column: "SearchVector")
                .Annotation("Npgsql:IndexMethod", "GIN");

            migrationBuilder.CreateIndex(
                name: "IX_PostRatings_PostId_UserId",
                table: "PostRatings",
                columns: new[] { "PostId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PostRatings_UserId",
                table: "PostRatings",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Posts_Quizzes_SharedQuizId",
                table: "Posts",
                column: "SharedQuizId",
                principalTable: "Quizzes",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Posts_Quizzes_SharedQuizId",
                table: "Posts");

            migrationBuilder.DropTable(
                name: "PostRatings");

            migrationBuilder.DropIndex(
                name: "IX_Teachers_SearchVector",
                table: "Teachers");

            migrationBuilder.DropIndex(
                name: "IX_Quizzes_SearchVector",
                table: "Quizzes");

            migrationBuilder.DropIndex(
                name: "IX_Posts_SharedQuizId",
                table: "Posts");

            migrationBuilder.DropIndex(
                name: "IX_Files_SearchVector",
                table: "Files");

            migrationBuilder.DropColumn(
                name: "SearchVector",
                table: "Teachers");

            migrationBuilder.DropColumn(
                name: "SearchVector",
                table: "Quizzes");

            migrationBuilder.DropColumn(
                name: "GradeLevel",
                table: "Posts");

            migrationBuilder.DropColumn(
                name: "SharedQuizId",
                table: "Posts");

            migrationBuilder.DropColumn(
                name: "SearchVector",
                table: "Files");
        }
    }
}
