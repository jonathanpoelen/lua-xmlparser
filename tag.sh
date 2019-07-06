#!/bin/bash

set -e

if [ $# -lt 3 ] ; then
  echo "$0 major minor revision" >&2
  exit 1
fi

oldfile=(*.rockspec)
oldfile=${oldfile[0]}
name=${oldfile::-9}
lib=${name/-*}
old_rock_vers=${name#*-}
new_rock_vers="$1.$2-$3"
new_std_vers="$1.$2.$3"
newfile="$lib-$new_rock_vers.rockspec"

sed -i "s/$old_rock_vers/$new_rock_vers/;s/${old_rock_vers/-/\\.}/$new_std_vers/" "$oldfile"
sed -i "s/${oldfile//./\\.}/$newfile/" README.md
mv "$oldfile" "$newfile"

git add "$oldfile" "$newfile" README.md
git commit -vm "$lib version $new_std_vers"
git tag "v$new_std_vers"
git push --tags
git push
