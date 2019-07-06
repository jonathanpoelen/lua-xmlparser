#!/bin/bash

set -e

if [ $# -lt 4 ] ; then
  echo "$0 old.rockspec major minor revision" >&2
  exit 1
fi

oldfile=$1
name=${oldfile::-9}
lib=${name/-*}
old_rock_vers=${name#*-}
new_rock_vers="$2.$3-$4"
new_std_vers="$2.$3.$4"
newfile="$lib-$new_rock_vers.rockspec"

sed -i "s/$old_rock_vers/$new_rock_vers/;s/${old_rock_vers/-/\\.}/$new_std_vers/" "$oldfile"
sed -i "s/${oldfile//./\\.}/$newfile/" README.md
mv "$oldfile" "$newfile"

git add "$oldfile" "$newfile" README.md
git commit -vm "$lib version $new_std_vers"
git tag "v$new_std_vers"
git push --tags
git push
