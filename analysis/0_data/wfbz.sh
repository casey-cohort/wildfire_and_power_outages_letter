#!/usr/bin/env bash

DST="data/raw/wfbz/wfbz.geojson"
mkdir -p $(dirname $DST)
curl -Ls https://github.com/lpiep/wfbz_disasters_lite/blob/main/wfbz.geojson -o "$DST" -z "$DST"
