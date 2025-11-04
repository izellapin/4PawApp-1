using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eVeterinarskaStanicaServices.Migrations
{
    /// <inheritdoc />
    public partial class AddPaymentFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsPaid",
                table: "Appointments",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "PaymentDate",
                table: "Appointments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PaymentMethod",
                table: "Appointments",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PaymentTransactionId",
                table: "Appointments",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsPaid",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "PaymentDate",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "PaymentMethod",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "PaymentTransactionId",
                table: "Appointments");
        }
    }
}
