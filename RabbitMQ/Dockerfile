FROM library/rabbitmq:management
MAINTAINER Jim Sander <jim.sander@enstratius.com>

RUN apt-get update && apt-get install -y curl wget openssl supervisor

ADD https://raw.githubusercontent.com/jimsander/sensu-docker/compose/support/install-sensu.sh /tmp/
RUN chmod +x /tmp/install-sensu.sh
RUN /tmp/install-sensu.sh

ADD rabbitmq-run.sh /tmp/
ADD supervisor.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/tmp/rabbitmq-run.sh"]
