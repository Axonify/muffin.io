git checkout gh-pages
git merge master -m"Merge master"
muffin minify
git add -f <?= buildDir ?>
git add -u <?= buildDir ?>
git commit -m"Commit for deployment"
git subtree push --prefix <?= buildDir ?> origin gh-pages
git checkout master
