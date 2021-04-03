FROM ebispot/ols:3.3.6

ENV OLS_HOME /opt/ols
ENV JAVA_OPTS "-Xmx50g"
ENV SOLR_VERSION 5.5.3

ADD ols/ols-config.yaml ${OLS_HOME}
ADD ols/logo-monarch.jpg ${OLS_HOME}/web-custom/
#ADD ols/obo-config.yaml ${OLS_HOME}	

RUN mkdir ${OLS_HOME}/ontologies
RUN mkdir /tools

###### ROBOT ######
ENV ROBOTVERSION v1.8.1
ARG ROBOT_JAR=https://github.com/ontodev/robot/releases/download/$ROBOTVERSION/robot.jar
ENV ROBOT_JAR ${ROBOT_JAR}
ENV ROBOT=/tools/robot
RUN pwd
RUN wget $ROBOT_JAR -O /tools/robot.jar && \
    wget https://raw.githubusercontent.com/ontodev/robot/$ROBOTVERSION/bin/robot -O /tools/robot && \
    chmod +x /tools/robot && \
    chmod +x /tools/robot.jar

## Prepare configuration files
ADD ols/application.properties ${OLS_HOME}
ADD src ${OLS_HOME}/src
ADD Makefile ${OLS_HOME}
RUN ls -l ${OLS_HOME}

## Start MongoDB and 
### Load configuration into MongoDB
RUN mongod --smallfiles --fork --logpath /var/log/mongodb.log \ 
    && cd ${OLS_HOME} \ 
    && java -jar ${OLS_HOME}/ols-config-importer.jar \
    && sleep 10

## Preprocess ontologies
RUN date
RUN apk add --update make
RUN cd ${OLS_HOME} && make ontologies -B

## Start MongoDB and SOLR
## Build/update the indexes
RUN mongod --smallfiles --fork --logpath /var/log/mongodb.log \
  && /opt/solr-${SOLR_VERSION}/bin/solr -Dsolr.solr.home=${OLS_HOME}/solr-5-config/ -Dsolr.data.dir=${OLS_HOME} \  
  && java ${JAVA_OPTS} -Dobo.db.xrefs=https://raw.githubusercontent.com/geneontology/go-site/a94d68f4e57264db2ff3692866a680c3fb9dda9d/metadata/db-xrefs.yaml -Dols.home=${OLS_HOME} -jar ${OLS_HOME}/ols-indexer.jar  

## Expose the tomcat port 
EXPOSE 8080

CMD cd ${OLS_HOME} \
    && mongod --smallfiles --fork --logpath /var/log/mongodb.log \
    && /opt/solr-${SOLR_VERSION}/bin/solr -Dsolr.solr.home=${OLS_HOME}/solr-5-config/ -Dsolr.data.dir=${OLS_HOME} \
    && java -jar -Dols.home=${OLS_HOME} ols-boot.war

