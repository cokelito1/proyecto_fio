#!/bin/bash

# Check if at least one argument is passed
if [ $# -ne 1 ]; then
  echo "Usage: $0 --ultra | --small | --medium | --big | --mega"
  exit 1
fi

# Extract the argument without the '--' prefix
case "$1" in
  --ultra|--small|--medium|--big|--mega)
    ARGUMENT="${1#--}" # Remove the '--' prefix
    ;;
  *)
    echo "Invalid argument. Allowed: --ultra, --small, --medium, --big, --mega"
    exit 1
    ;;
esac

# Check if the file exists
FILE="${ARGUMENT}.mzn"
if [ -f "$FILE" ]; then
  echo "File $FILE exists. Deleting it..."
  rm "$FILE"
else
  echo "File $FILE does not exist. Proceeding..."
fi

# Call generador.lisp with sbcl and run the (gen-instance 'argument) function
echo "Calling generador.lisp with argument '$ARGUMENT'..."
sbcl --load generador.lisp --eval "(gen-instance '$ARGUMENT)" --eval "(quit)"
