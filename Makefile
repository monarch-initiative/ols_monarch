URIBASE = http://purl.obolibrary.org/obo
ONTS = upheno2 geno upheno_patterns hp chr cl mondo_patterns
#monarch
ONTFILES = $(foreach n, $(ONTS), ontologies/$(n).owl)
VERSION = "0.0.3" 
IM=monarchinitiative/monarch-ols

docker-build:
	@docker build -t $(IM):$(VERSION) . \
	&& docker tag $(IM):$(VERSION) $(IM):latest
	
docker-build-no-cache:
	@docker build --no-cache -t $(IM):$(VERSION) . \
	&& docker tag $(IM):$(VERSION) $(IM):latest

docker-publish: docker-build
	@docker push $(IM):$(VERSION) \
	&& docker push $(IM):latest
	
docker-publish-no-build:
	@docker push $(IM):$(VERSION) \
	&& docker push $(IM):latest
	
docker-run:
	@docker run -p 8080:8080 -t $(IM):$(VERSION)

# Download and pre-process the ontologies
clean:
	rm -rf ontologies/*

ontologies: $(ONTFILES)

ontologies/%.owl: 
	$(ROBOT) convert -I $(URIBASE)/$*.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/hp.owl: 
	$(ROBOT) convert -I https://ci.monarchinitiative.org/view/pipelines/job/hpo-pipeline-dev2/lastSuccessfulBuild/artifact/hp.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/cl.owl: 
	$(ROBOT) convert -I https://ci.monarchinitiative.org/view/pipelines/job/cl_pipeline/lastSuccessfulBuild/artifact/cl.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/chr.owl: 
	$(ROBOT) convert -I https://raw.githubusercontent.com/monarch-initiative/monochrom/master/chr.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/upheno2.owl: 
	$(ROBOT) -vv merge -I https://ci.monarchinitiative.org/view/pipelines/job/upheno2/lastSuccessfulBuild/artifact/src/curation/upheno-release/all/upheno_all_with_relations.owl \
	remove --term-file src/remove_terms.txt \
	annotate --link-annotation http://purl.obolibrary.org/obo/IAO_0000700 http://purl.obolibrary.org/obo/UPHENO_0001001 -o $@.tmp.owl && mv $@.tmp.owl $@
	
ontologies/upheno_patterns.owl:
	$(ROBOT) convert -I https://raw.githubusercontent.com/obophenotype/upheno/master/src/patterns/pattern.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/mondo_patterns.owl:
	$(ROBOT) convert -I https://raw.githubusercontent.com/monarch-initiative/mondo/master/src/patterns/pattern.owl -o $@.tmp.owl && mv $@.tmp.owl $@

#ontologies/monarch.owl:
#	$(ROBOT) convert -I https://ci.monarchinitiative.org/view/pipelines/job/monarch-owl-pipeline/lastSuccessfulBuild/artifact/src/ontology/mo.owl -o $@.tmp.owl && mv $@.tmp.owl $@
