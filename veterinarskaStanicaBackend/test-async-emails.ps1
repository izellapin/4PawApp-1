# 4Paw Async Email Test Script
# Testira RabbitMQ asinhroni email sistem

param(
    [Parameter(Mandatory=$true)]
    [string]$Email,
    
    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = "http://localhost:5160",
    
    [Parameter(Mandatory=$false)]
    [string]$TestType = "all"
)

Write-Host "🐰 4Paw Async Email Test Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Test Email: $Email" -ForegroundColor Yellow
Write-Host "API Base URL: $BaseUrl" -ForegroundColor Yellow
Write-Host "Test Type: $TestType" -ForegroundColor Yellow
Write-Host ""

# Function to make HTTP request and measure time
function Invoke-TimedRequest {
    param([string]$Url, [string]$TestName)
    
    Write-Host "🧪 Testing: $TestName" -ForegroundColor Green
    Write-Host "URL: $Url" -ForegroundColor Gray
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-RestMethod -Uri $Url -Method GET
        $stopwatch.Stop()
        
        Write-Host "✅ SUCCESS - Response time: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
        if ($stopwatch.ElapsedMilliseconds -lt 1000) {
            Write-Host "🚀 FAST response - This indicates async processing is working!" -ForegroundColor Cyan
        }
        Write-Host "Response: $($response.message)" -ForegroundColor White
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

# Check if API is running
Write-Host "🔍 Checking if API is running..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET
    Write-Host "✅ API is running" -ForegroundColor Green
} catch {
    Write-Host "❌ API is not running. Please start the API first:" -ForegroundColor Red
    Write-Host "   dotnet run --project veterinarskaStanica.WebAPI" -ForegroundColor Yellow
    Write-Host "   or: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

# Check RabbitMQ
Write-Host "🐰 Checking RabbitMQ..." -ForegroundColor Yellow
try {
    $rabbitCheck = Invoke-WebRequest -Uri "http://localhost:15672" -Method GET -TimeoutSec 5
    Write-Host "✅ RabbitMQ Management UI is accessible" -ForegroundColor Green
} catch {
    Write-Host "⚠️  RabbitMQ Management UI not accessible. Make sure RabbitMQ is running:" -ForegroundColor Yellow
    Write-Host "   docker-compose up rabbitmq -d" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🚀 Starting async email tests..." -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

# Test based on type
switch ($TestType.ToLower()) {
    "appointment" {
        $allPassed = Invoke-TimedRequest "$BaseUrl/api/AsyncEmailTest/appointment?email=$Email" "Appointment Notification"
    }
    "service" {
        $allPassed = Invoke-TimedRequest "$BaseUrl/api/AsyncEmailTest/service?email=$Email" "Service Notification (CineVibe Pattern)"
    }
    "registration" {
        $allPassed = Invoke-TimedRequest "$BaseUrl/api/AsyncEmailTest/registration?email=$Email" "User Registration Notification"
    }
    "system" {
        $allPassed = Invoke-TimedRequest "$BaseUrl/api/AsyncEmailTest/system?email=$Email" "System Notification"
    }
    "performance" {
        $allPassed = Invoke-TimedRequest "$BaseUrl/api/AsyncEmailTest/performance?email=$Email" "Performance Test"
    }
    "bulk" {
        $allPassed = Invoke-TimedRequest "$BaseUrl/api/AsyncEmailTest/bulk?email=$Email&count=3" "Bulk Notifications Test"
    }
    "all" {
        Write-Host "🔄 Running all tests..." -ForegroundColor Cyan
        Write-Host ""
        
        $tests = @(
            @{Name="Appointment Notification"; Url="$BaseUrl/api/AsyncEmailTest/appointment?email=$Email"},
            @{Name="Service Notification (CineVibe Pattern)"; Url="$BaseUrl/api/AsyncEmailTest/service?email=$Email"},
            @{Name="User Registration Notification"; Url="$BaseUrl/api/AsyncEmailTest/registration?email=$Email"},
            @{Name="System Notification"; Url="$BaseUrl/api/AsyncEmailTest/system?email=$Email"},
            @{Name="Performance Test"; Url="$BaseUrl/api/AsyncEmailTest/performance?email=$Email"},
            @{Name="Bulk Notifications (3 emails)"; Url="$BaseUrl/api/AsyncEmailTest/bulk?email=$Email&count=3"}
        )
        
        $passedCount = 0
        foreach ($test in $tests) {
            if (Invoke-TimedRequest $test.Url $test.Name) {
                $passedCount++
            }
            Start-Sleep -Seconds 1  # Kratka pauza između testova
        }
        
        $allPassed = ($passedCount -eq $tests.Count)
        
        Write-Host "📊 Test Summary:" -ForegroundColor Cyan
        Write-Host "Passed: $passedCount / $($tests.Count)" -ForegroundColor $(if ($allPassed) { "Green" } else { "Yellow" })
    }
    default {
        Write-Host "❌ Invalid test type. Available options: appointment, service, registration, system, performance, bulk, all" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🏁 Tests completed!" -ForegroundColor Cyan
Write-Host ""

if ($allPassed) {
    Write-Host "🎉 All tests passed!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed. Check the output above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 What to check now:" -ForegroundColor Cyan
Write-Host "1. 🐰 RabbitMQ Management UI: http://localhost:15672 (admin/admin123)" -ForegroundColor White
Write-Host "   - Check Queues tab for message counts" -ForegroundColor Gray
Write-Host "   - Look for queues: 4paw_appointment_notifications, 4paw_service_notifications, etc." -ForegroundColor Gray
Write-Host ""
Write-Host "2. 📧 Email Inbox: Check $Email for received test emails" -ForegroundColor White
Write-Host ""
Write-Host "3. 📝 Application Logs: Check console output for:" -ForegroundColor White
Write-Host "   - 'Published ... notification'" -ForegroundColor Gray
Write-Host "   - 'Processing ... notification'" -ForegroundColor Gray
Write-Host "   - 'Email sent successfully'" -ForegroundColor Gray
Write-Host ""
Write-Host "4. ⚡ Performance: API responses should be fast (< 1000ms) because emails are async" -ForegroundColor White
Write-Host ""

# Examples for different test types
Write-Host "💡 Example commands:" -ForegroundColor Cyan
Write-Host ".\test-async-emails.ps1 -Email 'your@email.com' -TestType 'all'" -ForegroundColor Gray
Write-Host ".\test-async-emails.ps1 -Email 'your@email.com' -TestType 'service'" -ForegroundColor Gray
Write-Host ".\test-async-emails.ps1 -Email 'your@email.com' -TestType 'performance'" -ForegroundColor Gray
















