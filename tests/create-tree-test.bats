#!/usr/bin/env bats

load git-utils

@test "test the create_tree utility function" {

  WORK_DIR="$(mktemp -d /tmp/create-tree-test.XXXX)"

  #
  # Create an upstream project
  #
  upstream_name="upstream-project"
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

  # Make sure that things end up nominally in the right place.
  [ -d $WORK_DIR/$upstream_name ]
  [ -f $WORK_DIR/$upstream_name/README.md ]
  [ -d $WORK_DIR/$upstream_name/scripts ]
  [ -f $WORK_DIR/$upstream_name/scripts/script.sh ]
  [ -d $WORK_DIR/$upstream_name/tests ]
  [ -f $WORK_DIR/$upstream_name/tests/unit.tests ]

  cd "$WORK_DIR/$upstream_name"
  git init
  git config user.email 'developers+pantheon-upstream@getpantheon.com'
  git config user.name 'Pantheon Upstream Bot'
  git add .
  git commit -m "Initial commit of test project $upstream_name"
  git tag -a -m "Version 1.0.0" '1.0.0'

  #
  # Copy the files of the 'upstream' project to make the 'downstream' project.
  #
  downstream_name="downstream-project"
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

  # The two trees should be different.  The diff should show us the
  # difference in content between the README.md files.
  run diff -Nupr -x .git "$WORK_DIR/$upstream_name" "$WORK_DIR/$downstream_name"
  [ "$status" -eq 1 ]
  [ "${lines[4]}" = "-This is test repository representing the upstream" ]
  [ "${lines[5]}" = "+This is a downstream repository created from the initial upstream" ]
}
