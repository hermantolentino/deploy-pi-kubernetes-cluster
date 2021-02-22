#!/usr/bin/env bash

for initfile in $(cat initfiles); do
  rm $initfile && echo "$initfile removed"
done
:> $(pwd)/initfiles
