#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 --ultra | --small | --medium | --big | --mega"
  exit 1
fi

case "$1" in
  --ultra|--small|--medium|--big|--mega)
    ARGUMENT="${1#--}" # Remove the '--' prefix
    ;;
  *)
    echo "Invalid argument. Allowed: --ultra, --small, --medium, --big, --mega"
    exit 1
    ;;
esac

FILE="${ARGUMENT}.mzn"
if [ -f "$FILE" ]; then
  echo "File $FILE exists. Deleting it..."
  rm "$FILE"
else
  echo "File $FILE does not exist. Proceeding..."
fi

echo "Calling generador.lisp with argument '$ARGUMENT'..."

# En caso de error sacar /dev/null, no quiero pensar una mejor forma de hacerlo
sbcl --load generador.lisp --eval "(gen-instance '$ARGUMENT)" --eval "(quit)" > /dev/null 2>&1

# Despues de esto deberia existir el archivo ${ARGUMENT}.mzn, en caso de no existir algo salio mal
if [ ! -f "$FILE" ]; then
	echo "Something went wrong, $FILE does not exist after executing generador.lisp, aborting..."
	exit 1
fi

# WARNING WARNING WARNING
# Editamos modelo.mzn para usar la nueva instancia, esto es muy hacky, probablemente hay una mejor forma de hacerlo,
# minizinc acepta argumentos? probablemente si pero no quiero pensar. Me voy a arrepentir de esto

echo "Changing include in model.mzn"
sed -i "3s|include \"./.*.mzn\";|include \"./$ARGUMENT.mzn\";|" modelo.mzn

# Llamamos a minizinc para resolver el modelo
echo -n "Solving model..."
inicio=$(date +%s.%N)
minizinc --solver HiGHS modelo.mzn -o output.txt
fin=$(date +%s.%N)
runtime=$(echo "$fin - $inicio" | bc)
echo "FINISHED in $runtime seconds"
echo "Editing output.txt"
sed -i '$d' output.txt
sed -i '$d' output.txt
echo -n "Generating graph..."
python3 graph_maker.py
echo "Finished, output.png was created"
