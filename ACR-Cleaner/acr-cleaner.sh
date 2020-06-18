#!/usr/bin/env bash

TIMESTAMP_45DAYS=$(date -d '-45 days' +%Y-%m-%d)
TIMESTAMP_30DAYS=$(date -d '-30 days' +%Y-%m-%d)
TIMESTAMP_15DAYS=$(date -d '-15 days' +%Y-%m-%d)

# Modify for your environment
REGISTRY="<Registry Name>"

function usage {
  echo "Usage: $0 -n enable_delete"
  echo "  -n enable_delete  Enable delete for image deletion"
  echo "  -h                display help"
}

[ $# -eq 0 ] && usage && exit 1
while getopts ":hn:" arg; do
  case $arg in
    n)
      ENABLE_DELETE=${OPTARG}
      ;;
    h | *) # Display help.
      usage
      exit 0
      ;;
  esac
done

if [ -z "$ENABLE_DELETE" ]; then
  echo "Missing ENABLE_DELETE variable"
  exit 1
fi

# List all repository in the registry
REPOSITORY_LIST=$(az acr repository list --name $REGISTRY -o tsv)

echo "Repository List : $REPOSITORY_LIST"
echo ""
echo ""

delete_images() {
  REPOSITORY=$1
  QUERY=$2
  az acr repository show-manifests --name $REGISTRY --repository $REPOSITORY \
      --orderby time_asc --query "$QUERY" -o tsv \
      | head -n -2 \
      | xargs -I% az acr repository delete --name $REGISTRY --image $REPOSITORY@% --yes
}

check_images() {
    REPOSITORY=$1
    QUERY=$2
    az acr repository show-manifests --name $REGISTRY --repository $REPOSITORY \
        --orderby time_asc --query "$QUERY" -o tsv \
        | head -n -2
}


for REPOSITORY in $REPOSITORY_LIST; do
  if [ "$ENABLE_DELETE" = true ]; then
    echo ""
    echo "Processing repository=$REPOSITORY"
    echo ""

    echo ""
    echo "Deleting Feature Branch Images older than 15 Days"
    echo ""
    delete_images "$REPOSITORY" "[? not_null(tags[0]) && !contains(tags[0],'master') && !contains(tags[0],'staging') && !contains(tags[0],'latest')  && timestamp < '$TIMESTAMP_15DAYS' ].digest"

    echo ""
    echo "Deleting Master Branch Images older than 45 Days"
    echo ""
    delete_images "$REPOSITORY" "[? not_null(tags[0]) && contains(tags[0],'master') && timestamp < '$TIMESTAMP_45DAYS' ].digest"

    echo ""
    echo "Deleting Staging Branch Images older than 30 Days"
    echo ""
    delete_images "$REPOSITORY" "[? not_null(tags[0]) && contains(tags[0],'staging') && timestamp < '$TIMESTAMP_30DAYS' ].digest"

    echo ""
    echo "Deleting untagged images"
    echo ""
    delete_images "$REPOSITORY" "[?tags[0]==null].digest"

    echo ""
    echo "Completed Processing repository=$REPOSITORY"
    echo ""
  else
    echo ""
    echo "No data will be deleted."
    echo "Set ENABLE_DELETE=true to enable deletion"
    echo ""
    echo "Processing repository=$REPOSITORY"
    echo ""

    echo ""
    echo "Feature Branch Images older than 15 Days"
    echo ""
    check_images "$REPOSITORY" "[? not_null(tags[0]) && !contains(tags[0],'master') && !contains(tags[0],'staging') && !contains(tags[0],'latest')  && timestamp < '$TIMESTAMP_15DAYS' ].[tags[0],timestamp]"

    echo ""
    echo "Master Branch Images older than 45 Days"
    echo ""
    check_images "$REPOSITORY" "[? not_null(tags[0]) && contains(tags[0],'master') && timestamp < '$TIMESTAMP_45DAYS' ].[tags[0],timestamp]"

    echo ""
    echo "Staging Branch Images older than 30 Days"
    echo ""
    check_images "$REPOSITORY" "[? not_null(tags[0]) && contains(tags[0],'staging') && timestamp < '$TIMESTAMP_30DAYS' ].[tags[0],timestamp]"

    echo ""
    echo "untagged images"
    echo ""
    check_images "$REPOSITORY" "[?tags[0]==null].[digest,timestamp]"

    echo ""
    echo "Completed Processing repository=$REPOSITORY"
    echo ""
  fi
done
echo "Done"
