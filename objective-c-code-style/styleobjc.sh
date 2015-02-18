#!/bin/bash

# Simple code syntax for Objective C.
# Run 'styleobc -h' for help

# TODO: use with precaution, this script might edit character inside strings.
# TODO: show help if no input.
# TODO: automatically detect if colordiff is installed, otherwise use regular diff or git diff.
# TODO: remove lines that are made of only spaces or tabs.
# TODO: add cases where methods start with '+' instad of '-'.

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
  # Spaces around '=', '==' and '!='.
  sed -i '' "s;\([^ 	=!]\)[ 	]*\([!]*[=]\{1,\}\)[ 	]*\([^ 	=!]\);\1 \2 \3;g" $TMP_FILE

  ## POINTERS
  # Removes right spaces.
  sed -i '' "s-\*[ 	]*-\*-" $TMP_FILE
  # Normalizes left spaces.
  sed -i '' "s-\([^(][^ 	]\{1,\}\)[ 	]*\*\([^)]\)-\1 \*\2-" $TMP_FILE


  ## METHOD DECLARATION
  # Normalizes spaces in method return type: '   -   (void)    method' -> '- (void)method'
  sed -i '' "s,^[ 	]*-[ 	]*(\([^)]*\))[ 	]*,- (\1)," $TMP_FILE
  # Normalize spaces after colon in method signature
  sed -i '' "s,\(^[ 	]*-.*\)[ 	]*:[ 	]*\(.*[ 	]*{\),\1:\2,g" $TMP_FILE
  # Normalize spaces after closing parentesis for parameter tipe: "call:(type) var" -> "call:(type)var"
# TODO: NOT WORKING PROPERLY
  sed -i '' "s,\(^[ 	]*-.*:[ 	]*([^)]*)\)[ 	]*\([^ 	].*{\),\1\2,g" $TMP_FILE
#echo "- (void)tableViewController:(BasicCellTableViewController*) _tableViewController didSelectRowAtIndexPath:(NSIndexPath*)indexPath {" | sed "s,[ ]*-[ ]*(.*:([^)]*)[ ]*\([^ ]\),%%%\1,g"

  # Exactly one space before opening { on method declaration
  sed -i '' "s,\(^[ 	]*-.*[^ 	]\)[ 	]*{,\1 {," $TMP_FILE
  # Spacing inside parenthesis:
  #   '(type    *)' -> '(type *)'
  sed -i '' "s;\(([^)]*[^ 	)]\)[ 	]*\(\*[\* 	]*)\);\1 \2;g" $TMP_FILE
  #   '(   type *)' -> '(type *)'
  sed -i '' "s;([ 	]\{1,\}\([^)]*\));(\1);g" $TMP_FILE
  #   '(type *   )' -> '(type *)'
  sed -i '' "s;(\([^)]\{1,\}[^ 	]\)[ 	]\{1,\});(\1);g" $TMP_FILE 


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
  # Spacing around colon in interface definition:
  sed -i '' "s;^[ 	]*@interface[ 	]*\([^ 	]*\)[ 	]*:[ 	]*\([^ 	].*[^ 	]\)[ 	]*$;@interface \1 : \2;" $TMP_FILE
  # Spaces around '*' in extern constants definitions:
  sed -i '' "s,^[ 	]*\(extern .*[^ 	\*]\)[ 	]*\*[ 	]*\([^ 	]*.*\)$,\1 * \2," $TMP_FILE

  #Ensure newline at EOF:
  sed -i '' -e '$a\' $TMP_FILE

  if [ "$SHOW_DIFF" = "true" ]; then
    command -v colordiff >/dev/null 2>&1
    if [[ "$?" -eq 0 ]]; then
      colordiff $ORIGINAL_FILE $TMP_FILE 2>/dev/null
    else
      diff $ORIGINAL_FILE $TMP_FILE
    fi
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

function showHelp {
  echo "Usage:"
  echo -e "\t-a: shows whole file output instead of diff."
  echo -e "\t-h: shows help."
  echo -e "\t-i: inplace."
  echo ""
}

SHOW_DIFF="true"
INPLACE="false"
while getopts ":ae:hi" opt; do
  case $opt in
    e)
      echo "-a was triggered, Parameter: $OPTARG" >&2
      ;;
    a)
      SHOW_DIFF="false"
      ;;
    h)
      showHelp
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

if [[ "$#" -eq 0 ]]; then
  showHelp
  exit 0
fi

argstart=$OPTIND
for p in "${@:$argstart}"
  do
    main "$p" "$SHOW_DIFF"
  done

