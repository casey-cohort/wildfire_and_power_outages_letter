#!/usr/bin/env bash

DST="data/raw/wfsmoke/wfsmoke.rds"
mkdir -p $(dirname $DST)
curl -Ls "https://www.dropbox.com/scl/fi/icblxmhbplhfql89bonmt/tigris_counties_smokePM_predictions_yearly_weighted_20060101-20241231.rds?rlkey=jxgdkubnr6smkf57or2mkytvp&st=y25j2nmw&e=1&dl=1" -o $DST -z $DST
