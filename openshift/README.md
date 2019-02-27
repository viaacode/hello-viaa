### Introduction

This is a very simple Openshift setup. There are a lot of other possibilities:

1. Splitting the config maps/secrets in multiple reusable entities
2. Defining services, routes, persistent storage, jobs, cronjobs, ...
3. Combining template files
4. ...

See the other Openshift projects.

Don't forget to change the variables in the init.sh script.

### Manual:

For all non critical environments: set ImageStream to 'latest' instead of 'stable' and set automatic: true manually in the deploymentConfig->ImageChange trigger via Openshift web interface (edit YAML or just edit).

### Routing:

This is done outside of Openshift (ask devops teams). To see if the app works you can create a temporary route to the service in Openshift and visit the url.
