using System;
using System.Text.Json.Serialization;

namespace eVeterinarskaStanicaModel.DTOs
{
    public class AppointmentDto
    {
        public int Id { get; set; }
        public string AppointmentNumber { get; set; } = string.Empty;
        public DateTime AppointmentDate { get; set; }
        public string StartTime { get; set; } = string.Empty;
        public string EndTime { get; set; } = string.Empty;
        public int Type { get; set; }
        public int Status { get; set; }
        
        [JsonPropertyName("petId")]
        public int PetId { get; set; }
        
        public string PetName { get; set; } = string.Empty;
        
        [JsonPropertyName("veterinarianId")]
        public int VeterinarianId { get; set; }
        
        public string OwnerName { get; set; } = string.Empty;
        public string VeterinarianName { get; set; } = string.Empty;
        
        [JsonPropertyName("serviceId")]
        public int? ServiceId { get; set; }
        
        public string? ServiceName { get; set; }
        public decimal? EstimatedCost { get; set; }
        public decimal? ActualCost { get; set; }
        public string? Reason { get; set; }
        public string? Notes { get; set; }

        // Payment status fields
        public bool IsPaid { get; set; }
        public DateTime? PaymentDate { get; set; }
        public string? PaymentMethod { get; set; }
        public string? PaymentTransactionId { get; set; }
    }
}


