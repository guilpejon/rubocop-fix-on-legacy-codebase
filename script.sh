#!/bin/bash

cat cops.txt | while read cop
do
  BRANCH_NAME="fix-${cop}"
  cop_description=`awk -F"${cop}: " '{print $2}' cop_descriptions.yml | sed '/^[[:space:]]*$/d'`
  echo ${cop_description}

  git checkout master
  git pull origin master

  # create a new branch
  git checkout -b $BRANCH_NAME

  # run cop auto-correct
  > .rubocop_todo.yml
  rubocop -a --only "${cop}"

  # recreate .rubocop_todo
  rm .rubocop_todo.yml
  bundle exec rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit=10000

  # add cop to .rubocop.strict
  echo -e "\n${cop}:\n  Description: ${cop_description}\n  Enabled: true\n" >> .rubocop_strict.yml

  # add changes
  git add .

  # reset script and cops file
  git reset cops.txt
  git reset script.sh
  git reset cop_descriptions.yml

  # reset gemfiles because of capybara-webkit mac bug
  git reset Gemfile
  git reset Gemfile.lock

  # commit and open PR
  git commit -m "[RUBOCOP] Fix cop ${cop}"
  git push origin $BRANCH_NAME --no-verify -f
  gh pr create --fill

  # return to main branch
  git checkout master

  # erase used branch
  git branch -D $BRANCH_NAME

  # so gh client behaves
  sleep 1m
done
