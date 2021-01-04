#!/bin/bash
# Adopted from https://sookocheff.com/post/linux/deploying-a-static-site-with-rsync/
set -o nounset
set -o errexit

DIR="/opt/documentation.networkcanvas.com"
DEPLOY_SOURCE_DIR="_site/"
DEPLOY_DEST_DIR="/var/www/documentation.networkcanvas.com"

echo $DIR

NFLAG=""

while getopts ":n" opt; do
  case $opt in
    n)
      NFLAG="-n"
      echo "Dry run, not modifying server files"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

[ -f "$DIR/.env" ] && source "$DIR/.env"

git -C $DIR fetch origin
git -C $DIR clean -fd
git -C $DIR git reset --hard origin/master
git -C $DIR submodule update --init --recursive

echo "Building production Jekyll site"
JEKYLL_ENV=production BUNDLE_GEMFILE=$DIR/Gemfile bundle exec jekyll build --config $DIR/_config.yml,$DIR/_config-production.yml,$DIR/_config-pdf.yml

echo "Deploying ${DIR}/${DEPLOY_SOURCE_DIR} to ${DEPLOY_DEST_DIR}"
rsync $NFLAG -rvz --delete --rsync-path="sudo rsync" "${DIR}/${DEPLOY_SOURCE_DIR}" "${DEPLOY_DEST_DIR}"
