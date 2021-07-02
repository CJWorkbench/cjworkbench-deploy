# Deploying cjworkbench on Kubernetes

This repository is lightly inspired by GitOps, but ultimately it's imperative.

## TL;DR Maintaining Workbench on production

1. Code in the [cjworkbench](https://github.com/CJWorkbench/CJWorkbench)
   repository.
2. Commit your changes, usually in a pull request.
3. Wait for GitHub to report success on your pull request.
4. Merge (and usually flatten) the pull request to `master`.
5. Wait for GitHub to report success on the latest `master` commit. Success
   means, those images are in our Docker repository.
6. Wait for GitHub Actions to run `advanced-deploy ENVIRONMENT SHA`.
7. Check that staging is alive.
8. Run `./update-production-to-staging`.

Each push to the CJWorkbench repository leads to a Google Cloud Build, with
images.

Each push to `master` leads to a staging deploy. You can mimic that deploy
with `./update-staging-to-latest-passing-master`.

The best way to deploy to production is `./update-production-to-staging`.

To roll back, use `./advanced-deploy ENVIRONMENT SHA`. Database migrations can
impede successful rollbacks, so be extra-careful when migrating.

# Commands

## <a name="advanced-deploy"></a>`advanced-deploy ENVIRONMENT SHA`

Do the deploy dance:

1. Upload assets at version `$SHA` to the static web server
2. (simultaneously with 1) Run new database migrations in version `$SHA`
3. Set all running images to version `$SHA`, with configs from `overlays/$ENVIRONMENT`
4. Wait for rollout to finish

BEWARE: this writes files, sullying the Git repository. Don't commit the
changes.

## `clear-render-cache ENVIRONMENT`

(Slowly) delete all cached tables, one workflow at a time, respecting locks.

Currently, there are some nasty side-effects:

* API requests for cache-miss will respond HTTP 503 (and schedule a re-render).
* Email notifications won't be sent on each workflow's next update.
* Users will see "busy" when they browse to their workflows.
* Server load will be much, much higher than usual; spin up many renderers to cope!

## `psql ENVIRONMENT`

Launch `psql` within a `frontend` pod.

## `refresh-suggested-modules ENVIRONMENT`

Re-import all modules.

Generally, when we push a module to GitHub we import it on staging and
production. So in theory, we shouldn't ever need to run this command. It can
give peace of mind.

## `update-production-to-staging`

Run [advanced-deploy](#advanced-deploy) on production, with staging's `$SHA`.

BEWARE: this writes files, sullying the Git repository. Don't commit the
changes.

## `update-staging-to-latest-passing-master`

Check GitHub for the "best" `$SHA`, and run [advanced-deploy](#advanced-deploy)
on staging.

BEWARE: this writes files, sullying the Git repository. Don't commit the
changes.

# Extra documentation

The `./cluster-setup` folders show how some clusters were created. These scripts
are imperative and _illustrative_. Try them and suggest changes! It'll take some
effort.

TODO it would be cool to spin up a cluster per pull request. These scripts are
the start.
