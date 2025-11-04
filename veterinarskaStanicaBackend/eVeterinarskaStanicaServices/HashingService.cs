using System;
using System.Security.Cryptography;

namespace eVeterinarskaStanicaServices
{
    public class HashingService : IHashingService
    {
        private const int SaltSize = 32; // 32 bytes salt
        private const int KeySize = 32;  // 32 bytes key
        private const int Iterations = 100000; // 100,000 iterations

        public string HashPassword(string password, out byte[] salt)
        {
            if (string.IsNullOrWhiteSpace(password))
                throw new ArgumentException("Password cannot be null or empty", nameof(password));

            salt = new byte[SaltSize];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(salt);
            }

            using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256))
            {
                return Convert.ToBase64String(pbkdf2.GetBytes(KeySize));
            }
        }

        public bool VerifyPassword(string password, string hashedPassword, string saltBase64)
        {
            if (string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(hashedPassword) || string.IsNullOrWhiteSpace(saltBase64))
                return false;

            try
            {
                byte[] salt = Convert.FromBase64String(saltBase64);
                
                using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256))
                {
                    string newHash = Convert.ToBase64String(pbkdf2.GetBytes(KeySize));
                    return newHash == hashedPassword;
                }
            }
            catch
            {
                return false;
            }
        }
    }
}
