# Monarch OLS

This repository contains the configuration of a bespoke Ontology Lookup Service for the Monarch Initiative. 

### To launch local in [OLS](https://www.ebi.ac.uk/ols/index) via [Docker](https://www.docker.com/)

```
docker build . -t monarch-ols
docker run -p 8080:8080 -t monarch-ols
```

OLS should now be running at http://localhost:8080
