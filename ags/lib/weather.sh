#!/bin/bash

LOCATION="Great+Falls,VA"

icon=$(omarchy-weather-icon 2>/dev/null)
weather=$(curl -fsS --max-time 4 "https://wttr.in/${LOCATION}?format=%l|%t|%w" 2>/dev/null | tr -d '\n')

if [[ -z $weather ]]; then
  echo "Weather unavailable"
  exit 1
fi

IFS='|' read -r place temperature wind <<< "$weather"
place=${place%%,*}
temperature=${temperature#+}

echo "$icon    $place  ·  Temp $temperature  ·  Wind $wind"
