FROM debian:bullseye-slim

RUN apt-get update && apt-get install procps grep curl -y
RUN curl https://linux-clients.seafile.com/seafile.asc -o /usr/share/keyrings/seafile-keyring.asc
RUN echo deb [arch=amd64 signed-by=/usr/share/keyrings/seafile-keyring.asc] https://linux-clients.seafile.com/seafile-deb/bullseye/ stable main | tee /etc/apt/sources.list.d/seafile.list
RUN apt-get update -y
RUN apt-get install -y seafile-cli
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get clean

RUN mkdir /seafile-state
RUN mkdir /home/seafile

WORKDIR /home/seafile

COPY start.sh /home/seafile/start.sh
RUN chmod +x /home/seafile/start.sh

RUN useradd -U -d /home/seafile -s /bin/bash seafile
RUN usermod -G users seafile
RUN chown seafile:seafile -R /home/seafile

CMD ["./start.sh"]
