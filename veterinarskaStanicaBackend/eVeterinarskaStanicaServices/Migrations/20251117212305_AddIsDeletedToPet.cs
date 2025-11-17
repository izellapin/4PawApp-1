using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eVeterinarskaStanicaServices.Migrations
{
    /// <inheritdoc />
    public partial class AddIsDeletedToPet : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Pets",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Pets");
        }
    }
}
