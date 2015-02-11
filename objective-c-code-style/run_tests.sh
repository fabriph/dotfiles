#!/bin/bash
TMP_OUTPUT="test.styleobjc.tmp"

runWithFile () {
  echo -e "\n$1\n"
  ./styleobjc.sh -a "./test/$1" > $TMP_OUTPUT
  command -v colordiff >/dev/null 2>&1
  if [[ "$?" -eq 0 ]]; then
    colordiff $TMP_OUTPUT "./test/expected-$1" 2>/dev/null
  else
    git diff $ORIGINAL_FILE $TMP_FILE
  fi
  rm "$TMP_OUTPUT"
}

runWithFile "colon-spacing.txt"
runWithFile "bool-operands.txt"
runWithFile "method-signature.txt"
runWithFile "pointers.txt"
runWithFile "general-code.txt"

