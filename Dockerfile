
FROM debian:jessie
# FROM buildpack-deps:jessie
  # to much useless stuff inside,
  # and is also FROM debian:latest
# FROM python:3.2
  # A user can add this later. If wanted.

ENV TG_USER telegram
ENV TG_HOME /home/$TG_USER
ENV COMMAND python

# set user/group IDs
RUN groupadd -r "$TG_USER" --gid=999 && useradd -r -g "$TG_USER" --uid=999 "$TG_USER"


# Base
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive && apt-get install --no-install-recommends --yes \
		ca-certificates make git gcc libreadline-dev libconfig-dev libssl-dev lua5.2 liblua5.2-dev libevent-dev libjansson-dev libpython-dev make   \
    zlib1g-dev libncurses5-dev \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists \
  && echo "[http]\n\tsslVerify = true\n\tslCAinfo = /etc/ssl/certs/ca-certificates.crt\n" >> ~/.gitconfig
  # the install ca-certificates and adding "slCAinfo = /etc/ssl/certs/ca-certificates.crt" to .gitconfig
  # fixed tg cloning via git with the error:
  ## fatal: unable to access 'https://github.com/vysheng/tg.git/': Problem with the SSL CA cert (path? access rights?)

RUN mkdir "$TG_HOME"

RUN git clone --recursive https://github.com/vysheng/tg.git "$TG_HOME"/tg
WORKDIR "$TG_HOME"/tg
RUN git submodule update --init --recursive

RUN ./configure --disable-liblua
RUN make 
ENV TG_CLI "$TG_HOME"/tg/bin/telegram-cli

ENV PATH "$TG_HOME"/tg/bin/:$PATH
ENV TG_PUBKEY "$TG_HOME"/tg/tg-server.pub
ENV KILLCACHE "YES PLZ! NAO!" # I just comment this out some time to trigger a rebuild from here on.
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENV CLI_DATA $TG_USER/.telegram-cli
ENTRYPOINT ["/entrypoint.sh"]

CMD ["bash"]

VOLUME $TG_HOME
VOLUME $CLI_DATA
