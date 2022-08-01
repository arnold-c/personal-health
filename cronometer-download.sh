#!/bin/zsh

./cronometer-export -s -$3d -e 0d -t daily-nutrition -u $1 -p $2 -o data/Cronometer/cron_daily-nutrition.csv

./cronometer-export -s -$4d -e 0d -t exercises -u $1 -p $2 -o data/Cronometer/cron_exercises.csv

./cronometer-export -s -$4d -e 0d -t biometrics -u $1 -p $2 -o data/Cronometer/cron_biometrics.csv