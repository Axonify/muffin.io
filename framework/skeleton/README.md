## Deploy to Heroku
Create the app:

    heroku login
    heroku create
    heroku config:add NODE_ENV=production
    heroku addons:add mongolab

Deploy a new build:
    
    muffin deploy heroku

which does the following:

    git checkout -b temp_branch_for_deployment
    cp -f .deploy-gitignore .gitignore
    muffin build
    git add .
    git commit -m"Commit for deployment"
    git push heroku temp_branch_for_deployment:master
    git checkout master
    git branch -D temp_branch_for_deployment

Scale up:

    heroku ps:scale web=1

Check server status and logs:

    heroku ps
    heroku logs

Open the app:

    heroku open