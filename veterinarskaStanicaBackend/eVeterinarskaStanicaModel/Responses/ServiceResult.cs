namespace eVeterinarskaStanicaModel.Responses
{
    public class ServiceResult<T> where T : class
    {
        public bool Success { get; set; }
        public string? ErrorMessage { get; set; }
        public T? Data { get; set; }

        public static ServiceResult<T> SuccessResult(T data)
        {
            return new ServiceResult<T>
            {
                Success = true,
                Data = data
            };
        }

        public static ServiceResult<T> ErrorResult(string errorMessage)
        {
            return new ServiceResult<T>
            {
                Success = false,
                ErrorMessage = errorMessage
            };
        }
    }

    public class ServiceResult
    {
        public bool Success { get; set; }
        public string? ErrorMessage { get; set; }

        public static ServiceResult SuccessResult()
        {
            return new ServiceResult { Success = true };
        }

        public static ServiceResult ErrorResult(string errorMessage)
        {
            return new ServiceResult
            {
                Success = false,
                ErrorMessage = errorMessage
            };
        }
    }
}
