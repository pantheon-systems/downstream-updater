#/bin/bash

TARGET_COMPOSER_PROJECT_DIR="."

tags="$(git tag -l | grep '^[0-9]')"

for t in $tags; do
	echo "----------------------------------------------------"
	echo "version $t"
	git checkout $t
  sed -i '' -e 's#"name":.*#"name": "pantheon-systems/drops-8-scaffolding",#' $TARGET_COMPOSER_PROJECT_DIR/composer.json
  git diff
  git add composer.json
  git commit --amend --no-edit
  git tag -f $t
  git push -f origin $t
done
