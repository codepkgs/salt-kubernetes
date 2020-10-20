#!/bin/bash
# check nginx master process

nginx_count=$(ps aux | grep 'nginx: master' | grep -v grep | wc -l)

if [ "$nginx_count" -eq 1 ]; then
    exit 0
else
    exit 1
fi