#!/bin/bash

set -e

if [ $# -lt 3 ] ; then
  echo "$0 major minor revision" >&2
  exit 1
fi

OLD_ROCK_VERS=$(ls -1 *.rockspec | sed 's/^[^-]*-//;s/\.rockspec$//;q')
NEW_ROCK_VERS="$1.$2-$3"
NEW_STD_VERS="$1.$2.$3"

OLD_ROCK_VERS_REG="${OLD_ROCK_VERS//./\\.}"
SED_LUA_REPLACE="s/$OLD_ROCK_VERS_REG/$NEW_ROCK_VERS/"
SED_VERSION_REPLACE="s/v${OLD_ROCK_VERS_REG/-/\\.}/v$NEW_STD_VERS/"

sed "$SED_LUA_REPLACE" -i README.md

for prefix in xmlparser xmllpegparser ; do
  NEWFILE="$prefix-$NEW_ROCK_VERS.rockspec"
  OLDFILE="$prefix-$OLD_ROCK_VERS.rockspec"
  mv "$OLDFILE" "$NEWFILE"
  sed -i "$SED_LUA_REPLACE;$SED_VERSION_REPLACE" "$NEWFILE"
  git add "$NEWFILE"
done

git commit -vam "Version $NEW_STD_VERS"
git tag "v$NEW_ROCK_VERS"
git push --tags
