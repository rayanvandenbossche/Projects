# IMPORTS
import os
import json
import pandas as pd
import psycopg2
from sqlalchemy import create_engine
from datetime import datetime

# CONFIGURATIE EN CONSTANTEN
WEATHER_FOLDER = "weather"  # Folder met opgeslagen JSON-bestanden
SERVER = "localhost"
DATABASE_OP = "velodbse"
DATABASE_DWH = "datawarehouse"
USERNAME = "postgres"
PASSWORD = "admin123"
PORT = "5433"

# FUNCTIES

def load_weather_data():
    """
    Laadt JSON-bestanden in een dictionary voor weersinformatie.
    """
    weather_data = {}
    for filename in os.listdir(WEATHER_FOLDER):
        if filename.endswith(".json"):
            with open(os.path.join(WEATHER_FOLDER, filename), "r") as file:
                data = json.load(file)
                zip_code = data.get("zipCode")
                timestamp = data.get("dt")
                weather_main = data.get("weather", [{}])[0].get("main", "Onbekend")

                if zip_code not in weather_data:
                    weather_data[zip_code] = []
                weather_data[zip_code].append((timestamp, weather_main))
    for zip_code in weather_data:
        weather_data[zip_code].sort(key=lambda x: x[0])
    return weather_data

def find_weather_sk(weather_data, zipcode, start_timestamp, cursor_dwh):
    """Zoekt de juiste weather_sk op basis van postcode en timestamp."""
    weather_sk = 4  # Default "Onbekend"
    if str(zipcode) in weather_data:
        closest_weather = None
        for timestamp, weather_main in weather_data[str(zipcode)]:
            if timestamp <= start_timestamp.timestamp():
                closest_weather = weather_main
            else:
                break
        if closest_weather:
            cursor_dwh.execute("""
                SELECT weather_sk FROM dim_weather WHERE weather_type = %s;
            """, (closest_weather,))
            result = cursor_dwh.fetchone()
            if result:
                weather_sk = result[0]
    return weather_sk

def calculate_distance(start_coords, end_coords):
    """
    Bereken de afstand tussen twee coördinaten met de haversine-formule.
    """
    from math import radians, sin, cos, sqrt, atan2
    R = 6371  # Radius van de aarde in kilometers

    if not start_coords or not end_coords:
        return 0

    lat1, lon1 = map(float, start_coords.strip('()').split(','))
    lat2, lon2 = map(float, end_coords.strip('()').split(','))


    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat / 2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return round(R * c, 3)

def load_fact_rides():
    try:
        # CONNECTIES NAAR DATABANKEN
        engine_op = create_engine(f"postgresql://{USERNAME}:{PASSWORD}@{SERVER}:{PORT}/{DATABASE_OP}")
        engine_dwh = create_engine(f"postgresql://{USERNAME}:{PASSWORD}@{SERVER}:{PORT}/{DATABASE_DWH}")

        print("Haal alle rides op...")
        rides_query = """
            SELECT r.rideId, r.StartTime, r.EndTime, r.Startlockid, r.Endlockid, r.SubscriptionId, s.userid
            FROM rides r
            JOIN subscriptions s ON r.SubscriptionId = s.subscriptionid;
        """
        rides_df = pd.read_sql_query(rides_query, engine_op)

        print("Data succesvol opgehaald. Start verwerking...")

        # Laad aanvullende dimensies
        locks_df = pd.read_sql_query("SELECT lockid, lock_sk, station_zipcode, station_coordinations FROM dim_locks;", engine_dwh)
        dates_df = pd.read_sql_query("SELECT date, date_sk FROM dim_date;", engine_dwh)
        customers_df = pd.read_sql_query("SELECT user_id, customer_sk FROM dim_customer WHERE scd_expiration_date = '9999-12-31';", engine_dwh)

        # Mappen voor snelle lookup
        lock_sk_map = locks_df.set_index("lockid")["lock_sk"].to_dict()
        lock_coords_map = locks_df.set_index("lockid")["station_coordinations"].to_dict()
        date_sk_map = dates_df.set_index("date")["date_sk"].to_dict()
        customer_sk_map = customers_df.set_index("user_id")["customer_sk"].to_dict()

        # Laad weerdata
        weather_data = load_weather_data()

        # Resultaten voorbereiden
        fact_rides = []

        for _, row in rides_df.iterrows():
            ride_id = row["rideid"]
            start_time = row["starttime"]
            end_time = row["endtime"]
            start_lockid = row["startlockid"]
            end_lockid = row["endlockid"]
            user_id = row["userid"]

            # Customer SK ophalen
            customer_sk = customer_sk_map.get(user_id, 0)

            # Lock SK ophalen
            start_lock_sk = lock_sk_map.get(start_lockid, 0)
            end_lock_sk = lock_sk_map.get(end_lockid, 0)

            # Date SK ophalen
            start_date_sk = date_sk_map.get(start_time.date(), 0)
            end_date_sk = date_sk_map.get(end_time.date(), 0)

            if start_date_sk == 0 or end_date_sk == 0:
                print(f"Date_SK ontbreekt voor ride_id {ride_id}. Record overgeslagen.")
                continue

            # Weather SK ophalen
            start_zipcode = locks_df.loc[locks_df["lockid"] == start_lockid, "station_zipcode"].values
            start_zipcode = str(start_zipcode[0]) if len(start_zipcode) > 0 else "0"
            weather_sk = find_weather_sk(weather_data, start_zipcode, start_time, engine_dwh)

            # Distance berekenen
            start_coords = lock_coords_map.get(start_lockid)
            end_coords = lock_coords_map.get(end_lockid)
            distance_km = calculate_distance(start_coords, end_coords)

            # Duur berekenen
            duration_minutes = round((end_time - start_time).total_seconds() / 60, 2)

            # Voeg record toe
            fact_rides.append((
                customer_sk, start_lock_sk, end_lock_sk, start_date_sk, end_date_sk,
                weather_sk, duration_minutes, distance_km
            ))

        # Inladen in fact_ride tabel
        fact_rides_df = pd.DataFrame(fact_rides, columns=[
            "customer_sk", "lock_sk_start", "lock_sk_end", "start_date_sk",
            "end_date_sk", "weather_sk", "duration_minutes", "distance_km"
        ])
        fact_rides_df.to_sql("fact_ride", engine_dwh, if_exists="append", index=False)
        print("Fact table succesvol geladen!")

    except Exception as e:
        print(f"Error during ETL process: {e}")

# SCRIPT UITVOEREN
if __name__ == "__main__":
    load_fact_rides()
