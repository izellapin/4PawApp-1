-- SQL skripta za ručno dodavanje cijena usluga po vrstama
-- Izvrši ovu skriptu direktno u SQL Server Management Studio
-- Ova skripta koristi MERGE da izbjegne duplikate

-- Godišnji pregled
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
WHEN MATCHED THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

-- Vakcinacija
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
WHEN MATCHED THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

-- Hitna pomoć
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
WHEN MATCHED THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

-- Sterilizacija
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
WHEN MATCHED THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

-- Čišćenje zuba
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
WHEN MATCHED THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

-- Kompletno čišćenje
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
WHEN MATCHED THEN
    UPDATE SET Price = source.Price, DateModified = GETUTCDATE();

-- Provjeri rezultat
SELECT COUNT(*) as 'Ukupno cijena' FROM ServiceSpeciesPrices;
SELECT * FROM ServiceSpeciesPrices ORDER BY ServiceId, Species;
