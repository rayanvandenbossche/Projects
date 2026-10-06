import pandas as pd

def create_weather_dimension():
    """
    Creates a static weather dimension.

    Returns:
        DataFrame: DataFrame containing the weather dimension.
    """
    weather_types = [
        {"weather_id": 1, "weather_type": "onaangenaam", "description": "Rain or precipitation"},
        {"weather_id": 2, "weather_type": "aangenaam", "description": "Sunny and warm (Temp > 15Â°C)"},
        {"weather_id": 3, "weather_type": "neutraal", "description": "Other conditions"},
        {"weather_id": 4, "weather_type": "onbekend", "description": "Unknown weather conditions"}
    ]
    return pd.DataFrame(weather_types)

# Example usage
df_weather_dim = create_weather_dimension()