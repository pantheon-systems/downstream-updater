#!/usr/bin/env bats

#
# tree-test.bats
#
# This test file tests the functions in 'tree.bash'.
# This file is only used by the bats tests, for test data generation.
#

load tree

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

  # Make sure that things end up in the right place.
  [ -d $WORK_DIR/$upstream_name ]
  [ -f $WORK_DIR/$upstream_name/README.md ]
  [ -d $WORK_DIR/$upstream_name/scripts ]
  [ -f $WORK_DIR/$upstream_name/scripts/version.sh ]
  [ -f $WORK_DIR/$upstream_name/scripts/script.sh ]
  [ -d $WORK_DIR/$upstream_name/tests ]
  [ -f $WORK_DIR/$upstream_name/tests/unit.tests ]

  # Check the contents of the README file
  CONTENTS=$(cat $WORK_DIR/$upstream_name/README.md)
  [ "$CONTENTS" == "This is test repository representing the upstream" ]

  # Run the version script
  VERSION=$($WORK_DIR/$upstream_name/scripts/version.sh)
  [ "$VERSION" == "1.0.0" ]
}
