#!/bin/bash
set -euv

rm -rf functions/*/function

for subdir in functions/*/ ; do
    mkdir "$subdir"function/
    cp "$subdir"src/*.py  "$subdir"/function/
done
