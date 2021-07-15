#!/bin/bash

# Configs
directory="c:/Users/Aleksuei\ Riabtsev/Development/Personal/Github/commit_manager/"

remote="ar"
main_branch="notes"

cd $directory

branch=`date +%F`
date_human=`date +"%H:%M:%S %d %b %F"`

branch_exists=`git show-ref refs/heads/${branch}`
num_changes=`git status --porcelain=v1 2>/dev/null | wc -l`

git_is_merged() {
  # I am using the following bash function like:
  # git-is-merged develop feature/new-feature
  # https://stackoverflow.com/a/49434212/

  merge_destination_branch=$1
  merge_source_branch=$2

  merge_base=$(git merge-base $merge_destination_branch $merge_source_branch)
  merge_source_current_commit=$(git rev-parse $merge_source_branch)
  if [[ $merge_base = $merge_source_current_commit ]]
  then
    echo $merge_source_branch is merged into $merge_destination_branch
    return 0
  else
    echo $merge_source_branch is not merged into $merge_destination_branch
    return 1
  fi
}


create_commit() {
  local gstatus=`git status --porcelain`

  if [ ${#gstatus} -ne 0 ]
  then
    echo "Committing and pushing changes!"
    git add --all
    if [[ -n "$1" ]]
      then
        git commit -m "$1" -m "Porecellain: $gstatus"
      else
        git commit -m "$dateAuto Commit" -m "Porecellain: $gstatus"
    fi
  fi
}


commit_and_push() {
  git checkout $1

  create_commit

  git push $remote $1
}

commit_and_push_set_tracking() {
  git checkout $1
1
  create_commit

  git push -u $remote $1
}

create_squash_commit_push() {
  # Create squash commit from $1
  git checkout $main_branch

  local gcherry=`git cherry -v $main_branch $1`

  git merge --squash $1

  create_commit $date_human

  git push $remote $main_branch
}

prev_check() {
  local prev_branch=`date -d "yesterday" +%F`
  local prev_branch_exists=`git show-ref refs/heads/${prev_branch}`

  if [ -n "$prev_branch_exists" ]; then
    echo "Prev branch not deleted, processing!"

    git_is_merged $main_branch $prev_branch
    is_merged=$?
    echo $is_merged

    if [ $is_merged -eq 0 ]; then
      echo "$prev_branch merged"
    else
      echo "$prev_branch not merged"
      commit_and_push $prev_branch
      create_squash_commit_push $prev_branch
    fi

    # Delete prev day's branch
    git checkout $main_branch
    git branch -D $prev_branch
    git push --delete $remote $prev_branch

  else
    echo "Prev branch doesn't exist skipping"
  fi

}

main() {

  echo -e "/n/n===Running Script===/n :at $0 /n :on $(date) /n :with $num_changes changes /n"

  prev_check

  if [ -n "$branch_exists" ]; then
    echo 'Daily Branch exists!'
    # Commit all stuff here
    commit_and_push $branch
  else
    echo "Daily Branch doesn't exist!"
    git checkout $main_branch
    git checkout -b $branch
    commit_and_push_set_tracking $branch
  fi
}

main

