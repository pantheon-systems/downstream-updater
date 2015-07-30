#!/bin/bash

#
# Print a message if we are in VERBOSE mode
#
# Usage:
#
#    verbose_message "This is a message"
#
function verbose_message() {
  if $VERBOSE
  then
    echo "$1"
  fi
}

#
# Exit with a message if the previous function returned an error.
#
# Usage:
#
#   aborterr "Description of what went wrong"
#
function aborterr() {
  if [ $? != 0 ]
  then
    echo "$1" >&2
    exit 1
  fi
}

#
# Given a function parameter value containing flags, return a parsed
# argument string that can be passed in to curl to specify boolean
# argument values.
#
# Parameters:
#
#    ALL:     All of the available flags
#
#    TEST:    The function parameter value.  Contains 'flag' to
#             specify "flag": "true", or '!flag' to specify
#             "flag": "false".
#
# Usage:
#
#    parse_function_flags 'a b c d e f g' 'a !c f'
#
function parse_function_flags() {
  ALL="$(echo $1 | tr ',' ' ')"
  TEST=" $(echo $1 | tr ',' ' ') "

  for flag in $ALL
  do
    # Test to see if $TEST contains $flag by replacing " $flag " with
    # an empty string.  If the result is different than the unmodified
    # variable, then $TEST contains $flag.
    if [ "x${TEST/ $flag /}" == "x$TEST" ]
    then
      echo -n ", \"$flag\":\"true\""
    fi
    # Also check for !$flag, meaning "FALSE"
    flag='!'$flag
    if [ "x${TEST/ $flag /}" == "x$TEST" ]
    then
      echo -n ", \"$flag\":\"false\""
    fi
  done
}

#
# Check the result of the last operation, and either print progress or call aborterr
#
# Usage:
#
#   check "Something the script did" "Message to display if it did not work"
#
function check() {
  aborterr "$2"
  echo "$1"
}

#
# URL-encode a string
#
# Usage:
#
#    ENCODED=$(urlencode $DATA)
#
function urlencode() {
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
      local c="${1:i:1}"
      case $c in
          [a-zA-Z0-9.~_-]) printf "$c" ;;
          ' ') printf "+" ;;
          *) printf '%%%02X' "'$c"
      esac
  done
}
