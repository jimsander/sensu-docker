FROM ubuntu:trusty
MAINTAINER Jim Sander <jim.sander@enstratius.com>

RUN apt-get update && apt-get install -y curl wget openssl redis-server supervisor

ADD https://raw.githubusercontent.com/jimsander/sensu-docker/compose/support/install-sensu.sh /tmp/
RUN chmod +x /tmp/install-sensu.sh
RUN /tmp/install-sensu.sh

ADD redis-run.sh /tmp/
ADD supervisor.conf /etc/supervisor/conf.d/sensu.conf

CMD /tmp/redis-run.sh
