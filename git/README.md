
Basics of git: gitting onboard.

Branches
--------

Making and changing branches

```bash
# see current branches
git branch

# change to master and pull in updates
git checkout master
git pull origin master

# create a new local branch and check it out at the same time
git checkout -b my-new-feature-branch
# add new branch to the remote repo
git push origin my-new-feature-brach
# add new branch to the remote repo & set upstream repo to pull in updates
git push --set-upstream origin/master my-new-feature-brach

# set origin to master for branch
git branch --set-upstream-to=origin/master my-new-feature-brach

# change to remote branch that is not yet local
git checkout -b [branch] origin/[branch]

# add a remote branch to your local list of branches
git remote add my-new-feature-brach-already-in-repo
```

Adding edited branches back to master.

```bash
# in preparation to submit a pull request to the master (to pull in the branch
# changes to master), make sure that the local branch is synced with the
# master
git pull origin my-new-feature-branch

# push the new feature branch to the repo
# NOTE: this will be automatically rejected if there are unincorporated updates
git push origin my-new-feature-brach
```

Deleting a branch.

```bash
# delete a branch on your local filesystem
git branch -d my-new-feature-branch

# force delete a branch on your local filesystem
git branch -D my-new-feature-branch

# delete the branch on GitHub
git push origin :my-new-feature-branch
```

Adding a submodule (e.g., include another repo in current one):
```bash
# fork the repo if you don't own it

# now add the submodule
git submodule add git@github.com:${USER}/${YOUR_REPO}.git

# in order to see that submodule repo being displayed with full content in repo
git submodule update --init
```
