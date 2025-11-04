# Test Registration API Endpoints
# PowerShell script to test user registration functionality

$baseUrl = "https://localhost:7160/api/auth"

# Test data
$registerData = @{
    Email = "test.user@example.com"
    Username = "testuser123"
    Password = "TestPassword123!"
    ConfirmPassword = "TestPassword123!"
    FirstName = "Test"
    LastName = "User"
    PhoneNumber = "+387 61 123 456"
    Address = "Sarajevo, BiH"
    ClientType = "Mobile"
    Role = 4  # PetOwner
} | ConvertTo-Json

$verifyEmailData = @{
    Email = "test.user@example.com"
    Code = "123456"  # This will be provided via email
} | ConvertTo-Json

$resendData = @{
    Email = "test.user@example.com"
} | ConvertTo-Json

Write-Host "=== 4Paw Veterinary Clinic - Registration API Tests ===" -ForegroundColor Green
Write-Host ""

# Test 1: User Registration
Write-Host "1. Testing User Registration..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/register" -Method Post -Body $registerData -ContentType "application/json" -SkipCertificateCheck
    Write-Host "✅ Registration successful!" -ForegroundColor Green
    Write-Host "Response: $($response.message)" -ForegroundColor Cyan
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 400) {
        $errorContent = $_.Exception.Response.Content.ReadAsStringAsync().Result
        Write-Host "❌ Registration failed with validation errors:" -ForegroundColor Red
        Write-Host $errorContent -ForegroundColor Red
    } else {
        Write-Host "❌ Registration failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 2: Resend Email Verification Code
Write-Host "2. Testing Resend Email Verification Code..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/resend-email-verification" -Method Post -Body $resendData -ContentType "application/json" -SkipCertificateCheck
    Write-Host "✅ Resend verification code successful!" -ForegroundColor Green
    Write-Host "Response: $($response.message)" -ForegroundColor Cyan
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 400) {
        $errorContent = $_.Exception.Response.Content.ReadAsStringAsync().Result
        Write-Host "❌ Resend failed:" -ForegroundColor Red
        Write-Host $errorContent -ForegroundColor Red
    } else {
        Write-Host "❌ Resend failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 3: Email Verification (requires manual input)
Write-Host "3. Testing Email Verification..." -ForegroundColor Yellow
Write-Host "Check your email for the verification code and enter it below:" -ForegroundColor Cyan
$verificationCode = Read-Host "Enter verification code (6 digits)"

if ($verificationCode -and $verificationCode.Length -eq 6) {
    $verifyEmailData = @{
        Email = "test.user@example.com"
        Code = $verificationCode
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/verify-email" -Method Post -Body $verifyEmailData -ContentType "application/json" -SkipCertificateCheck
        Write-Host "✅ Email verification successful!" -ForegroundColor Green
        Write-Host "Response: $($response.message)" -ForegroundColor Cyan
    } catch {
        $errorResponse = $_.Exception.Response
        if ($errorResponse.StatusCode -eq 400) {
            $errorContent = $_.Exception.Response.Content.ReadAsStringAsync().Result
            Write-Host "❌ Email verification failed:" -ForegroundColor Red
            Write-Host $errorContent -ForegroundColor Red
        } else {
            Write-Host "❌ Email verification failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "⚠️ Skipping email verification test - invalid code format" -ForegroundColor Yellow
}

Write-Host ""

# Test 4: Try to register with same email (should fail)
Write-Host "4. Testing Duplicate Email Registration (should fail)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/register" -Method Post -Body $registerData -ContentType "application/json" -SkipCertificateCheck
    Write-Host "❌ Duplicate registration should have failed!" -ForegroundColor Red
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 400) {
        $errorContent = $_.Exception.Response.Content.ReadAsStringAsync().Result
        Write-Host "✅ Duplicate registration correctly rejected!" -ForegroundColor Green
        Write-Host "Error: $errorContent" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 5: Try to login with new user (after email verification)
Write-Host "5. Testing Login with New User..." -ForegroundColor Yellow
$loginData = @{
    Email = "test.user@example.com"
    Password = "TestPassword123!"
    ClientType = "Mobile"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body $loginData -ContentType "application/json" -SkipCertificateCheck
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "User: $($response.firstName) $($response.lastName)" -ForegroundColor Cyan
    Write-Host "Role: $($response.role)" -ForegroundColor Cyan
    Write-Host "Email Verified: $($response.isEmailVerified)" -ForegroundColor Cyan
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 400) {
        $errorContent = $_.Exception.Response.Content.ReadAsStringAsync().Result
        Write-Host "❌ Login failed:" -ForegroundColor Red
        Write-Host $errorContent -ForegroundColor Red
    } else {
        Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Registration API Tests Completed ===" -ForegroundColor Green
Write-Host ""
Write-Host "📧 Check your email (test.user@example.com) for verification codes" -ForegroundColor Cyan
Write-Host "🔐 Remember to verify your email before trying to login" -ForegroundColor Cyan

