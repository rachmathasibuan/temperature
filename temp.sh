#!/bin/bash

TOKEN="653700178:AAHFA9TpaCHTJPQqWcPMRcFngrLPcSvHdpM"
CHAT_ID="-964763910"
URL="https://api.telegram.org/bot${TOKEN}/sendMessage"

MYSQL_USER="leonor"
MYSQL_PASS="805@leonor"
MYSQL_HOST="10.157.0.164"
MYSQL_DB="temp"
MYSQL_PORT="33061"

DATE=$(date '+%Y-%m-%d %H:%M:%S')

SUHU=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -h"$MYSQL_HOST" \
  -P"$MYSQL_PORT" -D"$MYSQL_DB" -N -s \
  -e "SELECT temperature FROM data ORDER BY id DESC LIMIT 1;")

if [ -z "$SUHU" ]; then
  exit 0
fi

if awk "BEGIN {exit !($SUHU >= 25)}"; then
  curl -s -X POST "$URL" \
    -d chat_id="$CHAT_ID" \
    -d text="temp: $SUHU°C - date: $DATA"
fi
