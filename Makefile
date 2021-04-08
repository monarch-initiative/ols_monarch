URIBASE = http://purl.obolibrary.org/obo
ONTS = upheno2 geno upheno_patterns hp chr mondo_patterns mondo-harrisons-view mondo mondo-issue-2632
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

ontologies/mondo-issue-%.owl:
	mkdir -p github && mkdir -p github/mondo-issue-$* && rm -rf github/mondo-issue-$*/*
	cd github/mondo-issue-$* && git clone --depth 1 https://github.com/monarch-initiative/mondo.git -b issue-$* 
	$(ROBOT) merge -i github/mondo-issue-$*/mondo/src/ontology/mondo-edit.obo --catalog github/mondo-issue-$*/mondo/src/ontology/catalog-v001.xml reason --reasoner ELK -o $@.tmp.owl && mv $@.tmp.owl $@
	echo "  - id: mondo-issue-$*" >> ols/ols-config.yaml
	echo "    preferredPrefix: MONDO_ISSUE_$*" >> ols/ols-config.yaml
	echo "    title: Mondo Disease Ontology - Issue $* (Developmental Snapshot)" >> ols/ols-config.yaml
	echo "    uri: http://purl.obolibrary.org/obo/mondo/mondo-issue-$*.owl" >> ols/ols-config.yaml
	echo "    definition_property:" >> ols/ols-config.yaml
	echo "      - http://purl.obolibrary.org/obo/IAO_0000115" >> ols/ols-config.yaml
	echo "    reasoner: EL" >> ols/ols-config.yaml
	echo "    oboSlims: false" >> ols/ols-config.yaml
	echo "    ontology_purl : file:/opt/ols/$@" >> ols/ols-config.yaml

ontologies/%.owl: 
	$(ROBOT) convert -I $(URIBASE)/$*.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/hp.owl: 
	$(ROBOT) convert -I https://ci.monarchinitiative.org/view/pipelines/job/hpo-pipeline-dev2/lastSuccessfulBuild/artifact/hp.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/mondo.owl: 
	$(ROBOT) convert -I https://ci.monarchinitiative.org/view/pipelines/job/mondo-build/lastSuccessfulBuild/artifact/src/ontology/mondo.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/mondo-harrisons-view.owl: 
	$(ROBOT) convert -I https://ci.monarchinitiative.org/view/pipelines/job/mondo-build/lastSuccessfulBuild/artifact/src/ontology/modules/mondo-harrisons-view.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/chr.owl: 
	$(ROBOT) convert -I https://raw.githubusercontent.com/monarch-initiative/monochrom/master/chr.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/upheno2.owl: 
	$(ROBOT) -vv merge -I https://data.monarchinitiative.org/upheno2/current/upheno-release/all/upheno_all_with_relations.owl \
	remove --term-file src/remove_terms.txt \
	annotate --link-annotation http://purl.obolibrary.org/obo/IAO_0000700 http://purl.obolibrary.org/obo/UPHENO_0001001 -o $@.tmp.owl && mv $@.tmp.owl $@
	
ontologies/upheno_patterns.owl:
	$(ROBOT) convert -I https://raw.githubusercontent.com/obophenotype/upheno/master/src/patterns/pattern.owl -o $@.tmp.owl && mv $@.tmp.owl $@

ontologies/mondo_patterns.owl:
	$(ROBOT) convert -I https://raw.githubusercontent.com/monarch-initiative/mondo/master/src/patterns/pattern.owl -o $@.tmp.owl && mv $@.tmp.owl $@

#ontologies/monarch.owl:
#	$(ROBOT) convert -I https://ci.monarchinitiative.org/view/pipelines/job/monarch-owl-pipeline/lastSuccessfulBuild/artifact/src/ontology/mo.owl -o $@.tmp.owl && mv $@.tmp.owl $@

