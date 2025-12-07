using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eVeterinarskaStanicaServices.Migrations
{
    /// <inheritdoc />
    public partial class AddAppointmentIdToReview : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AppointmentId",
                table: "Review",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Review_AppointmentId",
                table: "Review",
                column: "AppointmentId");

            migrationBuilder.AddForeignKey(
                name: "FK_Review_Appointments_AppointmentId",
                table: "Review",
                column: "AppointmentId",
                principalTable: "Appointments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Review_Appointments_AppointmentId",
                table: "Review");

            migrationBuilder.DropIndex(
                name: "IX_Review_AppointmentId",
                table: "Review");

            migrationBuilder.DropColumn(
                name: "AppointmentId",
                table: "Review");
        }
    }
}
