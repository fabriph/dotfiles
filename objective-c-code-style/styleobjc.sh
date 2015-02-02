#!/bin/bash
# Simple code syntax for Objective C.
# Fabricio PH  http://fabricioph.com

# TODO: use with precaution, this script might edit character inside strings.
# sed -i '' "s,,,g" $TMP_FILE

# TODO: accept many files as parameters
# TODO: show help if non entries, or if -h or --help
# TODO: default is not inplace, unles -i
# TODO: option -d --diff to show differences with original file


function checkstyle {
  ORIGINAL_FILE="$1"
  TMP_FILE='./temp.syntax-style'
  cat $ORIGINAL_FILE > $TMP_FILE

  ## GENERAL
  # TODO: this can be better done by analyzing different scenarios.
  # Removing spaces around ':'
  sed -i '' "s,\([^ 	]\)[ 	]*:,\1:,g" $TMP_FILE
  sed -i '' "s,:[ 	]*,:,g" $TMP_FILE


  ## OPERANDS
  # Spaces around '=' and '=='
  sed -i '' "s;\([^ 	]\)[ 	]*\([=]\{1,\}\)[ 	]*\([^ 	]\);\1 \2 \3;g" $TMP_FILE


  ## POINTERS
  # Removes right spaces.
  sed -i '' "s-\*[ 	]*-\*-" $TMP_FILE
  # Normalizes left spaces.
  sed -i '' "s-\([^(][^ 	]*\)[ 	]*\*\([^)]\)-\1 \*\2-" $TMP_FILE


  ## METHOD DECLARATION
  # Normalizes spaces in method return type: '   -   (void)    method' -> '- (void)method'
  sed -i '' "s,^[ 	]*-[ 	]*(\([^)]*\))[ 	]*,- (\1)," $TMP_FILE
  # Normalize spaces after colon in method signature
  sed -i '' "s,\(^[ 	]*-.*\)[ 	]*:[ 	]*\(.*[ 	]*{\),\1:\2,g" $TMP_FILE
  # Normalize spaces after closing parentesis for parameter tipe: "call:(type) var" -> "call:(type)var"
  sed -i '' "s,\(^[ 	]*-.*:[ 	]*([^)]*)\)[ 	]*\(.*[ 	]*{\),\1\2,g" $TMP_FILE
  # Exactly one space before opening { on method declaration
  sed -i '' "s,\(^[ 	]*-.*[^ 	]\)[ 	]*{,\1 {," $TMP_FILE


  ## METHOD CALLING
  # Removing spaces after [ and before ]
  sed -i '' "s,^\([ 	]*\[\)[ 	]*\([^ 	].*[^ 	]\)[ 	]*\\(].*\)$,\1\2\3,g" $TMP_FILE
  # Removing double spacing
  sed -i '' "s;^\(.*\[.*\)[ 	]\{2,\};\1 ;g" $TMP_FILE
  sed -i '' "s;^\([ 	]*[^ 	].*\)[ 	]\{2,\};\1 ;g" $TMP_FILE


  ## REVERTS (Putting spaces back when suitable)
  # Ternary operand like 'condition ? positive : negative'
  sed -i '' "s,\([^ 	]\)[ 	]*\?[ 	]*\(.*\)[ 	]*:[ 	]*\(.*\)$,\1 ? \2 : \3,g" $TMP_FILE
  # Enums like: 'typedef enum : Type {'
  sed -i '' "s;^\([ 	]*\)typedef[ 	]\{1,\}enum[ 	]*:[ 	]*\([^ 	]*\)[ 	]*{$;\1typedef enum : \2 {;" $TMP_FILE

  if [ "$SHOW_DIFF" = "true" ]; then
    echo "TODO showdiff"
    #git diff $ORIGINAL_FILE $TMP_FILE
  else
    cat "$TMP_FILE"
  fi

  if [ "$INPLACE" = "true" ]; then
    mv "$TMP_FILE" "$ORIGINAL_FILE"
  else
    rm "$TMP_FILE"
  fi
}


function main {
  checkstyle "$1"
}


SHOW_DIFF="false"
INPLACE="false"
while getopts ":e:dhi" opt; do
  case $opt in
    e)
      echo "-a was triggered, Parameter: $OPTARG" >&2
      ;;
    d)
      SHOW_DIFF="true"
      ;;
    h)
      echo -e "-d: shows diff instead of full output\n-h: help\n-i: inplace\n"
      exit 0
      ;;
    i)
      INPLACE="true"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

argstart=$OPTIND
for p in "${@:$argstart}"
  do
    main "$p" "$SHOW_DIFF"
  done

