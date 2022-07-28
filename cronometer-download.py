#!/Users/cfa5228/.pyenv/versions/personal-health/bin/python

"""
Have set the password and usernname using keyring.set_password(). For the
username, we used the fake username 'garminexport_username' so we could
abuse keyring and store the username as a password.
"""
#%%
import keyring
import subprocess
from datetime import datetime, timedelta

#%%
username = keyring.get_password("cronometer", "cronometer_username")
password = keyring.get_password("cronometer", username)
today = datetime.today().date()

#%%
nutrition_start_date = datetime(2021, 5, 1).date()
nutrition_day_delta_timedelta = today - nutrition_start_date
nutrition_day_delta = str(nutrition_day_delta_timedelta.days)

#%%
exercise_biometric_start_date = datetime(2016, 1, 1).date()
exercise_biometric_day_delta_timedelta = today - exercise_biometric_start_date
exercise_biometric_day_delta = str(exercise_biometric_day_delta_timedelta.days)


#%%
subprocess.call(["zsh", "cronometer-download.sh", username, password, nutrition_day_delta, exercise_biometric_day_delta])
# %%
