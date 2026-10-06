import psycopg2
from config import SERVER, DATABASE_OP, DATABASE_DWH, USERNAME, PASSWORD, PORT
import dwh_tools as dwh



def load_dim_locks(source_cursor, target_cursor, target_conn):
    try:
        target_cursor.execute("TRUNCATE TABLE dim_locks CASCADE;")
        target_conn.commit()

        # Haal gegevens uit de bron `locks` en `stations` tabellen
        source_cursor.execute("""
            SELECT 
                l.lockid, l.stationid, s.type, s.street, s.number, s.zipcode, s.district, s.gpscoord
            FROM locks l
            JOIN stations s ON l.stationid = s.stationid
        """)
        locks = source_cursor.fetchall()

        # Controleer de opgehaalde rijen om er zeker van te zijn dat ze het juiste formaat hebben
        for lock in locks:
            # Debug: print de tuple om te zien welke gegevens we ophalen
            print(f"Lock data: {lock}")

            # Zorg ervoor dat alle velden aanwezig zijn in de tuple
            if len(lock) == 8:  # Zorg ervoor dat er precies 8 velden zijn (voor lockid, stationid, type, etc.)
                target_cursor.execute("""
                    INSERT INTO dim_locks (lockid, stationid, stationtype, station_straat, station_numeric, station_zipcode, station_district, station_coordinations)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, lock)
            else:
                print(f"Onverwachte gegevensstructuur voor lock: {lock}")

        target_conn.commit()
        print("dim_locks succesvol geladen.")

    except Exception as e:
        print(f"Fout bij het laden van dim_locks: {e}")
        target_conn.rollback()


def load_dim_locks_default(cursor_dwh, conn_dwh):
    print("Loading default row")

    cursor_dwh.execute(""" INSERT INTO dim_locks (lockid, stationid, stationtype, station_straat, station_numeric, station_zipcode, station_district, station_coordinations)
                    VALUES (0, null, null, null, null, null, null, null)""")
    conn_dwh.commit()

def main():
    # Connect to the 'VeloDB' database
    conn_op = dwh.establish_connection(SERVER, DATABASE_OP, USERNAME, PASSWORD, PORT)
    cursor_op = conn_op.cursor()

    # Connect to the 'DWH-DB2-project' database
    conn_dwh = dwh.establish_connection(SERVER, DATABASE_DWH, USERNAME, PASSWORD, PORT)
    cursor_dwh = conn_dwh.cursor()

    load_dim_locks_default(cursor_dwh, conn_dwh)

    load_dim_locks(cursor_op, cursor_dwh, conn_dwh)

    # Close the connections
    cursor_op.close()
    conn_op.close()
    cursor_dwh.close()
    conn_dwh.close()


print("ETL-proces voltooid.")

if __name__ == "__main__":
    main()