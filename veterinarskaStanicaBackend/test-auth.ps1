
# PowerShell script to test authentication endpoints
# Make sure the API is running on http://localhost:8080

Write-Host "🧪 Testing Veterinary Clinic Authentication System" -ForegroundColor Cyan
Write-Host "=" * 50

$baseUrl = "http://localhost:5160/api"

# Test 1: Admin Login (Desktop)
Write-Host "`n1️⃣ Testing Admin Login (Desktop)" -ForegroundColor Yellow
$adminLogin = @{
    email = "admin@veterinary.com"
    password = "Admin123!"
    clientType = "Desktop"
} | ConvertTo-Json

try {
    $adminResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $adminLogin -ContentType "application/json"
    Write-Host "✅ Admin Login Success!" -ForegroundColor Green
    Write-Host "User: $($adminResponse.firstName) $($adminResponse.lastName)" -ForegroundColor Gray
    Write-Host "Role: $($adminResponse.role)" -ForegroundColor Gray
    Write-Host "Permissions: $($adminResponse.permissions -join ', ')" -ForegroundColor Gray
    $adminToken = $adminResponse.accessToken
} catch {
    Write-Host "❌ Admin Login Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Veterinarian Login (Desktop)
Write-Host "`n2️⃣ Testing Veterinarian Login (Desktop)" -ForegroundColor Yellow
$vetLogin = @{
    email = "vet@veterinary.com"
    password = "Vet123!"
    clientType = "Desktop"
} | ConvertTo-Json

try {
    $vetResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $vetLogin -ContentType "application/json"
    Write-Host "✅ Veterinarian Login Success!" -ForegroundColor Green
    Write-Host "User: $($vetResponse.firstName) $($vetResponse.lastName)" -ForegroundColor Gray
    Write-Host "Role: $($vetResponse.role)" -ForegroundColor Gray
    Write-Host "Permissions: $($vetResponse.permissions -join ', ')" -ForegroundColor Gray
    $vetToken = $vetResponse.accessToken
} catch {
    Write-Host "❌ Veterinarian Login Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Pet Owner Login (Mobile)
Write-Host "`n3️⃣ Testing Pet Owner Login (Mobile)" -ForegroundColor Yellow
$mobileLogin = @{
    email = "petowner@email.com"
    password = "Mobile123!"
    clientType = "Mobile"
} | ConvertTo-Json

try {
    $mobileResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $mobileLogin -ContentType "application/json"
    Write-Host "✅ Pet Owner Login Success!" -ForegroundColor Green
    Write-Host "User: $($mobileResponse.firstName) $($mobileResponse.lastName)" -ForegroundColor Gray
    Write-Host "Role: $($mobileResponse.role)" -ForegroundColor Gray
    Write-Host "Permissions: $($mobileResponse.permissions -join ', ')" -ForegroundColor Gray
    $mobileToken = $mobileResponse.accessToken
} catch {
    Write-Host "❌ Pet Owner Login Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Invalid Login
Write-Host "`n4️⃣ Testing Invalid Login" -ForegroundColor Yellow
$invalidLogin = @{
    email = "invalid@email.com"
    password = "wrongpassword"
    clientType = "Desktop"
} | ConvertTo-Json

try {
    $invalidResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $invalidLogin -ContentType "application/json"
    Write-Host "❌ Invalid login should have failed!" -ForegroundColor Red
} catch {
    Write-Host "✅ Invalid Login Correctly Rejected" -ForegroundColor Green
}

# Test 5: Protected Endpoint (Admin only - Get All Users)
if ($adminToken) {
    Write-Host "`n5️⃣ Testing Protected Endpoint (Admin - Get Users)" -ForegroundColor Yellow
    try {
        $headers = @{ "Authorization" = "Bearer $adminToken" }
        $users = Invoke-RestMethod -Uri "$baseUrl/user" -Method GET -Headers $headers
        Write-Host "✅ Admin can access user list ($($users.Count) users)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Admin access to users failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 6: Unauthorized Access (Pet Owner trying to access admin endpoint)
if ($mobileToken) {
    Write-Host "`n6️⃣ Testing Unauthorized Access (Pet Owner -> Admin Endpoint)" -ForegroundColor Yellow
    try {
        $headers = @{ "Authorization" = "Bearer $mobileToken" }
        $users = Invoke-RestMethod -Uri "$baseUrl/user" -Method GET -Headers $headers
        Write-Host "❌ Pet Owner should not access admin endpoints!" -ForegroundColor Red
    } catch {
        Write-Host "✅ Unauthorized Access Correctly Blocked" -ForegroundColor Green
    }
}

# Test 7: Get Current User Info
if ($adminToken) {
    Write-Host "`n7️⃣ Testing Get Current User Info" -ForegroundColor Yellow
    try {
        $headers = @{ "Authorization" = "Bearer $adminToken" }
        $currentUser = Invoke-RestMethod -Uri "$baseUrl/auth/me" -Method GET -Headers $headers
        Write-Host "✅ Current User Info Retrieved" -ForegroundColor Green
        Write-Host "User ID: $($currentUser.userId)" -ForegroundColor Gray
        Write-Host "Email: $($currentUser.email)" -ForegroundColor Gray
        Write-Host "Role: $($currentUser.role)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Get current user failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 8: Change Password (with proper authentication)
if ($adminToken) {
    Write-Host "`n8️⃣ Testing Change Password (Authenticated)" -ForegroundColor Yellow
    $changePasswordRequest = @{
        currentPassword = "Admin123!"
        newPassword = "NewAdmin123!"
    } | ConvertTo-Json
    
    try {
        $headers = @{ "Authorization" = "Bearer $adminToken" }
        $response = Invoke-RestMethod -Uri "$baseUrl/auth/change-password" -Method POST -Body $changePasswordRequest -ContentType "application/json" -Headers $headers
        Write-Host "✅ Password Change Successful" -ForegroundColor Green
        
        # Test login with new password
        Write-Host "   🔄 Testing login with new password..." -ForegroundColor Gray
        $newLoginTest = @{
            email = "admin@veterinary.com"
            password = "NewAdmin123!"
            clientType = "Desktop"
        } | ConvertTo-Json
        
        $newLoginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $newLoginTest -ContentType "application/json"
        Write-Host "   ✅ Login with new password successful!" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Change password failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 9: Change Password Without Authentication (Should Fail)
Write-Host "`n9️⃣ Testing Change Password Without Authentication" -ForegroundColor Yellow
$unauthorizedChangePassword = @{
    currentPassword = "Admin123!"
    newPassword = "NewAdmin123!"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/change-password" -Method POST -Body $unauthorizedChangePassword -ContentType "application/json"
    Write-Host "❌ Unauthorized password change should have failed!" -ForegroundColor Red
} catch {
    Write-Host "✅ Unauthorized Password Change Correctly Blocked (401)" -ForegroundColor Green
}

Write-Host "`n🎉 Authentication Testing Complete!" -ForegroundColor Cyan
Write-Host "=" * 50

Write-Host "`n📝 Test Credentials:" -ForegroundColor White
Write-Host "Admin (Desktop): admin@veterinary.com / Admin123!" -ForegroundColor Gray
Write-Host "Veterinarian (Desktop): vet@veterinary.com / Vet123!" -ForegroundColor Gray
Write-Host "Pet Owner (Mobile): petowner@email.com / Mobile123!" -ForegroundColor Gray
