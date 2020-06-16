FROM prometheus:v2.19.0
EXPOSE 9090
RUN mkdir /prometheus-vol
VOLUME /prometheus-vol
COPY . /etc/prometheus/prometheus.yml
ENTRYPOINT ["/bin/prometheus"]
