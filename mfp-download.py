import myfitnesspal as mfp
import csv, sys, os
import keyring
from datetime import datetime
import pandas as pd

mfp_username = keyring.get_password("mfp", "mfp_username")
client = mfp.Client(mfp_username)

start_date = datetime(2015, 1, 1)
today = datetime.today().date()
date_range = pd.date_range(start_date, today)

day_num = 1
food_diary = []

for day in pd.date_range(datetime(2018, 7, 20), datetime(2018, 7, 30)):
    mfp_day = client.get_date(day)

    food_diary.append(
        {
            "Date": day,
            "Totals": mfp_day.totals
        }
    )

df = pd.DataFrame.from_dict(food_diary)
df = pd.concat([df, df["Totals"].apply(pd.Series)], axis=1)