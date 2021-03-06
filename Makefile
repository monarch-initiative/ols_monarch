URIBASE = http://purl.obolibrary.org/obo
ONTS = upheno2 geno upheno_patterns hp chr mondo_patterns mondo-harrisons-view mondo mondo-issue-2632 uberon-human-view
#monarch
ONTFILES = $(foreach n, $(ONTS), ontologies/$(n).owl)
VERSION = "0.0.3" 
IM=monarchinitiative/monarch-ols
OLSCONFIG=/opt/ols/ols-config.yaml

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
	$(ROBOT) merge -i github/mondo-issue-$*/mondo/src/ontology/mondo-edit.obo --catalog github/mondo-issue-$*/mondo/src/ontology/catalog-v001.xml remove --select ontology reason --reasoner ELK -o $@.tmp.owl && mv $@.tmp.owl $@

# echo "  - id: mondo_issue$*" >> $(OLSCONFIG)
# echo "    preferredPrefix: MONDO_ISSUE$*" >> $(OLSCONFIG)
# echo "    title: Mondo Disease Ontology - Issue $* (Developmental Snapshot)" >> $(OLSCONFIG)
# echo "    uri: http://purl.obolibrary.org/obo/mondo/mondo-issue-$*.owl" >> $(OLSCONFIG)
# echo "    definition_property:" >> $(OLSCONFIG)
# echo "      - http://purl.obolibrary.org/obo/IAO_0000115" >> $(OLSCONFIG)
# echo "    reasoner: EL" >> $(OLSCONFIG)
# echo "    oboSlims: false" >> $(OLSCONFIG)
# echo "    ontology_purl : file:/opt/ols/$@" >> $(OLSCONFIG)

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

HUMAN_VIEW=http://purl.obolibrary.org/obo/uberon/subsets/human-view.owl

ontologies/uberon-human-view.owl:
	$(ROBOT) convert -I $(HUMAN_VIEW) -o $@.tmp.owl && mv $@.tmp.owl $@


#ontologies/monarch.owl:
#	$(ROBOT) convert -I https://ci.monarchinitiative.org/view/pipelines/job/monarch-owl-pipeline/lastSuccessfulBuild/artifact/src/ontology/mo.owl -o $@.tmp.owl && mv $@.tmp.owl $@

