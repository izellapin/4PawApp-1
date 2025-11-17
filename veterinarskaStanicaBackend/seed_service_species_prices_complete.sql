-- =============================================
-- KOMPLETNA SQL SKRIPTA ZA SEED-OVANJE CIJENA USLUGA PO VRSTAMA
-- =============================================
-- Izvrši ovu skriptu direktno u SQL Server Management Studio
-- Ova skripta automatski dodaje cijene za SVE usluge u bazi
-- Koristi MERGE da izbjegne duplikate i ažurira postojeće cijene
-- =============================================

-- Provjeri da li postoje usluge u bazi
IF NOT EXISTS (SELECT 1 FROM Services)
BEGIN
    PRINT 'UPOZORENJE: Nema usluga u bazi. Prvo dodaj usluge.';
    RETURN;
END

PRINT 'Pokretanje seed-ovanja cijena usluga po vrstama...';
PRINT '';

DECLARE @AddedCount INT = 0;
DECLARE @UpdatedCount INT = 0;

-- =============================================
-- 1. GODIŠNJI PREGLED
-- =============================================
MERGE ServiceSpeciesPrices AS target
USING (
    SELECT Id as ServiceId, 'Pas' as Species, 75.00 as Price FROM Services WHERE Name = 'Godišnji pregled'
    UNION ALL
    SELECT Id, 'Mačka', 70.00 FROM Services WHERE Name = 'Godišnji pregled'
    UNION ALL
    SELECT Id, 'Ptica', 60.00 FROM Services WHERE Name = 'Godišnji pregled'
    UNION ALL
    SELECT Id, 'Zec', 65.00 FROM Services WHERE Name = 'Godišnji pregled'
    UNION ALL
    SELECT Id, 'Glodar', 55.00 FROM Services WHERE Name = 'Godišnji pregled'
) AS source ON target.ServiceId = source.ServiceId AND target.Species = source.Species
WHEN NOT MATCHED THEN
    INSERT (ServiceId, Species, Price, DateCreated)
    VALUES (source.ServiceId, source.Species, source.Price, GETUTCDATE())
WHEN MATCHED AND target.Price != source.Price THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

SET @AddedCount = @AddedCount + @@ROWCOUNT;
PRINT 'Godišnji pregled: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' cijena dodano/ažurirano';

-- =============================================
-- 2. VAKCINACIJA
-- =============================================
MERGE ServiceSpeciesPrices AS target
USING (
    SELECT Id as ServiceId, 'Pas' as Species, 120.00 as Price FROM Services WHERE Name = 'Vakcinacija'
    UNION ALL
    SELECT Id, 'Mačka', 110.00 FROM Services WHERE Name = 'Vakcinacija'
    UNION ALL
    SELECT Id, 'Ptica', 100.00 FROM Services WHERE Name = 'Vakcinacija'
    UNION ALL
    SELECT Id, 'Zec', 90.00 FROM Services WHERE Name = 'Vakcinacija'
    UNION ALL
    SELECT Id, 'Glodar', 85.00 FROM Services WHERE Name = 'Vakcinacija'
) AS source ON target.ServiceId = source.ServiceId AND target.Species = source.Species
WHEN NOT MATCHED THEN
    INSERT (ServiceId, Species, Price, DateCreated)
    VALUES (source.ServiceId, source.Species, source.Price, GETUTCDATE())
WHEN MATCHED AND target.Price != source.Price THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

SET @AddedCount = @AddedCount + @@ROWCOUNT;
PRINT 'Vakcinacija: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' cijena dodano/ažurirano';

-- =============================================
-- 3. HITNA POMOĆ
-- =============================================
MERGE ServiceSpeciesPrices AS target
USING (
    SELECT Id as ServiceId, 'Pas' as Species, 150.00 as Price FROM Services WHERE Name = 'Hitna pomoć'
    UNION ALL
    SELECT Id, 'Mačka', 140.00 FROM Services WHERE Name = 'Hitna pomoć'
    UNION ALL
    SELECT Id, 'Ptica', 130.00 FROM Services WHERE Name = 'Hitna pomoć'
    UNION ALL
    SELECT Id, 'Zec', 125.00 FROM Services WHERE Name = 'Hitna pomoć'
    UNION ALL
    SELECT Id, 'Glodar', 120.00 FROM Services WHERE Name = 'Hitna pomoć'
) AS source ON target.ServiceId = source.ServiceId AND target.Species = source.Species
WHEN NOT MATCHED THEN
    INSERT (ServiceId, Species, Price, DateCreated)
    VALUES (source.ServiceId, source.Species, source.Price, GETUTCDATE())
WHEN MATCHED AND target.Price != source.Price THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

SET @AddedCount = @AddedCount + @@ROWCOUNT;
PRINT 'Hitna pomoć: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' cijena dodano/ažurirano';

-- =============================================
-- 4. STERILIZACIJA
-- =============================================
MERGE ServiceSpeciesPrices AS target
USING (
    SELECT Id as ServiceId, 'Pas' as Species, 300.00 as Price FROM Services WHERE Name = 'Sterilizacija'
    UNION ALL
    SELECT Id, 'Mačka', 280.00 FROM Services WHERE Name = 'Sterilizacija'
    UNION ALL
    SELECT Id, 'Ptica', 250.00 FROM Services WHERE Name = 'Sterilizacija'
    UNION ALL
    SELECT Id, 'Zec', 200.00 FROM Services WHERE Name = 'Sterilizacija'
    UNION ALL
    SELECT Id, 'Glodar', 180.00 FROM Services WHERE Name = 'Sterilizacija'
) AS source ON target.ServiceId = source.ServiceId AND target.Species = source.Species
WHEN NOT MATCHED THEN
    INSERT (ServiceId, Species, Price, DateCreated)
    VALUES (source.ServiceId, source.Species, source.Price, GETUTCDATE())
WHEN MATCHED AND target.Price != source.Price THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

SET @AddedCount = @AddedCount + @@ROWCOUNT;
PRINT 'Sterilizacija: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' cijena dodano/ažurirano';

-- =============================================
-- 5. ČIŠĆENJE ZUBA
-- =============================================
MERGE ServiceSpeciesPrices AS target
USING (
    SELECT Id as ServiceId, 'Pas' as Species, 200.00 as Price FROM Services WHERE Name = 'Čišćenje zuba'
    UNION ALL
    SELECT Id, 'Mačka', 180.00 FROM Services WHERE Name = 'Čišćenje zuba'
    UNION ALL
    SELECT Id, 'Ptica', 150.00 FROM Services WHERE Name = 'Čišćenje zuba'
    UNION ALL
    SELECT Id, 'Zec', 120.00 FROM Services WHERE Name = 'Čišćenje zuba'
    UNION ALL
    SELECT Id, 'Glodar', 100.00 FROM Services WHERE Name = 'Čišćenje zuba'
) AS source ON target.ServiceId = source.ServiceId AND target.Species = source.Species
WHEN NOT MATCHED THEN
    INSERT (ServiceId, Species, Price, DateCreated)
    VALUES (source.ServiceId, source.Species, source.Price, GETUTCDATE())
WHEN MATCHED AND target.Price != source.Price THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

SET @AddedCount = @AddedCount + @@ROWCOUNT;
PRINT 'Čišćenje zuba: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' cijena dodano/ažurirano';

-- =============================================
-- 6. KOMPLETNO ČIŠĆENJE
-- =============================================
MERGE ServiceSpeciesPrices AS target
USING (
    SELECT Id as ServiceId, 'Pas' as Species, 80.00 as Price FROM Services WHERE Name = 'Kompletno čišćenje'
    UNION ALL
    SELECT Id, 'Mačka', 75.00 FROM Services WHERE Name = 'Kompletno čišćenje'
    UNION ALL
    SELECT Id, 'Ptica', 70.00 FROM Services WHERE Name = 'Kompletno čišćenje'
    UNION ALL
    SELECT Id, 'Zec', 60.00 FROM Services WHERE Name = 'Kompletno čišćenje'
    UNION ALL
    SELECT Id, 'Glodar', 55.00 FROM Services WHERE Name = 'Kompletno čišćenje'
) AS source ON target.ServiceId = source.ServiceId AND target.Species = source.Species
WHEN NOT MATCHED THEN
    INSERT (ServiceId, Species, Price, DateCreated)
    VALUES (source.ServiceId, source.Species, source.Price, GETUTCDATE())
WHEN MATCHED AND target.Price != source.Price THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

SET @AddedCount = @AddedCount + @@ROWCOUNT;
PRINT 'Kompletno čišćenje: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' cijena dodano/ažurirano';

-- =============================================
-- REZULTATI
-- =============================================
PRINT '';
PRINT '=============================================';
PRINT 'SEED-OVANJE ZAVRŠENO!';
PRINT '=============================================';
PRINT 'Ukupno cijena u bazi: ' + CAST((SELECT COUNT(*) FROM ServiceSpeciesPrices) AS VARCHAR);
PRINT '';

-- Prikaži sve cijene po uslugama
SELECT 
    s.Name AS 'Usluga',
    ssp.Species AS 'Vrsta',
    ssp.Price AS 'Cijena (KM)',
    ssp.DateCreated AS 'Datum kreiranja',
    ssp.DateModified AS 'Datum ažuriranja'
FROM ServiceSpeciesPrices ssp
INNER JOIN Services s ON ssp.ServiceId = s.Id
ORDER BY s.Name, ssp.Species;

PRINT '';
PRINT 'Provjera cijena po vrstama:';
SELECT 
    Species AS 'Vrsta',
    COUNT(*) AS 'Broj usluga',
    MIN(Price) AS 'Min cijena',
    MAX(Price) AS 'Max cijena',
    AVG(Price) AS 'Prosječna cijena'
FROM ServiceSpeciesPrices
GROUP BY Species
ORDER BY Species;

