Add-Type -AssemblyName System.Drawing

function Optimize-Image {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$MaxWidth = 300,
        [int]$MaxHeight = 200,
        [int]$Quality = 75
    )
    
    try {
        # Load original image
        $originalImage = [System.Drawing.Image]::FromFile($InputPath)
        
        # Calculate new dimensions maintaining aspect ratio
        $ratio = [Math]::Min($MaxWidth / $originalImage.Width, $MaxHeight / $originalImage.Height)
        $newWidth = [int]($originalImage.Width * $ratio)
        $newHeight = [int]($originalImage.Height * $ratio)
        
        # Create new bitmap with new dimensions
        $newImage = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($newImage)
        
        # Set high quality settings
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        
        # Draw resized image
        $graphics.DrawImage($originalImage, 0, 0, $newWidth, $newHeight)
        
        # Save with JPEG quality
        $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageDecoders() | Where-Object { $_.FormatID -eq [System.Drawing.Imaging.ImageFormat]::Jpeg.Guid }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $Quality)
        
        $newImage.Save($OutputPath, $jpegCodec, $encoderParams)
        
        # Cleanup
        $graphics.Dispose()
        $newImage.Dispose()
        $originalImage.Dispose()
        
        Write-Host "Optimized: $InputPath -> $OutputPath"
        Write-Host "Original size: $((Get-Item $InputPath).Length) bytes"
        Write-Host "New size: $((Get-Item $OutputPath).Length) bytes"
        
    } catch {
        Write-Error "Error optimizing $InputPath : $($_.Exception.Message)"
    }
}

# Optimize images
Write-Host "Starting image optimization..."

# Create backup and optimize
Copy-Item "rex.jpg" "rex_backup.jpg"
Copy-Item "pets_group.jpg" "pets_group_backup.jpg"

Optimize-Image "rex.jpg" "rex_optimized.jpg"
Optimize-Image "pets_group.jpg" "pets_group_optimized.jpg"

# Replace original files
Move-Item "rex_optimized.jpg" "rex.jpg" -Force
Move-Item "pets_group_optimized.jpg" "pets_group.jpg" -Force

Write-Host "Image optimization completed!"

