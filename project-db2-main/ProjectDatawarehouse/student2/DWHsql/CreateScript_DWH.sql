DROP TABLE IF EXISTS fact_ride CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_lock CASCADE;
DROP TABLE IF EXISTS dim_weather CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;

-- Klantdimensie (dim_customer)
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_sk SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    name VARCHAR(100),
    email VARCHAR(100),
    street_number VARCHAR(50),
    street_name VARCHAR(100),
    zipcode VARCHAR(5),
    city VARCHAR(100) NOT NULL,
    country_code VARCHAR(3),
    subscription_type varchar(50),
    scd_version INTEGER DEFAULT 1,
    scd_start_date DATE,
    scd_expiration_date DATE
);

-- Slotdimensie (dim_locks)
CREATE TABLE IF NOT EXISTS dim_locks (
    lock_sk SERIAL PRIMARY KEY,
    lockid INTEGER NOT NULL,
    stationid INTEGER NULL,
    stationtype VARCHAR(20),
    station_straat VARCHAR(100),
    station_numeric VARCHAR(10),
    station_zipcode VARCHAR(10),
    station_district VARCHAR(100),
    station_coordinations POINT
);


CREATE TABLE IF NOT EXISTS dim_date (
    date_sk SERIAL PRIMARY KEY,      -- Surrogaatsleutel
    date DATE NOT NULL,              -- De feitelijke datum
    year INTEGER NOT NULL,           -- Jaar
    quarter INTEGER NOT NULL,        -- Kwartaal (1-4)
    month INTEGER NOT NULL,          -- Maand (1-12)
    month_name VARCHAR(20) NOT NULL, -- Naam van de maand
    day_of_month INTEGER NOT NULL,   -- Dag van de maand (1-31)
    day_of_week INTEGER NOT NULL,    -- Dag van de week (1=maandag, 7=zondag)
    weekday_name VARCHAR(20),        -- Naam van de dag
    is_weekend BOOLEAN               -- True als het een weekend is, anders False


);
CREATE TABLE IF NOT EXISTS dim_weather (
    weather_sk SERIAL PRIMARY KEY,   -- Surrogaatsleutel
    weather_type VARCHAR(20) NOT NULL -- Weertype zoals 'Onaangenaam', 'Aangenaam', etc.
);

CREATE TABLE IF NOT EXISTS fact_ride (
    ride_sk SERIAL PRIMARY KEY,           -- Surrogaatsleutel voor de fact table
    customer_sk INTEGER NOT NULL,         -- Verwijzing naar de klantdimensie
    lock_sk_start INTEGER NOT NULL,       -- Verwijzing naar het startslot in de slotdimensie
    lock_sk_end INTEGER NOT NULL,         -- Verwijzing naar het eindslot in de slotdimensie
    start_date_sk INTEGER NOT NULL,       -- Verwijzing naar de startdatum in de datadimensie
    end_date_sk INTEGER,                  -- Verwijzing naar de einddatum in de datadimensie
    weather_sk INTEGER DEFAULT NULL,      -- Verwijzing naar de weersdimensie
    duration_minutes INTEGER NOT NULL,    -- Duur van de rit in minuten
    distance_km NUMERIC(10, 5) NOT NULL,  -- Afgelegde afstand in kilometers
    FOREIGN KEY (customer_sk) REFERENCES dim_customer(customer_sk),
    FOREIGN KEY (lock_sk_start) REFERENCES dim_locks(lock_sk),
    FOREIGN KEY (lock_sk_end) REFERENCES dim_locks(lock_sk),
    FOREIGN KEY (start_date_sk) REFERENCES dim_date(date_sk),
    FOREIGN KEY (end_date_sk) REFERENCES dim_date(date_sk),
    FOREIGN KEY (weather_sk) REFERENCES dim_weather(weather_sk)
);
CREATE SEQUENCE customers_sk_seq START WITH 1 INCREMENT BY 1;
ALTER TABLE dim_customer ALTER COLUMN customer_sk SET DEFAULT nextval('customers_sk_seq');
ALTER SEQUENCE customers_sk_seq START WITH 1 INCREMENT BY 1;
ALTER SEQUENCE customers_sk_seq RESTART WITH 1;
select nextval('customers_sk_seq');
SELECT MAX(customer_sk) FROM dim_customer;
DROP SEQUENCE IF EXISTS customer_sk_seq CASCADE;

INSERT INTO dim_locks (lock_sk, lockid, stationid, stationtype, station_straat, station_numeric, station_zipcode, station_district, station_coordinations)
VALUES (0, 0, 0, '0', '0', '0', '0', '0', POINT(0, 0))
ON CONFLICT (lock_sk) DO NOTHING;



-- Step 1: Create the sequence
CREATE SEQUENCE fact_ride_ride_sk_seq START WITH 1 INCREMENT BY 1;

-- Step 2: Attach the sequence to the `ride_sk` column
ALTER TABLE fact_ride ALTER COLUMN ride_sk SET DEFAULT nextval('fact_ride_ride_sk_seq');

ALTER SEQUENCE fact_ride_ride_sk_seq START WITH 1 INCREMENT BY 1;
ALTER SEQUENCE fact_ride_ride_sk_seq RESTART WITH 1;
select nextval('fact_ride_ride_sk_seq');


CREATE OR REPLACE FUNCTION haversine_km(
    lat1 double precision, lon1 double precision,
    lat2 double precision, lon2 double precision
)
RETURNS double precision AS $$
DECLARE
    distance double precision;
BEGIN
    IF lat1 = lat2 AND lon1 = lon2 THEN
        RETURN 0;  -- Afstand is 0 km als de coördinaten hetzelfde zijn
    END IF;

    SELECT 6371 * ACOS(
        COS(radians(lat1)) * COS(radians(lat2)) *
        COS(radians(lon2) - radians(lon1)) +
        SIN(radians(lat1)) * SIN(radians(lat2))
    ) INTO distance;

    RETURN distance;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

