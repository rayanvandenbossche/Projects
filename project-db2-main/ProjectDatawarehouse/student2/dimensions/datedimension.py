import pandas as pd
import psycopg2
import dwh_tools as dwh
from config import SERVER, DATABASE_OP, DATABASE_DWH, USERNAME, PASSWORD, PORT

def fetch_min_date(cursor_op, table_name, date_column):
    """
    Haalt de minimumdatum op uit een opgegeven tabel en kolom.
    Args:
        cursor_op: De cursor voor de 'op' database.
        table_name (str): De naam van de tabel in de operationele database.
        date_column (str): De naam van de kolom met datums.
    Returns:
        str: De minimumdatum.
    """
    query = f"SELECT MIN({date_column}) FROM {table_name}"
    cursor_op.execute(query)
    return cursor_op.fetchone()[0]


def fill_table_dim_date(cursor_dwh, start_date, end_date='2040-01-01', table_name='dim_date'):
    """
    Vult de 'dim_date' tabel met datumgerelateerde gegevens.
    Args:
        cursor_dwh: De cursor voor de 'dwh' database.
        start_date (str): De startdatum voor het vullen van de tabel.
        end_date (str): De einddatum voor het vullen van de tabel (standaard is '2040-01-01').
        table_name (str): De naam van de tabel (standaard is 'dim_date').
    """
    insert_query = f"""
    INSERT INTO {table_name} (date, day_of_month, month, year, day_of_week, weekday_name, month_name, quarter, is_weekend)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    current_date = pd.to_datetime(start_date)
    end_date = pd.to_datetime(end_date)

    while current_date <= end_date:
        day_of_month = current_date.day
        month = current_date.month
        year = current_date.year
        day_of_week = current_date.dayofweek + 1
        weekday_name = current_date.strftime('%A')
        month_name = current_date.strftime('%B')
        quarter = (current_date.month - 1) // 3 + 1  # Bepaal het kwartaal op basis van de maand
        is_weekend = day_of_week in [6, 7]  # Controleer of het zaterdag (6) of zondag (7) is

        # Voer de INSERT-query uit
        cursor_dwh.execute(insert_query, (
            current_date, day_of_month, month, year, day_of_week, weekday_name, month_name, quarter, is_weekend
        ))

        # Commit de transactie
        cursor_dwh.connection.commit()
        current_date += pd.Timedelta(days=1)

def main():
    try:
        # Verbind met de 'op' database
        conn_op = dwh.establish_connection(SERVER, DATABASE_OP, USERNAME, PASSWORD, PORT)
        cursor_op = conn_op.cursor()

        # Verbind met de 'dwh' database
        conn_dwh = dwh.establish_connection(SERVER, DATABASE_DWH, USERNAME, PASSWORD, PORT)
        cursor_dwh = conn_dwh.cursor()

        # Ophalen van de minimumdatum (pas tabel- en kolomnamen aan naar jouw situatie)
        table_name = "rides"  # Naam van de tabel in de operationele database
        date_column = "StartTime"  # Naam van de kolom met datums
        start_date = fetch_min_date(cursor_op, table_name, date_column)
        print(f"Minimumdatum: {start_date}")


        # Vul de 'dim_date' tabel
        fill_table_dim_date(cursor_dwh, start_date, '2100-01-01', 'dim_date')
        print("dim_date succesvol ingeladen. ")

        # Sluit de verbindingen
        cursor_op.close()
        conn_op.close()
        cursor_dwh.close()
        conn_dwh.close()

    except psycopg2.Error as e:
        print(f"Fout bij het verbinden met de database: {e}")
    except Exception as e:
        print(f"Onverwachte fout: {e}")

if __name__ == "__main__":
    main()