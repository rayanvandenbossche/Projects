import os
import json
import random
from datetime import datetime, timedelta
import psycopg2
from config import SERVER, DATABASE_OP, DATABASE_DWH, USERNAME, PASSWORD, PORT

# Map voor de JSON-bestanden
OUTPUT_FOLDER = "weather"
if not os.path.exists(OUTPUT_FOLDER):
    os.makedirs(OUTPUT_FOLDER)

def establish_connection():
    """Maakt een verbinding met de datawarehouse database."""
    try:
        conn = psycopg2.connect(
            host=SERVER,
            database=DATABASE_DWH,
            user=USERNAME,
            password=PASSWORD,
            port=PORT,
        )
        return conn
    except Exception as e:
        print(f"Fout bij het verbinden met de database: {e}")
        raise

def fetch_postcodes_from_dim_locks():
    """Haalt unieke postcodes op uit de dim_locks-tabel."""
    try:
        conn = establish_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT DISTINCT station_zipcode FROM dim_locks WHERE station_zipcode IS NOT NULL")
        postcodes = [row[0] for row in cursor.fetchall()]
        conn.close()
        return postcodes
    except Exception as e:
        print(f"Fout bij het ophalen van postcodes: {e}")
        return []

def generate_weather_data(postcode, base_time):
    """Genereert 3 JSON-bestanden met weersinformatie voor een postcode."""
    weather_types = [
        {"id": 501, "main": "Rain", "description": "moderate rain", "temp_k": 278.15, "type": "Onaangenaam"},
        {"id": 800, "main": "Clear", "description": "clear sky", "temp_k": 293.15, "type": "Aangenaam"},
        {"id": 802, "main": "Clouds", "description": "scattered clouds", "temp_k": 285.15, "type": "Neutraal"},
    ]

    weather_data = []
    for i in range(3):  # Genereer 3 variaties per postcode
        weather = random.choice(weather_types)  # Kies een willekeurig weertype
        timestamp = base_time + timedelta(hours=i)  # Varieer de tijd
        # Converteer temperaturen naar Celsius
        temp_c = round(weather["temp_k"] - 273.15, 2)
        feels_like_c = round(temp_c + random.uniform(-1, 1), 2)
        temp_min_c = round(temp_c - random.uniform(1, 3), 2)
        temp_max_c = round(temp_c + random.uniform(1, 3), 2)

        weather_json = {
            "zipCode": postcode,
            "coord": {"lon": round(random.uniform(4.0, 5.0), 2), "lat": round(random.uniform(50.0, 51.0), 2)},
            "weather": [{
                "id": weather["id"],
                "main": weather["main"],
                "description": weather["description"],
                "icon": "10d"
            }],
            "base": "stations",
            "main": {
                "temp": temp_c,
                "feels_like": feels_like_c,
                "temp_min": temp_min_c,
                "temp_max": temp_max_c,
                "pressure": random.randint(1000, 1020),
                "humidity": random.randint(60, 80)
            },
            "visibility": random.randint(8000, 10000),
            "wind": {"speed": round(random.uniform(1, 5), 2), "deg": random.randint(0, 360)},
            "clouds": {"all": random.randint(20, 100)},
            "dt": int(timestamp.timestamp()),
            "sys": {"type": 2, "id": random.randint(2000, 3000), "country": "BE",
                    "sunrise": int((timestamp - timedelta(hours=6)).timestamp()),
                    "sunset": int((timestamp + timedelta(hours=6)).timestamp())},
            "timezone": 3600,
            "id": random.randint(1000, 2000),
            "name": f"City {postcode}",
            "cod": 200
        }
        weather_data.append(weather_json)
    return weather_data

def generate_weather_responses(postcodes):
    """Genereert en slaat weergegevens op voor elke postcode."""
    if not postcodes:
        print("Geen postcodes om weergegevens voor te genereren.")
        return

    print(f"Start genereren van weergegevens voor postcodes: {postcodes}")
    base_time = datetime(2023, 12, 15, 12, 0, 0)  # Basisdatum en tijd
    for postcode in postcodes:
        try:
            weather_data = generate_weather_data(postcode, base_time)
            for idx, data in enumerate(weather_data):
                filename = f"{OUTPUT_FOLDER}/weather_{postcode}_{idx + 1}.json"
                with open(filename, "w") as json_file:
                    json.dump(data, json_file, indent=4)
                    print(f"Weergegevens opgeslagen in: {filename}")
        except Exception as e:
            print(f"Fout bij het genereren van weergegevens voor postcode {postcode}: {e}")

if __name__ == "__main__":
    # Haal de postcodes uit de dim_locks-tabel
    try:
        postcodes = fetch_postcodes_from_dim_locks()
        if postcodes:
            generate_weather_responses(postcodes)
            print("Weerdata succesvol gegenereerd en opgeslagen in de 'weather'-map.")
        else:
            print("Geen postcodes gevonden. Controleer of de dim_locks-tabel correct is gevuld.")
    except Exception as e:
        print(f"Onverwachte fout: {e}")


