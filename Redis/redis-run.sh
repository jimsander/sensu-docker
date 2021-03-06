mkdir -p /etc/sensu/ssl
cp /tmp/ssl_certs/client/cert.pem /tmp/ssl_certs/client/key.pem /etc/sensu/ssl

cat << EOF > /etc/sensu/config.json
{
  "rabbitmq": {
    "ssl": {
      "cert_chain_file": "/usr/local/etc/sensu-docker/client/cert.pem",
      "private_key_file": "/usr/local/etc/sensu-docker/client/key.pem"
    },
    "port": 5671,
    "host": "$RABBITMQ_PORT_5671_TCP_ADDR",
    "user": "sensu",
    "password": "$RABBITMQ_PASSWD",
    "vhost": "/sensu"
  },
  "client": {
    "name": "sensu-redis",
    "address": "$HOSTNAME",
    "subscriptions": [ "default", "sensu-redis" ]
  }
}
EOF

/usr/bin/supervisord
