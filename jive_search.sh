#!/bin/bash

function load_config {
  # Config file can set JIVE_ENDPOINT and JIVE_USER
  if [ -f ~/.jive ] ; then
    . ~/.jive
  fi

  if [ -z "$JIVE_ENDPOINT" ] ; then
    echo "No JIVE_ENDPOINT has been defined in ~/.jive"
    echo "Try running jive_config"
    exit 1
  fi
}

function set_login {
  if [ "$JIVE_USER" ] ; then
    USER_ID="$JIVE_USER"
  else
    local default_user=$USER
    if tty -s < /dev/tty ; then
      echo -n "Username [$default_user]: " > /dev/tty
      read username < /dev/tty
      if [ -z "$username" ]; then
        USER_ID="$default_user"
      else
        USER_ID="$username"
      fi
    else
      USER_ID="$default_user"
    fi
  fi
}

function set_password {
  if tty -s ; then
    read -s -p "Password: " USER_PW
    echo
  elif tty -s < /dev/tty ; then
    read -s -p "Password: " USER_PW > /dev/tty < /dev/tty
    echo > /dev/tty
  else
    echo "Need a TTY to get the password"
    exit 1
  fi
}

function do_jive_search {
    URL=$1
    BUF=$2
    curl -s -u "$USER_ID":"$USER_PW" "${URL}" > $BUF
}

function jive_search_by_subject {
  JIVE_SUBJECT="$1"
  COUNT=100
  SEARCH=$(echo $JIVE_SUBJECT | tr " " ",")
  BUF=`mktemp`

  echo "Searching for '$SEARCH'" >&2

  next="${JIVE_ENDPOINT}contents?count=${COUNT}&filter=search($SEARCH)"
  while [[ -n $next && "$next" != "null" ]] ; do
    do_jive_search "${next}" $BUF
    jq -r '.list[] | [.id, .subject, .published, .parentPlace.html] | @csv' $BUF

    echo "... getting next page ..." >&2
    next=$(jq -r '.links.next' $BUF)
  done
}

load_config
set_login
set_password

jive_search_by_subject "$@"
