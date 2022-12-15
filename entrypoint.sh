#!/bin/sh

set -xe

check_all_certs_missing() {
	! ls *.pem >/dev/null 2>&1
}

generate_certs() {
	echo generating certs...
	(
		umask 077
		mkdir /tmp/pki
		cp /usr/share/taskd/generate* /tmp/pki

		cd /tmp/pki

		echo "cn = ${TASKDHOSTNAME}" >> ca.info
		echo "expiration_days = -1" >> ca.info
		echo "ca" >> ca.info
		certtool --generate-privkey --bits=4096 --outfile=ca.key.pem
		certtool --generate-self-signed --load-privkey ca.key.pem --template ca.info --outfile ca.cert.pem
		rm ca.info

		echo "cn = ${TASKDHOSTNAME}" >> server.info
		echo "expiration_days = -1" >> server.info
		echo "tls_www_server" >> server.info
		echo "encryption_key" >> server.info
		echo "signing_key" >> server.info
		certtool --generate-privkey --bits=4096 --outfile=server.key.pem
		certtool --generate-self-signed --load-privkey server.key.pem --template server.info --load-ca-privkey ca.key.pem --outfile server.cert.pem
		rm server.info


		echo "expiration_days = -1" >> crl.info
		certtool --generate-crl --load-ca-privkey ca.key.pem --load-ca-certificate ca.cert.pem --template crl.info --outfile server.crl.pem
		rm crl.info

		cp *pem	${TASKDDATA}
	)
}

check_all_certs_present() {
	for cert; do
		if ! [ -r "${cert}.pem" ]; then
			echo "${cert}.pem" missing
			echo Abort
			exit 1
		fi
		taskd config --quiet --force "${cert}" "${cert}.pem"
	done
}

init() {
	(
		cd "$TASKDDATA"
		if ! [ -w config ]; then
			taskd init
		fi
		
		# to not overwrite anything only generate certs if no files are present
		check_all_certs_missing && generate_certs 

		check_all_certs_present server.cert server.key server.crl ca.cert
		taskd config --quiet server ":::$TASKDPORT"
		taskd config --quiet pid ""
		taskd config --quiet log -
	)
}

init

# print the config
taskd config

exec /usr/libexec/catatonit/catatonit $*
