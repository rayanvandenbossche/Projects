import psycopg2

try:
    # Verbinden met de PostgreSQL-database
    conn = psycopg2.connect(
        dbname="dtbbase",
        user="postgres",
        password="admin123",
        host="localhost",  # Of je serveradres
        port="5433"  # Standaard PostgreSQL-poort
    )

    # Cursor aanmaken
    cursor = conn.cursor()

    # SQL-query uitvoeren
    cursor.execute("SELECT * FROM sales")
    rows = cursor.fetchall()

    # Resultaten printen
    for row in rows:
        print(row)

    # Verbinding sluiten
    cursor.close()
    conn.close()

except psycopg2.Error as e:
    print(f"Fout bij verbinden met de database: {e}")
