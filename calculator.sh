#!/bin/bash
# calculator.sh — tiny Bash calculator used in the GitHub lesson

add() { echo $(($1 + $2)); }
sub() { echo $(($1 - $2)); }
mul() { echo $(($1 * $2)); }
div() {
  if [ "$2" -eq 0 ]; then
    echo "Error: division by zero"
    exit 1
  fi
  echo $(($1 / $2))
} 

case "$1" in
  add) add "$2" "$3" ;;
  sub) sub "$2" "$3" ;;
  mul) mul "$2" "$3" ;;
  div) div "$2" "$3" ;;
  *)
    echo "Usage: $0 {add|sub|mul|div} a b"
    exit 1
    ;;
esa
# calculator.sh - tiny Bash calculator used in the GitHub lesson
# # Updated by Vanessa for GitHub pull request practice 
change