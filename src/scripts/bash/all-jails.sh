#!/bin/bash

JAILS=$(fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g')
INDEX=1
for JAIL in $JAILS
do
  echo ""
  echo -n "${INDEX}) "
  fail2ban-client status $JAIL
  ((INDEX++))
done
