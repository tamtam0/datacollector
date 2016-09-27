FROM streamsets/datacollector:latest
MAINTAINER Tamilselvan Tamilmani
USER root
RUN apk add krb5-libs
USER ${SDC_USER}
