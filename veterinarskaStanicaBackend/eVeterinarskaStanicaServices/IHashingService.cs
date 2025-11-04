using System;

namespace eVeterinarskaStanicaServices
{
    public interface IHashingService
    {
        /// <summary>
        /// Hashes a password using PBKDF2 with salt generation
        /// </summary>
        /// <param name="password">Plain text password</param>
        /// <param name="salt">Generated salt as byte array</param>
        /// <returns>Hashed password as Base64 string</returns>
        string HashPassword(string password, out byte[] salt);

        /// <summary>
        /// Verifies a password against a hash and salt
        /// </summary>
        /// <param name="password">Plain text password</param>
        /// <param name="hashedPassword">Previously hashed password</param>
        /// <param name="salt">Salt used for hashing</param>
        /// <returns>True if password matches, false otherwise</returns>
        bool VerifyPassword(string password, string hashedPassword, string saltBase64);
    }
}
