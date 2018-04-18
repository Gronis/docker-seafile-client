FROM debian:wheezy-slim

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8756C4F765C9AC3CB6B85D62379CE192D401AB61 && \
    echo deb http://deb.seadrive.org wheezy main | tee /etc/apt/sources.list.d/seafile.list && \
    apt-get update -y && \
    apt-get install -y seafile-cli procps curl grep && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /seafile-client

COPY start.sh /seafile-client/start.sh

RUN chmod +x /seafile-client/start.sh && \
    useradd -U -d /seafile-client -s /bin/bash seafile && \
    usermod -G users seafile && \
    chown seafile:seafile -R /seafile-client && \
    su - seafile -c "seaf-cli init -d /seafile-client"

CMD ["./start.sh"]
