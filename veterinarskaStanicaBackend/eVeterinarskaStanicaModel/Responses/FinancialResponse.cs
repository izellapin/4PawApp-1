using System;
using System.Collections.Generic;

namespace eVeterinarskaStanicaModel.Responses
{
    public class FinancialSummaryResponse
    {
        public decimal DailyRevenue { get; set; }
        public decimal WeeklyRevenue { get; set; }
        public decimal MonthlyRevenue { get; set; }
        public decimal YearlyRevenue { get; set; }
        public int DailyAppointments { get; set; }
        public int WeeklyAppointments { get; set; }
        public int MonthlyAppointments { get; set; }
        public decimal AverageAppointmentValue { get; set; }
        public decimal MonthlyGrowth { get; set; }
        public decimal YearlyGrowth { get; set; }
        public List<RevenueByServiceResponse> RevenueByService { get; set; } = new();
        public List<DailyRevenueResponse> DailyRevenueChart { get; set; } = new();
        public List<TopClientResponse> TopClients { get; set; } = new();
    }

    public class RevenueByServiceResponse
    {
        public string ServiceName { get; set; } = string.Empty;
        public decimal Revenue { get; set; }
        public int AppointmentCount { get; set; }
        public decimal Percentage { get; set; }
    }

    public class DailyRevenueResponse
    {
        public DateTime Date { get; set; }
        public decimal Revenue { get; set; }
        public int Appointments { get; set; }
    }

    public class TopClientResponse
    {
        public string ClientName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public decimal TotalSpent { get; set; }
        public int AppointmentCount { get; set; }
        public DateTime LastVisit { get; set; }
    }

    public class VeterinarianStatsResponse
    {
        public int MyAppointmentsToday { get; set; }
        public int MyAppointmentsWeek { get; set; }
        public int MyTotalPatients { get; set; }
        public decimal MyAverageRating { get; set; }
        public List<DailyRevenueResponse> MyDailyAppointments { get; set; } = new();
        public List<RevenueByServiceResponse> MyTopServices { get; set; } = new();
        public List<PatientInfoResponse> MyRecentPatients { get; set; } = new();
    }

    public class PatientInfoResponse
    {
        public string PetName { get; set; } = string.Empty;
        public string OwnerName { get; set; } = string.Empty;
        public string Species { get; set; } = string.Empty;
        public DateTime LastVisit { get; set; }
        public string LastService { get; set; } = string.Empty;
    }
}
