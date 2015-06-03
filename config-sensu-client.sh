# Jim Sander - Custom Client Configuration

# Build the template client config file 



# -------------------------------- #
# json file parser
# -------------------------------- #
## Looked @ JQ, but didn't want another dependency
## There's also a good awk parser, but I need to reel back the scope
## Given the scope of this script, not worried about variable pathing or unique names
##  e.g.  rabbitmq->client->name... for now there's no other variable for 'name'

export DEBUG="set -x"
function jupdate (){
    $DEBUG
    var=$1; val=$2 file=$3
    [ -z "$file" ] && file=$sensu_client_config
    if [ ! -f "$file" ]; then echo "File $file not found"; exit 1; fi
    if [ -z "$var" ]; then echo "No Variable provided"; exit 1; fi
    if [ -z "$val" ]; then echo "No Value provided"; exit 1; fi
    sed -i "s/\(\"${var}\":.*\"\)\(.*\)\(\"[,$]*\)/\1${val}\3/" $file 
} ## End of jupdate

# -------------------------------- #
# Update the rabbitmq stanza
# -------------------------------- #
## sed "s/\(\"host\":.*\"\).*\(.*\",\)/\1${rabbitmq_ip}\2/" config.json
function updateRabbitClient () {
	$DEBUG
	docker_rabbitmq=`docker ps | grep 'sensudocker_rabbitmq:latest' | awk '{ print $1 }'`
	if [ -n "$docker_rabbitmq" ]; then
		rabbitmq_ip=`docker inspect -f "{{.NetworkSettings.IPAddress}}" $docker_rabbitmq`
		jupdate "host" "$rabbitmq_ip" 
	
		export `docker inspect -f "{{ .Config.Env }}" $docker_rabbitmq  | sed 's/^\[//g' | sed 's/\]$//g'  | sed 's/ /\n/g' | grep RABBITMQ_PASSWD`
	
		if [ -n "$RABBITMQ_PASSWD" ]; then
			jupdate "password" "$RABBITMQ_PASSWD" 
		fi
	fi
} ## End updateRabbitClient


# -------------------------------- #
# Update the client stanza
# -------------------------------- #
function updateClient () {
	$DEBUG
	jupdate "address" `hostname`
	jupdate "name" "JDS-Sensu"
	jupdate subscriptions "default\", \"dcm-single-node"
} # End updateClient 

# -------------------------------- #
# Get Client Certs
# -------------------------------- #
## Assuming the docker container `sensudocker_sensu:latest` is local and the volume '/usr/local/etc/sensu-docker/client' is shared
function updateCert () {
	$DEBUG
	rpath=/usr/local/etc/sensu-docker/client
	dpath=/etc/sensu/ssl
	for certfile in key.pem cert.pem; do
		if [ -f "${rpath}/$certfile" ]; then
			cp ${rpath}/$certfile $dpath || rc=1
		else 
			docker_sensu=`docker ps | grep 'sensudocker_sensu:latest' | awk '{ print $1 }'`
			if [ -n "$docker_sensu" ]; then
				docker exec -i -t $docker_sensu cat ${rpath}/$certfile > ${dpath}/$certfile || rc=1
			else
				rc=1
			fi
		fi
	done
	return $rc
} ## End updateCert 

## ========================== ##
## Example client config.json
## ========================== ##
function createJson () {
cat << EOF > $sensu_client_config
{
  "rabbitmq": {
    "ssl": {
      "cert_chain_file": "/etc/sensu/ssl/cert.pem",
      "private_key_file": "/etc/sensu/ssl/key.pem"
    },
    "port": 5671,
    "host": "%RABBITMQ_ADDR_OR_IP%",
    "user": "sensu",
    "password": "%RABBITMQ_PASSWD%",
    "vhost": "/sensu"
  },
  "client": {
    "name": "%NODE_NAME%",
    "address": "%HOSTNAME%",
    "subscriptions": [ "default" ]
  }
}
EOF

} ## End createJson

## ========================== ##
## Install the client
## ========================== ##


# -------------------------------- #
##             MAIN               ##
# -------------------------------- #
sensu_client_config=/etc/sensu/conf.d/config.json
if [ ! -f "$sensu_client_config" ] ; then createJson; fi

for func in updateClient updateRabbitClient updateCert; do
	printf "Run     %16s \n" $func 
	$func
	printf "Status: %16s %s \n" $func `[ $? -eq 0 ] && echo "COMPLETED" || echo "FAILED"`
done

service sensu-client restart || service sensu-client start 

exit $?


