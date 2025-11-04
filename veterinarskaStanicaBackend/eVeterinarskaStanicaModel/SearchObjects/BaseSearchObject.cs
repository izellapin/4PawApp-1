namespace eVeterinarskaStanicaModel.SearchObjects
{
    public class BaseSearchObject
    {
        public int? Page { get; set; } = 1;
        public int? PageSize { get; set; } = 10;
        public string? OrderBy { get; set; }
        public bool IsDescending { get; set; } = false;
        public string? SearchTerm { get; set; }
        
        // Calculated properties
        public int Skip => ((Page ?? 1) - 1) * (PageSize ?? 10);
        public int Take => PageSize ?? 10;
    }
}
