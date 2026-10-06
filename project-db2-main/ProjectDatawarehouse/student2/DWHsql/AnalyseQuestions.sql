


-- [S1] Wat zijn de drukke momenten (op dagbasis) in de week t.o.v. het weekend?
-- Dinsdag is het drukste
SELECT
    d.day_of_week, d.weekday_name,
    COUNT(f.ride_sk) AS total_rides
FROM
    fact_ride f
JOIN
    dim_date d ON f.start_date_sk = d.date_sk
GROUP BY
    d.day_of_week, d.weekday_name
ORDER BY
    CASE
        WHEN d.day_of_week IN (6, 7) THEN 1 ELSE 0
    END,
    total_rides DESC;


-- [S1] Hebben datumparameters invloed op de afgelegde afstand?
-- Heel kleine verschil, maakt bijna geen verschil
SELECT
    d.day_of_week, d.weekday_name,
    AVG(f.distance_km) AS avg_distance
FROM
    fact_ride f
JOIN
    dim_date d ON f.start_date_sk = d.date_sk
GROUP BY
    d.day_of_week, d.weekday_name
ORDER BY
    avg_distance DESC;


-- [S1] Heeft weer invloed op ritten?

SELECT
    w.weather_type,
    COUNT(f.ride_sk) AS total_rides,
    AVG(f.distance_km) AS avg_distance
FROM
    fact_ride f
JOIN
    dim_weather w ON f.weather_sk = w.weather_sk
GROUP BY
    w.weather_type
ORDER BY
    total_rides DESC;

truncate table dim_customer;
truncate table fact_ride;

-- [S2] Wat is de invloed van de woonplaats van de gebruikers op het gebruik van de vehicles?
-- Stad Antwerpen het drukste, vergeleken met andere gemeentes
SELECT
    c.city,
    COUNT(f.ride_sk) AS total_rides
FROM
    fact_ride f
JOIN
    dim_customer c ON f.customer_sk = c.customer_sk
GROUP BY
    c.city
ORDER BY
    total_rides DESC;


-- [S2] We willen voorspellen welke sloten preventief onderhoud nodig hebben.

SELECT s.lockid, COUNT(f.ride_sk) AS usage_count
FROM fact_ride f
JOIN dim_locks s ON f.lock_sk_start = s.lock_sk OR f.lock_sk_end = s.lock_sk
GROUP BY  s.lockid
ORDER BY usage_count DESC;


-- [S2] Als een klant zijn abonnement stopzet, willen we kunnen voorspellen op welke stations dit het meeste effect zal hebben.

SELECT
    s.stationid,
    s.station_zipcode,
    COUNT(r.ride_sk) AS usage_count,
    c.scd_expiration_date
FROM
    fact_ride r
LEFT JOIN dim_locks s ON r.lock_sk_start = s.lock_sk
LEFT JOIN dim_customer c ON r.customer_sk = c.customer_sk
WHERE
    c.scd_expiration_date IS NOT NULL
GROUP BY
    s.stationid, s.station_zipcode, c.scd_expiration_date
ORDER BY
    usage_count DESC;




-- EXTRA QUERIES

-- [S1] Welke dagen van de week hebben gemiddeld de langste ritten (in minuten)?
SELECT
    d.weekday_name,
    AVG(r.duration_minutes) AS avg_duration
FROM
    fact_ride r
JOIN
    dim_date d ON r.start_date_sk = d.date_sk
GROUP BY
    d.weekday_name
ORDER BY
    avg_duration DESC;

-- [S1] Welke dagen hebben de meeste korte ritten (minder dan 5 minuten)?


SELECT
    d.day_of_week, d.weekday_name,
    COUNT(f.ride_sk) AS short_rides
FROM
    fact_ride f
JOIN
    dim_date d ON f.start_date_sk = d.date_sk
WHERE
    f.duration_minutes < 5
GROUP BY
    d.day_of_week, d.weekday_name
ORDER BY
    short_rides DESC;


-- [S2] Welke klanten hebben de meeste ritten gemaakt in een bepaalde periode?

SELECT
    c.name AS customer_name,
    c.email AS customer_email,
    COUNT(r.ride_sk) AS ride_count
FROM
    fact_ride r
JOIN
    dim_customer c ON r.customer_sk = c.customer_sk
WHERE
    r.start_date_sk IN (
        SELECT date_sk FROM dim_date WHERE date BETWEEN '2023-01-01' AND '2023-12-31'
    )
GROUP BY
    c.name, c.email
ORDER BY
    ride_count DESC;

-- [S2] Als er een klant zijn abbo verloopt, wie maakt de grootste impact.


SELECT
    c.user_id, c.name, c.email,
    COUNT(r.ride_sk) AS usage_count
FROM
    fact_ride r
JOIN
    dim_customer c ON r.customer_sk = c.customer_sk
GROUP BY
      c.user_id, c.name, c.email
ORDER BY
    usage_count DESC
LIMIT 10;

select weather_sk, count(*)
from fact_ride
group by weather_sk;