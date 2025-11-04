using System;
using System.Collections.Generic;
using System.Text;

namespace eVeterinarskaStanicaModel.SearchObjects
{
    public class ServiceSearchObject : BaseSearchObject
    {
        public string? Code { get; set; }

        public string? CodeGTE { get; set; }

        public string? FTS { get; set; } //FULL TEXT SEARCH

        public string? ServiceType { get; set; }

        public bool? RequiresAppointment { get; set; }

        public decimal? MinPrice { get; set; }

        public decimal? MaxPrice { get; set; }

        public int? CategoryId { get; set; }

        public bool? IsActive { get; set; }

        public bool? IsFeatured { get; set; }
    }
}

