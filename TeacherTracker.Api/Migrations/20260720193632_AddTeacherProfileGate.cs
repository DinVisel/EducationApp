using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeacherTracker.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddTeacherProfileGate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // defaultValue:false backfills every existing teacher as
            // grandfathered — they are never forced through the demographic
            // onboarding gate. New accounts are inserted by EF with the entity's
            // C# default (true), so only they must complete the gate.
            migrationBuilder.AddColumn<bool>(
                name: "RequiresProfileSetup",
                table: "Teachers",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RequiresProfileSetup",
                table: "Teachers");
        }
    }
}
