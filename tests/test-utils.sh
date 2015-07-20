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
function create_tree() {
  BASE="$1"
  if [ "x$3" == "xOVERWRITE" ]
  then
    rm -rf "$BASE"
  fi
  SUBTREE=""
  CURRENT_LEVEL=0
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
        while [ "$CURRENT_LEVEL" -gt "$LEVEL" ]
        do
          SUBTREE=$(dirname "$SUBTREE")
          CURRENT_LEVEL=$(($CURRENT_LEVEL-1))
        done
        # Anything without contents is a directory
        if [ -z "$filecontents" ]
        then
          SUBTREE="$SUBTREE/$filename"
          mkdir -p "$BASE$SUBTREE"
          echo "Create directory $BASE$SUBTREE"
          CURRENT_LEVEL=$(($CURRENT_LEVEL+1))
        else
          (
            if [ "$(basename $filename .sh)" != "$filename" ]
            then
              echo '#!/bin/bash'
              echo
            fi
            echo "$filecontents"
          ) > "$BASE$SUBTREE/$filename"
          echo "create file $BASE$SUBTREE/$filename"
        fi
      fi
  done <<< "$2"
}

# To create the token:
# curl https://api.github.com/authorizations --user "pantheon-upstream" --data '{"scopes":["public_repo","delete_repo"],"note":"Token used in unit tests of pantheon-systems/downstream-updater."}'
PANTHEON_UPSTREAM_TOKEN="288f2e8348cd3d9fd4d12a5ebefdb0b8b4a8629e"

# Use the sequence number '$id' to prevent problems with conflicting repository names,
# to insure that each repository is created fresh every time.
id="$(date "+%Y%m%d-%H%M%S")"

# Create a temporary directory to work in.
WORK_DIR="/tmp/updater-$id"
mkdir -p "$WORK_DIR"
#WORK_DIR="$(mktemp -d /tmp/updater-test.XXXX)"

#
# Create an upstream project
#
upstream_name="upstream-project-$id"
data='
.
|-- README.md                 "This is test repository representing the upstream"
|-- scripts
|   |-- version.sh            "echo 1.0.0"
|   `-- script.sh             "echo test"
`-- tests
    `-- unit.tests            "Sure, there are tests here."
'

create_tree "$WORK_DIR/$upstream_name" "$data" OVERWRITE

cd "$WORK_DIR/$upstream_name"
git init
git config user.email 'developers+pantheon-upstream@getpantheon.com'
git config user.name 'Pantheon Upstream Bot'
git add .
git commit -m "Initial commit of test project $upstream_name"
git tag -a -m "Version 1.0.0" '1.0.0'

hub create -d "Test 'upstream' repository created for downstream-updater tests." -h "https://github.com/pantheon-systems/downstream-updater"

#
# Copy the files of the 'upstream' project to make the 'downstream' project.
#
downstream_name="downstream-project-$id"
cp -R "$WORK_DIR/$upstream_name" "$WORK_DIR/$downstream_name"
rm -rf "$WORK_DIR/$downstream_name/.git"

data='
.
|-- README.md                 "This is a downstream repository created from the initial upstream"
|-- scripts
|   `-- enhancement.sh        "echo our enhancement"
`-- tests
    `-- enhancement.tests     "Of course we will test our enhancements too"
'

create_tree "$WORK_DIR/$downstream_name" "$data"

cd "$WORK_DIR/$downstream_name"
git init
git config user.email 'developers+pantheon-upstream@getpantheon.com'
git config user.name 'Pantheon Upstream Bot'
git add .
git commit -m "Initial commit of test project $downstream_name"

hub create -d "Test 'downstream' repository created for downstream-updater tests." -h "https://github.com/pantheon-systems/downstream-updater"

# TODO: Run the 'create-update-pr' script, and confirm that no PR was created


data='
.
|-- README.md                 "This is a better test repository representing the upstream"
`-- scripts
    `-- version.sh            "echo 1.0.1"
'

create_tree "$WORK_DIR/$upstream_name" "$data"

cd "$WORK_DIR/$upstream_name"
git add .
git commit -m "Simulate a new upstream release."
git tag -a -m "Version 1.0.1" '1.0.1'
git push --tags

# TODO: Run the 'create-update-pr' script again, and confirm that a pari of PRs were created based on the new release

