#%%
import myfitnesspal as mfp
from datetime import datetime, timedelta
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

#%%
# Set up user and days difference for date range
client = mfp.Client("calrkarnold")
day_delta = timedelta(1)
yesterday = datetime.today().date() - day_delta

#%%
"""
Check if a file exists for the food summary. If it does, load the data and set
the start date to the last date in the file + 1 day, otherwise start at the
beginning of 2015.
"""
try:
    food_summary = pq.read_table("mfp_food-summary.parquet").to_pandas()
    start_date = food_summary["date"].max() + day_delta

except EnvironmentError:
    start_date = datetime(2015, 1, 1)
    food_summary = pd.DataFrame()

#%%
def download_food_summary_dataframe(start_date: datetime, end_date: datetime):
    """If most recent date in the file is not yesterday, download the data and
    append"""
    
    if (end_date == start_date) | (end_date + day_delta  == start_date):
        return("No new data to download")
    elif end_date < start_date:
        return("Error: end date is before start date")
    else:
        # Create the date range
        date_range = pd.date_range(start_date, end_date)

        # Loop through date range and append the food summary from MFP to a new list
        new_food_summary = []
        for day in date_range:
            mfp_day = client.get_date(day)

            new_food_summary.append(
                {
                    "date": day,
                    "totals": mfp_day.totals
                }
            )

        # Turn new food summary data into a wide dataframe and remove dictionary column
        new_food_summary_df = pd.DataFrame.from_dict(new_food_summary)
        new_food_totals = pd.json_normalize(new_food_summary_df['totals'])
        new_food_summary_clean = pd.concat(
            [new_food_summary_df.drop("totals", axis = 1), new_food_totals],
            axis = 1
        )
        return new_food_summary_clean

#%%
new_food_summary_clean = download_food_summary_dataframe(start_date, yesterday)

#%%
def update_food_summary_dataframe(old_data: pd.DataFrame, new_data: pd.DataFrame):
    """If there is new data, append it to the old data, otherwise return the old data"""
    if isinstance(new_data, pd.DataFrame):
        updated_food_summary = pd.concat(
            [food_summary, new_food_summary_clean],
            axis=0, ignore_index=True
            )
        
        return updated_food_summary
    else:
        return old_data

#%%
updated_food_summary = update_food_summary_dataframe(food_summary, new_food_summary_clean)

#%%
# Write the updated data to a parquet file
pq.write_table(
    pa.Table.from_pandas(updated_food_summary),
    "mfp_food-summary.parquet"
    )
# %%
