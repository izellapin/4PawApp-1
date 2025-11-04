@echo off
echo Stopping any running processes...
taskkill /f /im "veterinarskaStanica.WebAPI.exe" 2>nul

echo Navigating to WebAPI directory...
cd /d "%~dp0veterinarskaStanica.WebAPI"

echo Creating migration...
dotnet ef migrations add VeterinaryDatabaseUpdate --project "../eVeterinarskaStanicaServices" --startup-project .

echo Updating database...
dotnet ef database update --project "../eVeterinarskaStanicaServices" --startup-project .

echo Database update complete!
pause
