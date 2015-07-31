#!/usr/bin/env bats

#
# git-test.bats
#
# This test file tests the functions in 'tree.bash'.
# This file is only used by the bats tests, for test data generation.
#

load tree
load ../scripts/git

@test "test the various git utility functions" {

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
  cd "$WORK_DIR"
  git clone "$WORK_DIR/$upstream_name/" "$downstream_name"

  cd "$WORK_DIR/$downstream_name"
  git config user.email 'developers+pantheon-upstream@getpantheon.com'
  git config user.name 'Pantheon Upstream Bot'

  data='
  .
  |-- README.md                 "This is a downstream repository created from the initial upstream"
  |-- scripts
  |   `-- enhancement.sh        "echo our enhancement"
  `-- tests
      `-- enhancement.tests     "Of course we will test our enhancements too"
  '

  create_tree "$WORK_DIR/$downstream_name" "$data" "Add some enhancements"

  # The two trees should be different.  The diff should show us the
  # difference in content between the README.md files.
  run diff -Nupr -x .git "$WORK_DIR/$upstream_name" "$WORK_DIR/$downstream_name"
  [ "$status" -eq 1 ]
  [ "${lines[4]}" = "-This is test repository representing the upstream" ]
  [ "${lines[5]}" = "+This is a downstream repository created from the initial upstream" ]

  # Test to see if our commit is in the git log
  git log | grep "Add some enhancements"

  #
  # Make a bunch of commits in the upstream to simulate a new release
  #
  cd "$WORK_DIR/$upstream_name"
  git checkout -b "work"

  data='
  .
  `-- scripts
      `-- update.sh             "echo a new feature"
  '

  create_tree "$WORK_DIR/$upstream_name" "$data" "Add update script"

  data='
  .
  `-- scripts
      `-- something.sh           "echo something else to do"
  '

  create_tree "$WORK_DIR/$upstream_name" "$data" "Something else we committed"

  data='
  .
  `-- scripts
      `-- script.sh             "echo some sort of bugfix"
  '

  create_tree "$WORK_DIR/$upstream_name" "$data" "A bugfix replacing an existing file"

  data='
  .
  `-- scripts
      `-- version.sh            "echo 1.0.1"
  '

  create_tree "$WORK_DIR/$upstream_name" "$data" "Version 1.0.1 release"

  # Test to see if the first commit is in the log
  git log | grep "Add update script"

  # Test to see if the last commit is in the log
  git log | grep "Version 1.0.1 release"

  # Now we will create a new "squashed" branch with the first three commits
  # squashed onto a new branch called "squashed"
  squash_all_but_last_commit "master" "squashed"

  # The release commit should still be in the commit log
  git log | grep "Version 1.0.1 release"

  # We should not see this commit any longer, however.
  run bash -c 'git log | grep "Add update script"'
  [ -n "$status" ]
}
