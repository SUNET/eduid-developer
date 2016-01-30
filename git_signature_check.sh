#!/bin/bash
#
# This script verifies all the signatures of commits in the
# current branch, or all commits made after the last trusted tag.
#
# Inspired by https://mikegerwitz.com/papers/git-horror-story.html
# and how Cosmos verifies git tags.

t="$( echo $'\t' )"

echo "Doing a git pull ..."
git pull

last_tag="$(git describe --tags --abbrev=0 2>/dev/null)"

if [ ${?} -ne 0 ]; then
    echo "No tags found, verifying all commits instead."
    git_log="$(git log --pretty="format:%H${t}%aN${t}%s${t}%G?" --first-parent \
        | grep -v "${t}G$")"
else
    echo "Verifying last tag: ${last_tag} and the commits after that"

    git tag -v "${last_tag}" | grep ^gpg:
    # again to not mask exit status of git with grep
    git tag -v ${last_tag} > /dev/null 2>&1

    if [ ${?} -ne 0 ]; then
        echo "WARNING: The last tag was not signed by a trusted key!, aborting."
        exit 1
    fi

    tag_object="$(git tag -v ${last_tag} 2>&1 | grep ^object | cut -d' ' -f2)"

    revision_range="${tag_object}..HEAD"

    git_log="$(git log --pretty="format:%H${t}%aN${t}%s${t}%G?" \
        ${revision_range} --first-parent | grep -v "${t}G$")"
fi

if [ ! -z "${git_log}" ]; then
    echo -e "\n----WARNING: unsigned or untrusted commits----"
    echo "${git_log}"
    exit 1
else
    echo -e "\n----All commits and/or tags verified OK----"
    exit 0
fi
