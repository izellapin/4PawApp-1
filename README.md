# 🐾 4Paw - Veterinary Clinic Management System

Kompletan sistem za upravljanje veterinarskom stanicom sa desktop i mobile aplikacijama.


## 🔐 Testni Accounti

****** Desktop App:

### Administrator

**Email:** `izellapin@gmail.com`  
**Password:** `Admin123!`

Administrator ima pristup svim funkcionalnostima:
- Upravljanje korisnicima (dodavanje veterinara, recepcionera)
- Pregled svih termina
- Finansijski izvještaji i statistike
- Upravljanje uslugama i kategorijama

### Veterinar (Kreira ga administrator)

**Email:** `adil@edu.fit.ba`  
**Password:** `Vet123!`

**Kako dodati veterinara:**
1. Prijavite se kao administrator (`izellapin@gmail.com`)
2. Idite na sekciju "Veterinari"
3. Kliknite "Dodaj novog veterinara"
4. Popunite formu:
   - Email: `adil@edu.fit.ba`
   - Password: `Vet123!`
5. Sačuvaj


***** Mobile App:

### Vlasnik ljubimca (Pet Owner) 

**Email:** `adil+1@edu.fit.ba`  
**Password:** `Owner123!`

**Kako registrovati korisnika:**
1. Otvorite mobile aplikaciju
2. Kliknite "Registracija"
3. Popunite formu:
   - Email: `adil+1@edu.fit.ba`
   - Password: `Owner123!`
   - Ime, prezime, username
   - Ostali podaci po potrebi
4. Potvrdite email adresu (verifikacioni email će biti poslan)
5. Prijavite se sa novim kredencijalima


## 📖 Kako se koristi

### Za Administratora

1. **Prijava:**
   - Otvorite desktop aplikaciju
   - Unesite email: `izellapin@gmail.com` i password: `Admin123!`
   - Kliknite "Prijavi se"

2. **Dodavanje veterinara:**
   - Navigirajte na "Korisnici" ili "Veterinari" u sidebar-u
   - Kliknite "Dodaj novog korisnika"
   - Popunite formu i postavite role na "Veterinarian"
   - Sačuvaj

3. **Pregled finansijskih izvještaja:**
   - Idite na "Finansije" ili "Dashboard"
   - Prikazuju se:
     - Dnevni/mjesečni/godišnji prihod
     - Top usluge po prihodu
     - Najbolji klijenti
     - Grafici prihoda

4. **Upravljanje terminima:**
   - Navigirajte na "Termini"
   - Pregled svih termina u sistemu
   - Možete filtrirati po datumu, statusu, veterinaru

### Za Veterinara

1. **Prijava:**
   - Otvorite desktop aplikaciju
   - Unesite email: `adil@edu.fit.ba` i password: `Vet123!`
   - Kliknite "Prijavi se"

2. **Pregled svojih termina:**
   - Navigirajte na "Termini"
   - Prikazuju se samo vaši termini
   - Možete označiti termin kao završen i unijeti stvarnu cijenu

3. **Finansijske statistike:**
   - Idite na "Finansije" ili "Dashboard"
   - Prikazuju se:
     - Vaši top usluge (najčešće korišćene)
     - Dnevni/mjesečni prihod
     - Broj pacijenata
     - Prosječna ocjena od klijenata

4. **Upravljanje pacijentima:**
   - Navigirajte na "Ljubimci"
   - Pregled svih pacijenata koje ste liječili
   - Dodavanje medicinskih zapisa

### Za Vlasnika ljubimca

1. **Registracija:**
   - Otvorite mobile aplikaciju
   - Kliknite "Registracija"
   - Popunite formu sa email: `adil+1@edu.fit.ba` i password: `Owner123!`
   - Potvrdite email adresu (verifikacioni kod će biti poslat na email)

2. **Prijava:**
   - Otvorite mobile aplikaciju
   - Unesite email i password
   - Kliknite "Prijavi se"

3. **Dodavanje ljubimca:**
   - Idite na "Ljubimci" tab
   - Kliknite "Dodaj ljubimca"
   - Popunite formu:
     - Ime ljubimca
     - Vrsta (pas, mačka, itd.)
     - Rasa
     - Datum rođenja
     - Pol
     - Slika (opciono)
   - Sačuvaj

4. **Zakazivanje termina:**
   - Idite na "Termini" tab
   - Kliknite "Zakaži termin" ili idite na "Početna" → "Zakaži termin"
   - Popunite formu:
     - Odaberite ljubimca
     - Odaberite veterinara
     - Odaberite uslugu (opciono)
     - Odaberite datum i vrijeme
     - Unesite razlog posjete
   - Kliknite "Zakazi"
   - Plaćanje se može obaviti kroz Stripe integraciju

5. **Pregled termina:**
   - Navigirajte na "Termini" tab
   - Prikazuju se:
     - Nadolazeći termini (plavi)
     - Prošli termini (sivi)
   - Možete otkazati nadolazeći termin
   - Možete ocjeniti veterinara nakon završenog termina

6. **Ocjenjivanje veterinara:**
   - Nakon završenog termina, idite na "Termini"
   - Pronađite prošli termin
   - Kliknite "Ocijeni" ili "Ostavi recenziju"
   - Unesite ocjenu (1-5) i komentar
   - Sačuvaj


## 🛠️ Tehnologije

### Backend
- **ASP.NET Core 8.0** - Web API framework
- **Entity Framework Core** - ORM
- **SQL Server** - Baza podataka
- **JWT** - Autentifikacija
- **Docker** - Containerizacija
- **RabbitMQ** - Message queue (notifikacije)

### Frontend
- **Flutter 3.9+** - Cross-platform framework
- **Dart 3.0+** - Programski jezik
- **Provider** - State management
- **Dio** - HTTP klijent
- **Shared Preferences** - Local storage


## 📝 Napomene

- **Email verifikacija** - Korisnici moraju potvrditi email adresu nakon registracije
- **JWT tokeni** - Tokeni se automatski refresh-uju kada isteknu
- **Role-based access** - Različiti korisnici imaju različite dozvole
- **Docker** - Backend se pokreće preko Docker Compose-a
