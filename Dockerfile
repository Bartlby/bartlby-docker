FROM debian
#docker run -p 49080:80 -p 49022:22 -p 49030:9030 -p 49040:9040  -name "bartlbycore" -d bartlby
#docker stop bartlbycore
#docker start bartlbycore


##update 11

ADD deploy.sh /opt/bartlby/deploy.sh
RUN chmod +x /opt/bartlby/deploy.sh
RUN /opt/bartlby/deploy.sh system_setup



CMD ["/opt/bartlby/deploy.sh", "app_start"]

EXPOSE 80 22 9030 9031
