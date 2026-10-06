import psycopg2
import datetime
from config import SERVER, DATABASE_OP, DATABASE_DWH, USERNAME, PASSWORD, PORT
import dwh_tools as dwh


def load_dim_customers():
    try:
        # Maak verbindingen met de databases
        conn_op = dwh.establish_connection(SERVER, DATABASE_OP, USERNAME, PASSWORD, PORT)
        conn_dwh = dwh.establish_connection(SERVER, DATABASE_DWH, USERNAME, PASSWORD, PORT)

        cursor_op = conn_op.cursor()
        cursor_dwh = conn_dwh.cursor()
        cursor_dwh.execute("TRUNCATE TABLE dim_customer CASCADE;")
        cursor_dwh.execute(
            """SELECT setval('customers_sk_seq',COALESCE((SELECT MAX(customer_sk) FROM dim_customer), 0) + 1,false)""")

        conn_dwh.commit()

        print("Start ophalen van klantgegevens...")

        # Query om alleen de meest recente subscriptions op te halen per klant
        select_query = """
        WITH recent_subscriptions AS (
            SELECT 
                vu.userid,
                vu.name,
                vu.email,
                vu.street,
                vu.number,
                vu.zipcode,
                vu.city,
                vu.country_code,
                st.description AS subscription_type,
                s.validfrom,
                ROW_NUMBER() OVER (PARTITION BY vu.userid ORDER BY s.validfrom DESC) AS row_num
            FROM velo_users vu
            LEFT JOIN subscriptions s ON vu.userid = s.userid
            LEFT JOIN subscription_types st ON s.subscriptiontypeid = st.subscriptiontypeid
            WHERE s.userid IS NOT NULL
        )
        SELECT *
        FROM recent_subscriptions
        WHERE row_num = 1
        ORDER BY userid; -- Zorg voor consistente volgorde
        """
        cursor_op.execute(select_query)

        # Verwerk brongegevens
        for row in cursor_op.fetchall():
            user_id, name, email, street, number, zipcode, city, country_code, subscription_type, validfrom, row_num = row

            print(f"Verwerken klant: {name} ({user_id})")

            # Controleer of de klant al bestaat in de dimensie
            cursor_dwh.execute("""
                SELECT customer_sk, name, email, street_number, street_name, zipcode, city, country_code, subscription_type, scd_version, scd_expiration_date
                FROM dim_customer
                WHERE user_id = %s AND scd_expiration_date = '9999-12-31';
            """, (user_id,))
            existing_record = cursor_dwh.fetchone()

            if existing_record:
                # Haal bestaande gegevens op
                (customer_sk, current_name, current_email, current_street_number, current_street_name,
                 current_zipcode, current_city, current_country_code, current_subscription_type,
                 scd_version, scd_expiration_date) = existing_record

                # Controleer op wijzigingen in adresgegevens of subscription type
                if (name != current_name or email != current_email or number != current_street_number or
                        street != current_street_name or zipcode != current_zipcode or city != current_city or
                        country_code != current_country_code or subscription_type != current_subscription_type):

                    print(f"Adresgegevens gewijzigd voor klant: {name} ({user_id})")

                    # Markeer het bestaande record als verlopen
                    cursor_dwh.execute("""
                        UPDATE dim_customer
                        SET scd_expiration_date = %s
                        WHERE customer_sk = %s;
                    """, (datetime.datetime.now().date(), customer_sk))

                    # Voeg een nieuwe versie van de klant toe met de gewijzigde gegevens
                    cursor_dwh.execute("""
                        INSERT INTO dim_customer (user_id, name, email, street_number, street_name, zipcode, city, 
                                                  country_code, subscription_type, scd_version, scd_start_date, scd_expiration_date)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, '9999-12-31');
                    """, (
                        user_id, name, email, number, street, zipcode, city, country_code, subscription_type,
                        scd_version + 1, datetime.datetime.now().date()
                    ))
                else:
                    print(f"Geen wijzigingen nodig voor klant: {name} ({user_id}).")
            else:
                # Voeg nieuwe klant toe als deze nog niet bestaat
                print(f"Nieuwe klant toevoegen: {name} ({user_id})")
                cursor_dwh.execute("""
                    INSERT INTO dim_customer (user_id, name, email, street_number, street_name, zipcode, city, 
                                              country_code, subscription_type, scd_version, scd_start_date, scd_expiration_date)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 1, %s, '9999-12-31');
                """, (
                    user_id, name, email, number, street, zipcode, city, country_code, subscription_type,
                    datetime.datetime.now().date()
                ))

            # Commit na elke klant
            conn_dwh.commit()

        print("Klantdimensie succesvol geladen!")

        # Sluit de verbindingen
        cursor_op.close()
        cursor_dwh.close()
        conn_op.close()
        conn_dwh.close()

    except Exception as e:
        print(f"Fout bij het laden van dim_customer: {e}")


if __name__ == "__main__":
    load_dim_customers()
    print("ETL-proces voltooid.")
