import pandas as pd
from datetime import datetime, timedelta


def create_date_dimension(start_date, end_date):
    """
    Creates a date dimension from start_date to end_date.

    Args:
        start_date (str): Start date in 'YYYY-MM-DD' format.
        end_date (str): End date in 'YYYY-MM-DD' format.

    Returns:
        DataFrame: DataFrame containing the date dimension.
    """
    start = datetime.strptime(start_date, '%Y-%m-%d')
    end = datetime.strptime(end_date, '%Y-%m-%d')
    dates = []

    current_date = start
    while current_date <= end:
        dates.append({
            "date": current_date,
            "day_of_month": current_date.day,
            "month": current_date.month,
            "year": current_date.year,
            "day_of_week": current_date.weekday(),
            "day_of_year": current_date.timetuple().tm_yday,
            "weekday": current_date.strftime('%A'),
            "month_name": current_date.strftime('%B'),
            "quarter": (current_date.month - 1) // 3 + 1
        })
        current_date += timedelta(days=1)

    return pd.DataFrame(dates)


# Example usage
df_date_dim = create_date_dimension('2023-01-01', '2030-01-01')