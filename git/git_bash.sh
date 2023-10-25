#!/bin/bash

echo "NOTE the first arg is a string which can contain "_" "

git pull
git add . 
git commit  -m $1 
git push 

echo "git push ok!"
