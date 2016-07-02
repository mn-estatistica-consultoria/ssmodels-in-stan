#!/bin/sh

set -e

[ -z "${GH_TOKEN}" ] && exit 0
[ "${TRAVIS_BRANCH}" != "master" ] && exit 0

BOOK_DIR=$(pwd)/doc/_book
rm -rf ~/_book
mkdir ~/_book && cd ~/_book
git clone -b gh-pages https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git .
ls | grep -v ^bookdown[.].* | xargs rm -rf
git ls-files --deleted -z | xargs -0 git rm
cp -r ${BOOK_DIR}/* ./
rm -rf _bookdown_files
git add --all *
git commit -m"update homepage (travis build ${TRAVIS_BUILD_NUMBER})"
git push -q -f origin gh-pages
