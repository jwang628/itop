#!/bin/bash
#James Q Wang 2/4/19
h=127.0.0.1
P=3306
q="show databases"
db=

vvv=
if [[ "vvv" == "$3" ]]; then vvv="-vvv"; fi

cmd="mysql --defaults-file=$HOME/itop/.my.cnf_mon -t -A $vvv"

function checksqlfile () {
    file=$1
    safe=$(head -n 3 "$file"|egrep -i "^#|^[ ]*explain|^[ ]*show|^[ (]*select|^[ ]*SET STATEMENT max_statement_time")
    analyze=$(head -n 3 "$file"|egrep -i "^[ ]*analyze format|^[ ]*explain format")
    if [[ -n "$analyze" ]]; then
        echo $cmd
        exit
    fi
    if [[ -z "$safe" ]] || [[ -n "$(find $file -size +32k)" ]]; then
        read -p "r u sure to run file $file? y/N"
        if [[ "y" == "$REPLY" ]]; then
            $cmd < $file
        else
            echo "nice stay safe"
            exit
        fi
    fi
}

if   [[ -f "$1" ]]; then
    checksqlfile "$1"
    if [[ -z "$2" ]]; then
        $cmd < $1
    else
        $cmd < $1 |egrep "^\|"|awk -F'|' '{if (NF<=3) print $2; else print $3"\t"$4"\t"$5"\t"$7"\t"$8"\t"$10"\t"$11}'
    fi
elif [[ -d "$1" ]]; then
    #if a fold, query sql file 1 by 1
    for file in $(ls -t -r $1/*); do
        read -p "run file $file (hit enter to continue)"
        echo "explain $file"
        checksqlfile "$file"
        if [[ -z "$2" ]]; then
            $cmd < $file
        else
            $cmd < $file|egrep "^\|"|awk -F'|' '{if (NF<=3) print $2; else print $3"\t"$4"\t"$5"\t"$7"\t"$8"\t"$10"\t"$11}'
        fi
    done
elif [[ -n "$1" ]]; then
    danger=$(echo $1|egrep -i "update |delete |insert |optimize |analyze |flush |create |drop |truncate ")
    safe=$(echo $1|egrep -i "^[ ]*select |^[ ]*show |^[ ]*explain |^[ ]*desc |^[ ]*set |^[ ]*status ")
    if [[ -z "$danger" ]] && [[ -n "$safe" ]]; then
        $cmd -e "$1"
    else
        read -p "r u sure to run $1? y/N"
        if [[ "y" == "$REPLY" ]]; then
            $cmd -e "$1"
        else
            echo "nice stay safe"
            exit
        fi
    fi
else
    $cmd -e "$q"
    echo "please query or file"
fi
