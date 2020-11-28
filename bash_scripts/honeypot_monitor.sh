#!/bin/bash

pgrep -x python3
if [ $? -gt 0 ]
then
  echo "Honeypod not running"
  service ssh restart
fi