#!/usr/bin/env bash

DST="data/raw/wfsmoke/wfsmoke.zip"
mkdir -p $(dirname $DST)
curl -Ls "https://www.dropbox.com/scl/fo/91k0aq80vp57qixkm508q/AOADXrl5470J9uGaxpkOniA/county?rlkey=nutebc9pn2vsupr0p9ks4k73u&subfolder_nav_tracking=1&st=6m7wqj6o&dl=1" -o $DST -z $DST
unzip -u -d $(dirname $DST) $DST
