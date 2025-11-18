import pandas as pd
from haversine import haversine

from src.utils.time import robust_hour_of_iso_date


def driver_distance_to_pickup(df: pd.DataFrame) -> pd.DataFrame:
    df["driver_distance"] = df.apply(
        lambda r: haversine(
            (r["driver_latitude"], r["driver_longitude"]),
            (r["pickup_latitude"], r["pickup_longitude"]),
        ),
        axis=1,
    )
    return df


def hour_of_day(df: pd.DataFrame) -> pd.DataFrame:
    df["event_hour"] = df["event_timestamp"].apply(robust_hour_of_iso_date)
    return df


def driver_historical_completed_bookings(df: pd.DataFrame) -> pd.DataFrame:
    """
    Creates a feature representing the historical number of accepted bookings for each driver.
    Drivers with better track records are more likely to accept bookings.
    
    This computes a cumulative count of accepted bookings per driver up to each timestamp,
    ensuring no data leakage by only counting past accepted bookings.
    
    NOTE: Sorting by event_timestamp as string works because ISO format naturally sorts correctly.
    """
    # Make a copy to avoid SettingWithCopyWarning
    df = df.copy()
    
    # Sort by driver and timestamp to ensure chronological order
    # ISO format timestamps sort correctly as strings (YYYY-MM-DD HH:MM:SS)
    df = df.sort_values(['driver_id', 'event_timestamp']).reset_index(drop=True)
    
    # Create a flag for accepted bookings
    df['is_accepted'] = (df['participant_status'] == 'ACCEPTED').astype(int)
    
    # Calculate cumulative accepted bookings per driver
    # Subtract current row to avoid data leakage (only count historical acceptances)
    df['driver_completed_bookings'] = (
        df.groupby('driver_id')['is_accepted'].cumsum() - df['is_accepted']
    )
    
    # Drop the temporary column
    df = df.drop('is_accepted', axis=1)
    
    return df
