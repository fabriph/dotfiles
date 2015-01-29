#!/bin/bash
TMP_OUTPUT="test.styleobjc.tmp"

runWithFile () {
  echo -e "\n$1\n"
  ./styleobjc.sh "./test/$1" > $TMP_OUTPUT
  diff $TMP_OUTPUT "./test/expected-$1"
}

runWithFile "colon-spacing.txt"
runWithFile "math-operands.txt"
runWithFile "method-signature.txt"
runWithFile "pointers.txt"

