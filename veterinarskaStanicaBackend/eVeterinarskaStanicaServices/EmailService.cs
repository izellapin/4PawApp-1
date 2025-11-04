using System;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace eVeterinarskaStanicaServices
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;
        private readonly string _smtpServer;
        private readonly int _smtpPort;
        private readonly string _fromEmail;
        private readonly string _fromPassword;
        private readonly string _fromName;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;

            // Gmail SMTP Configuration
            _smtpServer = _configuration["Email:SmtpServer"] ?? "smtp.gmail.com";
            _smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587");
            _fromEmail = _configuration["Email:FromEmail"] ?? "izellapin@gmail.com";
            _fromPassword = _configuration["Email:FromPassword"] ?? "";
            _fromName = _configuration["Email:FromName"] ?? "4Paw Veterinary Clinic";
        }

        public async Task<bool> Send2FACodeAsync(string email, string code, string userName)
        {
            var subject = "Your Login Verification Code - 4Paw Veterinary Clinic";
            var body = Generate2FAEmailBody(code, userName);
            
            return await SendEmailAsync(email, subject, body);
        }

        public async Task<bool> SendPasswordResetAsync(string email, string resetToken, string userName)
        {
            var subject = "Password Reset Request - 4Paw Veterinary Clinic";
            var body = GeneratePasswordResetEmailBody(resetToken, userName);
            
            return await SendEmailAsync(email, subject, body);
        }

        public async Task<bool> SendEmailAsync(string to, string subject, string body)
        {
            try
            {
                _logger.LogInformation($"Attempting to send email to {to} with subject: {subject}");

                using var client = new SmtpClient(_smtpServer, _smtpPort);
                client.EnableSsl = true;
                client.UseDefaultCredentials = false;
                client.Credentials = new NetworkCredential(_fromEmail, _fromPassword);
                client.DeliveryMethod = SmtpDeliveryMethod.Network;

                using var mailMessage = new MailMessage();
                mailMessage.From = new MailAddress(_fromEmail, _fromName);
                mailMessage.To.Add(to);
                mailMessage.Subject = subject;
                mailMessage.Body = body;
                mailMessage.IsBodyHtml = true;

                await client.SendMailAsync(mailMessage);
                
                _logger.LogInformation($"Email sent successfully to {to}");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send email to {to}: {ex.Message}");
                return false;
            }
        }

        private string Generate2FAEmailBody(string code, string userName)
        {
            return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <title>2FA Verification Code</title>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background-color: #2c3e50; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }}
        .content {{ background-color: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; }}
        .code {{ font-size: 32px; font-weight: bold; color: #e74c3c; text-align: center; padding: 20px; background-color: white; border-radius: 10px; margin: 20px 0; letter-spacing: 5px; }}
        .footer {{ text-align: center; margin-top: 20px; font-size: 12px; color: #666; }}
        .warning {{ background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🐾 4Paw Veterinary Clinic</h1>
            <h2>Login Verification</h2>
        </div>
        <div class='content'>
            <p>Hi <strong>{userName}</strong>,</p>
            
            <p>You're trying to sign in to your 4Paw Veterinary Clinic account. Please use the verification code below to complete your login:</p>
            
            <div class='code'>{code}</div>
            
            <div class='warning'>
                <strong>⚠️ Important:</strong>
                <ul>
                    <li>This code expires in <strong>10 minutes</strong></li>
                    <li>Never share this code with anyone</li>
                    <li>If you didn't request this, please ignore this email</li>
                </ul>
            </div>
            
            <p>If you're having trouble logging in, please contact our support team.</p>
            
            <p>Best regards,<br>
            <strong>4Paw Veterinary Clinic Team</strong></p>
        </div>
        <div class='footer'>
            <p>This is an automated message, please do not reply to this email.</p>
            <p>© 2024 4Paw Veterinary Clinic. All rights reserved.</p>
        </div>
    </div>
</body>
</html>";
        }

        private string GeneratePasswordResetEmailBody(string resetToken, string userName)
        {
            var resetUrl = $"{_configuration["App:BaseUrl"]}/reset-password?token={resetToken}";
            
            return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <title>Password Reset</title>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background-color: #2c3e50; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }}
        .content {{ background-color: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; }}
        .button {{ display: inline-block; background-color: #3498db; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
        .footer {{ text-align: center; margin-top: 20px; font-size: 12px; color: #666; }}
        .warning {{ background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🐾 4Paw Veterinary Clinic</h1>
            <h2>Password Reset Request</h2>
        </div>
        <div class='content'>
            <p>Hi <strong>{userName}</strong>,</p>
            
            <p>We received a request to reset your password for your 4Paw Veterinary Clinic account.</p>
            
            <p>Click the button below to reset your password:</p>
            
            <a href='{resetUrl}' class='button'>Reset Password</a>
            
            <div class='warning'>
                <strong>⚠️ Important:</strong>
                <ul>
                    <li>This link expires in <strong>1 hour</strong></li>
                    <li>If you didn't request this, please ignore this email</li>
                    <li>Your password won't change until you create a new one</li>
                </ul>
            </div>
            
            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p style='word-break: break-all; color: #666;'>{resetUrl}</p>
            
            <p>Best regards,<br>
            <strong>4Paw Veterinary Clinic Team</strong></p>
        </div>
        <div class='footer'>
            <p>This is an automated message, please do not reply to this email.</p>
            <p>© 2024 4Paw Veterinary Clinic. All rights reserved.</p>
        </div>
    </div>
</body>
</html>";
        }

        public async Task<bool> SendEmailVerificationCodeAsync(string email, string code, string userName)
        {
            var subject = "Verify Your Email Address - 4Paw Veterinary Clinic";
            var body = GetEmailVerificationTemplate(code, userName);
            return await SendEmailAsync(email, subject, body);
        }

        public async Task<bool> SendEmailVerificationLinkAsync(string email, string token, string userName)
        {
            var subject = "Verify Your Email Address - 4Paw Veterinary Clinic";
            var body = GetEmailVerificationLinkTemplate(token, userName);
            return await SendEmailAsync(email, subject, body);
        }

        private string GetEmailVerificationTemplate(string code, string userName)
        {
            return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Email Verification - 4Paw Veterinary Clinic</title>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f7fa; }}
        .container {{ max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }}
        .header h1 {{ margin: 0; font-size: 28px; font-weight: 300; }}
        .content {{ padding: 40px 30px; }}
        .verification-code {{ background-color: #f8f9fa; border: 2px dashed #667eea; border-radius: 8px; padding: 20px; text-align: center; margin: 25px 0; }}
        .code {{ font-size: 36px; font-weight: bold; color: #667eea; letter-spacing: 5px; font-family: 'Courier New', monospace; }}
        .footer {{ background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #6c757d; }}
        .btn {{ display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 12px 30px; text-decoration: none; border-radius: 25px; font-weight: 500; margin: 20px 0; }}
        .warning {{ background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0; color: #856404; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🐾 Welcome to 4Paw!</h1>
        </div>
        <div class='content'>
            <h2>Hello {userName}!</h2>
            
            <p>Thank you for registering with <strong>4Paw Veterinary Clinic</strong>! We're excited to help you take care of your beloved pets.</p>
            
            <p>To complete your registration and verify your email address, please use the verification code below:</p>
            
            <div class='verification-code'>
                <p style='margin: 0 0 10px 0; font-size: 14px; color: #6c757d;'>Your verification code is:</p>
                <div class='code'>{code}</div>
            </div>
            
            <div class='warning'>
                <strong>⚠️ Important:</strong> This code will expire in 30 minutes. If you didn't request this verification, please ignore this email.
            </div>
            
            <p>Once your email is verified, you'll be able to:</p>
            <ul>
                <li>📱 Access your account on our mobile app</li>
                <li>📅 Schedule appointments for your pets</li>
                <li>📋 View medical records and prescriptions</li>
                <li>🛒 Order veterinary services</li>
                <li>💬 Receive important notifications</li>
            </ul>
            
            <p>If you have any questions or need assistance, please don't hesitate to contact our support team.</p>
            
            <p>Best regards,<br>
            <strong>4Paw Veterinary Clinic Team</strong></p>
        </div>
        <div class='footer'>
            <p>This is an automated message, please do not reply to this email.</p>
            <p>© 2024 4Paw Veterinary Clinic. All rights reserved.</p>
        </div>
    </div>
</body>
</html>";
        }

        private string GetEmailVerificationLinkTemplate(string token, string userName)
        {
            var verifyUrl = $"{_configuration["App:BaseUrl"]}/api/Auth/verify-email?token={WebUtility.UrlEncode(token)}";

            return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Email Verification - 4Paw Veterinary Clinic</title>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f7fa; }}
        .container {{ max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }}
        .header h1 {{ margin: 0; font-size: 28px; font-weight: 300; }}
        .content {{ padding: 40px 30px; }}
        .button {{ display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 12px 30px; text-decoration: none; border-radius: 25px; font-weight: 500; margin: 20px 0; }}
        .footer {{ background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #6c757d; }}
        .warning {{ background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0; color: #856404; }}
        .url {{ word-break: break-all; color: #666; }}
    </style>
    
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🐾 Welcome to 4Paw!</h1>
        </div>
        <div class='content'>
            <h2>Hello {userName}!</h2>
            
            <p>Thank you for registering with <strong>4Paw Veterinary Clinic</strong>! To complete your registration and verify your email address, please click the button below:</p>
            
            <table role='presentation' cellspacing='0' cellpadding='0' border='0' align='center' style='margin:20px 0;'>
                <tr>
                    <td align='center' bgcolor='#667eea' style='border-radius: 25px;'>
                        <a href='{verifyUrl}' target='_blank' rel='noopener noreferrer'
                           style='font-size:16px; line-height:16px; font-weight:600; color:#ffffff; text-decoration:none; padding:14px 28px; display:inline-block; border-radius:25px; background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);'>
                            Verify My Email
                        </a>
                    </td>
                </tr>
            </table>
            
            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p class='url'>{verifyUrl}</p>
            
            <div class='warning'>
                <strong>⚠️ Important:</strong> This link will expire in 30 minutes. If you didn't request this verification, please ignore this email.
            </div>
            
            <p>Best regards,<br>
            <strong>4Paw Veterinary Clinic Team</strong></p>
        </div>
        <div class='footer'>
            <p>This is an automated message, please do not reply to this email.</p>
            <p>© 2024 4Paw Veterinary Clinic. All rights reserved.</p>
        </div>
    </div>
</body>
</html>";
        }
    }
}
