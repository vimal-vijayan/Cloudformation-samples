FROM prom/prometheus
EXPOSE 9090
COPY ./prometheus.yml /etc/prometheus/prometheus.yml
ENTRYPOINT ["/bin/prometheus"]
CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
             "--storage.tsdb.path=/prometheus", \
             "--web.console.libraries=/usr/share/prometheus/console_libraries", \
             "--web.console.templates=/usr/share/prometheus/consoles" ]
#CMD ["--config.file=/etc/prometheus/prometheus.yml"]
