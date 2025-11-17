-- =============================================
-- AUTOMATSKA SQL SKRIPTA ZA SEED-OVANJE CIJENA
-- =============================================
-- Ova skripta automatski dodaje cijene za SVE usluge u bazi
-- Koristi dinamički pristup - prvo pronalazi sve usluge, zatim dodaje cijene
-- =============================================

-- Provjeri da li postoje usluge u bazi
IF NOT EXISTS (SELECT 1 FROM Services)
BEGIN
    PRINT 'UPOZORENJE: Nema usluga u bazi. Prvo dodaj usluge.';
    RETURN;
END

PRINT 'Pokretanje automatskog seed-ovanja cijena usluga po vrstama...';
PRINT '';

-- Privremena tabela sa cijenama
DECLARE @PriceTable TABLE (
    ServiceName NVARCHAR(200),
    Species NVARCHAR(50),
    Price DECIMAL(18,2)
);

-- Dodaj sve cijene u privremenu tabelu
INSERT INTO @PriceTable (ServiceName, Species, Price) VALUES
('Godišnji pregled', 'Pas', 75.00),
('Godišnji pregled', 'Mačka', 70.00),
('Godišnji pregled', 'Ptica', 60.00),
('Godišnji pregled', 'Zec', 65.00),
('Godišnji pregled', 'Glodar', 55.00),
('Vakcinacija', 'Pas', 120.00),
('Vakcinacija', 'Mačka', 110.00),
('Vakcinacija', 'Ptica', 100.00),
('Vakcinacija', 'Zec', 90.00),
('Vakcinacija', 'Glodar', 85.00),
('Hitna pomoć', 'Pas', 150.00),
('Hitna pomoć', 'Mačka', 140.00),
('Hitna pomoć', 'Ptica', 130.00),
('Hitna pomoć', 'Zec', 125.00),
('Hitna pomoć', 'Glodar', 120.00),
('Sterilizacija', 'Pas', 300.00),
('Sterilizacija', 'Mačka', 280.00),
('Sterilizacija', 'Ptica', 250.00),
('Sterilizacija', 'Zec', 200.00),
('Sterilizacija', 'Glodar', 180.00),
('Čišćenje zuba', 'Pas', 200.00),
('Čišćenje zuba', 'Mačka', 180.00),
('Čišćenje zuba', 'Ptica', 150.00),
('Čišćenje zuba', 'Zec', 120.00),
('Čišćenje zuba', 'Glodar', 100.00),
('Kompletno čišćenje', 'Pas', 80.00),
('Kompletno čišćenje', 'Mačka', 75.00),
('Kompletno čišćenje', 'Ptica', 70.00),
('Kompletno čišćenje', 'Zec', 60.00),
('Kompletno čišćenje', 'Glodar', 55.00);

-- MERGE za sve usluge odjednom
MERGE ServiceSpeciesPrices AS target
USING (
    SELECT 
        s.Id AS ServiceId,
        pt.Species,
        pt.Price
    FROM @PriceTable pt
    INNER JOIN Services s ON s.Name = pt.ServiceName
    WHERE s.IsActive = 1
) AS source ON target.ServiceId = source.ServiceId AND target.Species = source.Species
WHEN NOT MATCHED THEN
    INSERT (ServiceId, Species, Price, DateCreated)
    VALUES (source.ServiceId, source.Species, source.Price, GETUTCDATE())
WHEN MATCHED AND target.Price != source.Price THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

DECLARE @TotalCount INT = (SELECT COUNT(*) FROM ServiceSpeciesPrices);
DECLARE @AffectedRows INT = @@ROWCOUNT;

PRINT '';
PRINT '=============================================';
PRINT 'SEED-OVANJE ZAVRŠENO!';
PRINT '=============================================';
PRINT 'Dodano/ažurirano cijena: ' + CAST(@AffectedRows AS VARCHAR);
PRINT 'Ukupno cijena u bazi: ' + CAST(@TotalCount AS VARCHAR);
PRINT '';

-- Prikaži sve cijene
SELECT 
    s.Name AS 'Usluga',
    ssp.Species AS 'Vrsta',
    ssp.Price AS 'Cijena (KM)'
FROM ServiceSpeciesPrices ssp
INNER JOIN Services s ON ssp.ServiceId = s.Id
ORDER BY s.Name, ssp.Species;

-- Provjera po vrstama
PRINT '';
PRINT 'Provjera cijena po vrstama:';
SELECT 
    Species AS 'Vrsta',
    COUNT(*) AS 'Broj usluga'
FROM ServiceSpeciesPrices
GROUP BY Species
ORDER BY Species;

