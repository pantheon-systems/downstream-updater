#!/bin/bash

#
# Create a tree of files on disk.
#
# Takes as input data output by 'tree' program, modified
# so that files contents are enclosed in quotes and placed
# on the same line as the filename.  Items in the tree that
# do not have contents are presumed to be directories, and
# are created as such.
#
# Usage:
#
#     create_tree base_dir "$data" OVERWRITE
#
#   or
#
#     create_tree base_dir "$data" "Commit comment"
#
function create_tree() {
  BASE="$1"
  if [ "x$3" == "xOVERWRITE" ]
  then
    rm -rf "$BASE"
  elif [ -d "$BASE/.git" ]
  then
    COMMIT_COMMENT="$3"
  fi
  SUBTREE=""
  CURRENT_LEVEL=
  while IFS='' read -r line || [[ -n $line ]]; do
      indentation="$(echo "$line" | sed -e 's/[a-zA-Z].*//')"
      filename="$(echo "$line" | sed -e 's/[^a-zA-Z]*//' -e 's/ .*//')"
      filecontents="$(echo "$line" | sed -e 's/[^"]*//' -e 's/"//g')"
      if [ -n "$filename" ]
      then
        # Compare our indentation level with the current indentation
        # level.  If this file has less indentation, then "pop" directories
        # off of the "SUBTREE" variable.
        INDENTATION_COUNT="${#indentation}"
        LEVEL="$(($INDENTATION_COUNT/3))"
        if [ -z "$CURRENT_LEVEL" ]
        then
          CURRENT_LEVEL="$LEVEL"
        fi
        # echo "Consider whether we need to pop up some; current level is $CURRENT_LEVEL and new level is $LEVEL"
        while [ "$CURRENT_LEVEL" -gt "$LEVEL" ]
        do
          SUBTREE=$(dirname "$SUBTREE")
          CURRENT_LEVEL=$(($CURRENT_LEVEL-1))
          # echo "   changed subtree to $SUBTREE and reduced current level to $CURRENT_LEVEL"
        done
        # Anything without contents is a directory
        if [ -z "$filecontents" ]
        then
          SUBTREE="$SUBTREE/$filename"
          mkdir -p "$BASE$SUBTREE"
          CURRENT_LEVEL=$(($CURRENT_LEVEL+1))
          # echo "Create directory $BASE$SUBTREE; level is now $CURRENT_LEVEL"
        else
          mkdir -p "$BASE$SUBTREE"
          (
            if [ "$(basename $filename .sh)" != "$filename" ]
            then
              echo '#!/bin/bash'
              echo
            fi
            echo "$filecontents"
          ) > "$BASE$SUBTREE/$filename"
          echo "create file $BASE$SUBTREE/$filename"
          if [ "$(basename $filename .sh)" != "$filename" ]
          then
            chmod +x "$BASE$SUBTREE/$filename"
          fi
          if [ -n "$COMMIT_COMMENT" ]
          then
            (
              cd "$BASE$SUBTREE"
              git add "$filename"
            )
          fi
        fi
      fi
  done <<< "$2"

  # If a commit comment was supplied, then go ahead and commit the changes
  cd "$BASE"
  if [ -n "$COMMIT_COMMENT" ]
  then
    git commit -m "$COMMIT_COMMENT"
  fi
}
