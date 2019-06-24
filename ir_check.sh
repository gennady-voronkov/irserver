#!/bin/bash

_count=3
_delay=2
url=http://localhost:8888
health_log_file=/root/ir_health_check/health.log
reboot_log_file=/root/ir_health_check/reboot.log

ok_msg="Service is UP"
error_msg="Service is DOWN"
error_msg2="Restarting service"

FOREBEAR=/opt/iridiumserver/forebear.sh

check()
{
  curl $url -k -s -f -o /dev/null --connect-timeout 2 && echo 200 || echo "ERROR"
}

timestamp()
{
    date +"%Y-%m-%d %H:%M:%S"
}

write_log()
{
  echo "$(timestamp) $1 $2" >> $3
}

try()
{
  srvup=0
  srvdown=0
  for ((i=1; i<=$_count; i++))
  do
  status=$(check)
  if [[ $status -ne 200 ]]
    then
      srvdown=`expr $srvdown + 1`
    else
      srvup=`expr $srvup + 1`
  fi
  sleep $_delay

  done

  if [[ $srvdown -eq $_count ]]
    then
      echo "$error_msg http_code=$status"
      write_log "http_code=$status" "$error_msg" "$reboot_log_file"
      echo "$error_msg. Going to restart"
      echo "-=Stopping server"
      $FOREBEAR --stop
      sleep 2
      echo "-=Staring server"
      write_log "http_code=$status" "$error_msg2" "$reboot_log_file"
      $FOREBEAR --start
    elif [[ $srvup -eq $_count ]]
      then
        echo "$ok_msg http_code=$status"
        write_log "http_code=$status" "$ok_msg" "$health_log_file"
      else
        write_log "http_code=$status" "helth_count is not "$_count"" "$health_log_file"
  fi
}

try
sleep 24
try

exit

