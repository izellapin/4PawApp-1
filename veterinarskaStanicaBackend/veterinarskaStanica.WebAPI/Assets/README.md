# Assets Folder Structure

This folder contains static files and images for the Veterinary Clinic system.

## 📁 Folder Structure

```
Assets/
├── Pets/                    # Pet profile images
│   ├── profile/             # Pet profile photos
│   ├── medical/             # Medical condition photos
│   └── documents/           # Pet documents (passports, certificates)
│
├── Users/                   # User profile images
│   ├── veterinarians/       # Veterinarian profile photos
│   ├── technicians/         # Technician profile photos
│   └── pet-owners/         # Pet owner profile photos
│
└── MedicalRecords/          # Medical documentation
    ├── x-rays/              # X-ray images
    ├── lab-results/         # Lab test results
    ├── prescriptions/       # Prescription images
    └── reports/             # Medical reports
```

## 🖼️ Supported Image Formats

- **Profile Images**: JPG, PNG, WEBP (max 2MB)
- **Medical Images**: JPG, PNG, DICOM (max 10MB)
- **Documents**: PDF, JPG, PNG (max 5MB)

## 📏 Image Guidelines

### Pet Profile Images
- **Recommended size**: 400x400px
- **Format**: JPG or PNG
- **Max file size**: 2MB

### Medical Images
- **Recommended size**: 1920x1080px or higher
- **Format**: JPG or PNG
- **Max file size**: 10MB

### User Profile Images
- **Recommended size**: 300x300px
- **Format**: JPG or PNG
- **Max file size**: 1MB

## 🔒 Security Notes

- All uploaded files are scanned for malware
- File names are sanitized to prevent path traversal attacks
- Access is controlled by user roles and permissions
- Sensitive medical images require veterinarian access level

## 🚀 Usage in Docker

This folder is mounted as a volume in Docker containers:
- **Development**: Local folder mapping
- **Production**: Persistent Docker volume
- **Backup**: Included in automated backups

## 📝 File Naming Convention

- **Pet images**: `pet_{petId}_{timestamp}.{ext}`
- **User images**: `user_{userId}_{timestamp}.{ext}`
- **Medical images**: `medical_{recordId}_{type}_{timestamp}.{ext}`

Example: `pet_123_20250923_profile.jpg`
