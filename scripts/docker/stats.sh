#!/bin/bash

# Credit: https://zwbetz.com/how-to-show-docker-memory-usage/

mem_amount_total_with_unit=$(docker system info 2>/dev/null |
  grep 'Total Memory: ' |
  tr -d 'Total Memory: ')

unit=$(echo ${mem_amount_total_with_unit} |
  sed 's/[0-9\.]*//g')

mem_amount_total=$(echo ${mem_amount_total_with_unit} |
  sed 's/[^0-9\.]*//g')

mem_percent_used=$(docker stats --no-stream --format '{{.MemPerc}}' 2>/dev/null |
  tr -d '%' |
  paste -s -d '+' - |
  bc)

mem_percent_used=${mem_percent_used:-0}

if [[ -z "$mem_amount_total_with_unit" || -z "$unit" || -z "$mem_amount_total" || -z "$mem_percent_used" ]]; then
  echo "Docker doesn't seem to be running."
  exit 1
fi

mem_amount_used=$(echo "scale=2; ${mem_amount_total} * ${mem_percent_used} / 100" 2>/dev/null |
  bc 2>/dev/null)

echo "Memory Amount Total: ${mem_amount_total}${unit}"
echo "Memory Amount Used: ${mem_amount_used}${unit}"
echo "Memory Percent Used: ${mem_percent_used}%"
