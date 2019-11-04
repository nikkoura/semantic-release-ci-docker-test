#!/usr/bin/env bash

function semverParser() {
    local REGEXP='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z_-]*\)'
    eval $2=`echo $1 | sed -e "s#$REGEXP#\1#"`
    eval $3=`echo $1 | sed -e "s#$REGEXP#\2#"`
    eval $4=`echo $1 | sed -e "s#$REGEXP#\3#"`
    eval $5=`echo $1 | sed -e "s#$REGEXP#\4#"`
}
