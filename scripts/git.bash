#!/bin/bash

#
# Squash-merge one branch into another, preserving the last commit
# on the merged-in branch.
#
# Presuming that the current branch is "master", and we
# want to merge the "update" branch in with three commits:
# the first commit should be the squashed merge of all but
# the last commit on the branch, and the second commit
# should be the last commit on the branch.  The final commit
#
# Example:
#
#   update:                  (d) - (e) - (f) - (g)
#                           /
#   master:  (a) - (b) - (c) - (h)
#
#
# Interim result:             the squash commit
#                             ^
#   update:                  (*) - (g)
#                           /
#   master:  (a) - (b) - (c) - (h)
#
# Final result:
#
#                     the squash commit           the merge commit
#                                     ^           ^
#   master:  (a) - (b) - (c) - (h) - (*) - (g) - (m)
#                                           ^
#                                           the preserved commit
#
# Doing this allows later analysis of the repository to find
# all of the final commits for branches that were merged in by
# this technique.  The final commit will usually be the release
# commit; we wish to preserve the commit comment and commit
# hash for this commit, so that it is available for later inspection.
#
function squash_merge_preserving_last() {
  local UPDATE_BRANCH="$1"

  local BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  # Pick a name for the temporary squash branch
  local SQUASH_BRANCH=squash

  git checkout "$UPDATE_BRANCH"
  squash_all_but_last_commit "$BASE_BRANCH" "$SQUASH_BRANCH"

  git checkout "$BASE_BRANCH"

  git merge -m "Merge $UPDATE_BRANCH into $BASE_BRANCH" "$UPDATE_BRANCH"

  #git branch -D "$SQUASH_BRANCH"
}

#
# Squash all but the last commit on a branch.
#
# Usage:
#
#   cd $PROJECT
#   git checkout "work"
#   squash_all_but_last_commit "master" "squashed"
#
# Example:
#
#   work:                    (d) - (e) - (f) - (g)
#                           /
#   master:  (a) - (b) - (c) - (h)
#
#
# Desired result:
#                               the squash commit
#                               ^
#   squashed:                  (*) - (g)
#                              /
#   work:                    (d) - (e) - (f) - (g)
#                           /
#   master:  (a) - (b) - (c) - (h)
#
function squash_all_but_last_commit() {
  local BASE_BRANCH="$1"
  local SQUASH_BRANCH="$2"

  # Get the work branch == the current branch
  local WORK_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  # Pick a name for the temporary interim branch
  local INTERIM_BRANCH=interim

  # Find the most recent commit on the currenct branch "(g)"
  local HEAD_COMMIT=$(git rev-parse HEAD)

  # Find the base commit "(c)" between the current branch
  # ($WORK_BRANCH) and the base branch
  local BASE_COMMIT=$(git merge-base HEAD $BASE_BRANCH)

  # Make a new branch that is a copy
  # of the current branch (create "interim" from "work")
  git checkout -B "$INTERIM_BRANCH" "$BASE_COMMIT"

  # Add all of the commits from the work branch
  git merge "$WORK_BRANCH"

  # Remove the last commit off of the
  # "interim" branch
  git reset --hard 'HEAD~'

  # Make a new empty branch "squashed"
  # that branches from the same base commit, but
  # contains no other commits.
  git checkout -B "$SQUASH_BRANCH" "$BASE_COMMIT"

  # Squash-merge the "interim" branch into
  # the "squashed" branch.
  git merge --squash -m "Squash together all of the commits" "$INTERIM_BRANCH"
  git commit -m "Squash together all of the commits"

  # Cherry-pick the last commit from the
  # work branch "(g)" onto the "squashed" branch
  git cherry-pick "$HEAD_COMMIT"

  #git branch -D "$INTERIM_BRANCH"
}
