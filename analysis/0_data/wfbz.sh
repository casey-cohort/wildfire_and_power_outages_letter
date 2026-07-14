#!/usr/bin/env bash

DST="data/raw/wfbz/wfbz.geojson"
mkdir -p $(dirname $DST)
curl -Ls https://media.githubusercontent.com/media/lpiep/wfbz_disasters_lite/refs/heads/main/wfbz.geojson -o "$DST" -z "$DST"
