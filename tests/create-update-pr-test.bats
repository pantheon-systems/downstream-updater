#!/usr/bin/env bats

# bats isolates us from our environment a little too much; try to find our project base directory
PROJECT_BASE_DIR="`pwd -P`"
if [ ! -f "$PROJECT_BASE_DIR/scripts" ]
then
  if [ -f "$PROJECT_BASE_DIR/../scripts" ]
  then
    PROJECT_BASE_DIR="$PROJECT_BASE_DIR/.."
  elif [ -f "$PROJECT_BASE_DIR/downstream-updater/scripts" ]
  then
    PROJECT_BASE_DIR="$PROJECT_BASE_DIR/downstream-updater"
  fi
fi

# Set the $PATH so that we can call create-update-pr
PATH="$PROJECT_BASE_DIR/scripts:$PATH"

load tree

# To create the token:
# curl https://api.github.com/authorizations --user "pantheon-upstream" --data '{"scopes":["public_repo","delete_repo"],"note":"Token used in unit tests of pantheon-systems/downstream-updater."}'
#
# Old token:
# HUB_TOKEN="288f2e8348cd3d9fd4d12a5ebefdb0b8b4a8629e"

@test "update a test 'downstream' repository from a test 'upstream' update" {

  # Use the sequence number '$id' to prevent problems with conflicting repository names,
  # to insure that each repository is created fresh every time.
  id="$(date "+%Y%m%d-%H%M%S")"

  # Create a temporary directory to work in.
  WORK_DIR="/tmp/updater-$id"
  mkdir -p "$WORK_DIR"

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

  #
  # Copy the files of the 'upstream' project to make the 'downstream' project.
  #
  downstream_name="downstream-project-$id"
  cp -R "$WORK_DIR/$upstream_name" "$WORK_DIR/$downstream_name"
  rm -rf "$WORK_DIR/$downstream_name/.git"

  cd "$WORK_DIR/$downstream_name"
  git init
  git config user.email 'developers+pantheon-upstream@getpantheon.com'
  git config user.name 'Pantheon Upstream Bot'
  git add .
  git commit -m "Initial commit of test project $downstream_name"
  git tag -a -m "Version 1.0.0" '1.0.0'

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
  git add .
  git commit -m "Make some local modifications in the downstream."

  # The two trees should be different.  The diff should show us the
  # difference in content between the README.md files.
  run diff -Nupr -x .git "$WORK_DIR/$upstream_name" "$WORK_DIR/$downstream_name"
  [ "$status" -eq 1 ]
  [ "${lines[4]}" = "-This is test repository representing the upstream" ]
  [ "${lines[5]}" = "+This is a downstream repository created from the initial upstream" ]

  #
  # Create repositories on GitHub for the upstream and downstream projects.
  #
  cd "$WORK_DIR/$upstream_name"
  hub create -d "Test 'upstream' repository created for downstream-updater tests." -h "https://github.com/pantheon-systems/downstream-updater"
  git push --set-upstream origin master
  git push --tags

  cd "$WORK_DIR/$downstream_name"
  hub create -d "Test 'downstream' repository created for downstream-updater tests." -h "https://github.com/pantheon-systems/downstream-updater"
  git push --set-upstream origin master
  git push --tags

  #
  # Run the 'create-update-pr' script, and confirm that no PR was created
  #
  # We call this with the --force-cleanup flag to delete old repositories from
  # previous runs of the tool.
  #
  cd "$WORK_DIR"
  run create-update-pr --scripts-dir "$PROJECT_BASE_DIR/scripts" --version-major 1 --github-token "$ENCODED_TOKEN" --pr-creator "pantheon-upstream" --repo "pantheon-upstream/$downstream_name" --upstream-url "git@github.com:pantheon-upstream/${upstream_name}.git" -v -d
  if [ "$status" != 10 ]
  then
    echo "------ Status of create-update-pr is $status --------------"
    echo "$output"
    echo "PROJECT_BASE_DIR is $PROJECT_BASE_DIR"
    echo "PATH is $PATH"
    echo "-----------------------------------------------------"
  fi
  [ "$status" -eq 10 ]

  # TODO: should we confirm that the downstream repository is unmodified?

  #
  # Simulate a new release on 'upstream' by bumping the version number
  # and making a new tag.
  #
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

  #
  # Run the 'create-update-pr' script again, and confirm that a pari of PRs were created based on the new release
  #
  cd "$WORK_DIR"
  run create-update-pr --scripts-dir "$PROJECT_BASE_DIR/scripts" --version-major 1 --github-token "$ENCODED_TOKEN" --pr-creator "pantheon-upstream" --repo "pantheon-upstream/$downstream_name" --upstream-url "git@github.com:pantheon-upstream/${upstream_name}.git" -v -d
  if [ -n "$status" ]
  then
    echo "------ Status of create-update-pr is $status --------------"
    echo "$output"
    echo "PROJECT_BASE_DIR is $PROJECT_BASE_DIR"
    echo "PATH is $PATH"
    echo "-----------------------------------------------------"
  fi
  [ "$status" -eq 0 ]

  # TODO: Should we confirm that the downstream repository contains the right modifications?
}
