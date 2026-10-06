DROP TABLE IF EXISTS fact_ride CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_slot CASCADE;
DROP TABLE IF EXISTS dim_weather CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;

-- Klantdimensie (dim_customer)
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_sk SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    name VARCHAR(100),
    email VARCHAR(100),
    street_number varchar(5),
    street_name varchar(100),
    zipcode varchar(10) NOT NULL,
    city varchar(100) NOT NULL,
    country_code varchar(3),
    subscription_type VARCHAR(50),
    scd_version INTEGER DEFAULT 1,
    subscription_start_date date,
    subscription_expiration_date date,
    Current_flag BOOLEAN
);

-- Slotdimensie (dim_slot)
CREATE TABLE IF NOT EXISTS dim_slot (
    lock_sk SERIAL PRIMARY KEY,
    lock_id INTEGER NOT NULL,
    station_id INTEGER NOT NULL,
    station_lock_nr INTEGER,
    station_nr varchar(20),
    station_zipcode varchar(10),
    station_type varchar(20),
    slot_type varchar(20),
    gpscoord point
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
CREATE TABLE IF NOT EXISTS dim_date (
    date_sk SERIAL PRIMARY KEY,       -- Surrogaatsleutel
    date DATE NOT NULL,               -- De feitelijke datum
    year INTEGER NOT NULL,            -- Jaar
    quarter INTEGER NOT NULL,         -- Kwartaal (1-4)
    month INTEGER NOT NULL,           -- Maand (1-12)
    month_name VARCHAR(20) NOT NULL,  -- Naam van de maand
    day_of_month INTEGER NOT NULL,    -- Dag van de maand (1-31)
    day_of_week INTEGER NOT NULL,     -- Dag van de week (1=maandag, 7=zondag)
    weekday_name VARCHAR(20),         -- Naam van de dag
    is_weekend BOOLEAN                -- True als het een weekend is, anders False
);

CREATE TABLE IF NOT EXISTS fact_ride (
    ride_sk SERIAL PRIMARY KEY,
    ride_id INTEGER NOT NULL,                -- Origineel ride ID uit operationele database
    customer_sk INTEGER NOT NULL,            -- Koppeling naar dim_customer
    start_slot_sk INTEGER,                   -- Koppeling naar startslot in dim_slot
    end_slot_sk INTEGER,                     -- Koppeling naar eindslot in dim_slot
    start_date_sk INTEGER NOT NULL,          -- Koppeling naar startdatum in dim_date
    end_date_sk INTEGER NOT NULL,            -- Koppeling naar einddatum in dim_date
    weather_sk INTEGER NOT NULL,             -- Koppeling naar dim_weather
    ride_duration_minutes NUMERIC(10, 2),    -- Duurtijd in minuten
    ride_distance_km NUMERIC(10, 2),         -- Afgelegde afstand in km
    CONSTRAINT fk_customer FOREIGN KEY (customer_sk) REFERENCES dim_customer(customer_sk),
    CONSTRAINT fk_start_slot FOREIGN KEY (start_slot_sk) REFERENCES dim_slot(lock_sk),
    CONSTRAINT fk_end_slot FOREIGN KEY (end_slot_sk) REFERENCES dim_slot(lock_sk),
    CONSTRAINT fk_weather FOREIGN KEY (weather_sk) REFERENCES dim_weather(weather_sk),
    CONSTRAINT fk_start_date FOREIGN KEY (start_date_sk) REFERENCES dim_date(date_sk),  -- Koppeling naar dim_date voor startdatum
    CONSTRAINT fk_end_date FOREIGN KEY (end_date_sk) REFERENCES dim_date(date_sk)     -- Koppeling naar dim_date voor einddatum
);

/*
CREATE OR REPLACE FUNCTION haversine_km(lat1 numeric, lon1 numeric, lat2 numeric, lon2 numeric)
RETURNS numeric AS $$
DECLARE
   distance numeric;
BEGIN
   -- Controleer of de coördinaten gelijk zijn
   IF lat1 = lat2 AND lon1 = lon2 THEN
       RETURN 0;  -- Afstand is 0 km
   END IF;

   -- Bereken de afstand met de haversine-formule
   SELECT 6371 * ACOS(
       COS(radians(lat1))
       * COS(radians(lat2))
       * COS(radians(lon2) - radians(lon1))
       + SIN(radians(lat1)) * SIN(radians(lat2))
   ) INTO distance;

   RETURN distance;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
*/