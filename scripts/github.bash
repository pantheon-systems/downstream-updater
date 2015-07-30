#!/bin/bash

#
# Add a label to a repository
#
# Usage:
#
#   add_label_to_repo $REPO "label-name" "label-color"
#
function add_label_to_repo() {
  local TARGET_REPO="$1"
  local LABEL_NAME="$2"
  local LABEL_COLOR="$3"

  local ADD_LABEL_TO_REPO_FILE="$TEMP_WORK/add-label-to-repo.json"

  # Create the "automation" label if it does not already exist
  curl --user-agent "$UA" -H "Content-Type: application/json" -H "Authorization: token $ENCODED_TOKEN" --data '{ "name": "'"$LABEL_NAME"'", "color": "'"$LABEL_COLOR"'" }' "https://api.github.com/repos/$TARGET_REPO/labels" --output "$ADD_LABEL_TO_FILE" &>/dev/null
}

#
# Add a label to an issue (or PR)
#
# Usage:
#
#   add_label_to_repo $REPO $ISSUE_NUMBER "label-name" "label-color"
#
function add_label_to_issue() {
  local TARGET_REPO="$1"
  local ISSUE_NUMBER="$2"
  local LABEL_NAME="$3"
  local LABEL_COLOR="$4"

  local ADD_LABEL_TO_ISSUE_FILE="$TEMP_WORK/add-label-to-issue.json"

  # Add the specified label to the provided issue number
  curl --user-agent "$UA" -H "Content-Type: application/json" -H "Authorization: token $ENCODED_TOKEN" --data '[ "'"$LABEL_NAME"'" ]' "https://api.github.com/repos/$TARGET_REPO/issues/$ISSUE_NUMBER/labels" --output "$ADD_LABEL_TO_ISSUE_FILE" &>/dev/null
  if [ $? != 0 ]
  then
    # Label does not exist in the repository?  Create it first
    add_label_to_repo "$TARGET_REPO" "$LABEL_NAME" "$LABEL_COLOR"
    # Try to add the label again
    curl --user-agent "$UA" -H "Content-Type: application/json" -H "Authorization: token $ENCODED_TOKEN" --data '[ "'"$LABEL_NAME"'" ]' "https://api.github.com/repos/$TARGET_REPO/issues/$ISSUE_NUMBER/labels" --output "$ADD_LABEL_TO_ISSUE_FILE" &>/dev/null
  fi
}

#
# Add a label to an issue (or PR)
#
# Usage:
#
#   create_pull_request $REPO "Title" "Body" master pr-branch $OUTPUT_FILE
#
function create_pull_request() {
  local TARGET_REPO="$1"
  local TITLE="$2"
  local BODY="$3"
  local BASE="$4"
  local HEAD="$5"
  local OUTPUT_FILE="$6"

  echo curl --user-agent "$UA" -H "Content-Type: application/json" -H "Authorization: token $ENCODED_TOKEN" --data '{"title":"'"$TITLE"'", "body":"'"$BODY"'","head":"'"$HEAD"'","base":"'"$BASE"'"}' "https://api.github.com/repos/$TARGET_REPO/pulls"
  curl --user-agent "$UA" -H "Content-Type: application/json" -H "Authorization: token $ENCODED_TOKEN" --data '{"title":"'"$TITLE"'", "body":"'"$BODY"'","head":"'"$HEAD"'","base":"'"$BASE"'"}' "https://api.github.com/repos/$TARGET_REPO/pulls" --output "$OUTPUT_FILE" &>/dev/null
  check "Created new PR '$TITLE' on $TARGET_REPO" "Failed to create PR '$TITLE' on $TARGET_REPO"
}

#
# Find a pull request, given a title to search for
#
# Usage:
#
#    find_pull_request_by_title $REPO "Title" $OUTPUT_FILE
#
function find_pull_request_by_title() {
  local REPO="$1"
  local TITLE="$(urlencode "$2")"
  local OUTPUT_FILE="$3"

  curl --user-agent "$UA" "https://api.github.com/search/issues?q=$TITLE+type:pr+state:open+in:title+repo:$REPO" --output "$OUTPUT_FILE" &>/dev/null
}

#
# Find pull requests in a repo that have a certain label
#
# Usage:
#
#    find_pull_request_by_label $REPO "shipit" $OUTPUT_FILE
#
function find_pull_request_by_label() {
  local REPO="$1"
  local LABEL="$(urlencode "$2")"
  local OUTPUT_FILE="$3"

  curl --user-agent "$UA" "https://api.github.com/search/issues?q=+type:pr+state:open+label:$LABEL+repo:$REPO&sort=created&order=asc" --output "$OUTPUT_FILE" &>/dev/null
}

# GET /users/:username/repos
function list_repositories() {
  local TARGET_USER="$1"
  local OUTPUT_FILE="$2"

  curl --user-agent "$UA" "https://api.github.com/users/$TARGET_USER/repos" -H "Authorization: token $ENCODED_TOKEN" --output "$OUTPUT_FILE" &>/dev/null
}

#
# Create a repository owned by the authenticated user
#
# Usage:
#
#    create_repository 'test-repo-123' 'Description of repo', 'http://homepage.io' 'has_issues has_wiki has_downloads !auto_init' $OUTPUT_FILE
#
function create_repository() {
  local TARGET_REPO="$1"
  local DESCRIPTION="$2"
  local HOMEPAGE="$3"
  local FLAGS="$4"
  local OUTPUT_FILE="$5"

  ARGS="$(parse_function_flags "has_issues has_wiki has_downloads auto_init" "$FLAGS")"
  echo curl --user-agent "$UA" -H "Content-Type: application/json" -H "Authorization: token $ENCODED_TOKEN" --data '{"name":"'"$TARGET_REPO"'", "description":"'"$DESCRIPTION"'", "homepage":"'"$HOMEPAGE"'"'"$ARGS"'}' "https://api.github.com/user/repos" --output "$OUTPUT_FILE" &>/dev/null
  curl --user-agent "$UA" -H "Content-Type: application/json" -H "Authorization: token $ENCODED_TOKEN" --data '{"name":"'"$TARGET_REPO"'", "description":"'"$DESCRIPTION"'", "homepage":"'"$HOMEPAGE"'"'"$ARGS"'}' "https://api.github.com/user/repos" --output "$OUTPUT_FILE" &>/dev/null
  check "Created new PR '$TITLE' on $TARGET_REPO" "Failed to create PR '$TITLE' on $TARGET_REPO"
}

#
# Delete a repository.  Watch out!
#
# Usage:
#
#    delete_repository $REPO $OUTPUT_FILE
#
function delete_repository() {
  local TARGET_REPO="$1"
  local OUTPUT_FILE="$2"

  echo curl --user-agent "$UA" -H "Content-Type: application/json" -H "Authorization: token $ENCODED_TOKEN" -X DELETE "https://api.github.com/repos/$TARGET_REPO"
  curl --user-agent "$UA" -H "Content-Type: application/json" -H "Authorization: token $ENCODED_TOKEN" -X DELETE "https://api.github.com/repos/$TARGET_REPO" --output "$OUTPUT_FILE" &>/dev/null
}
