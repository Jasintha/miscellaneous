#!/bin/bash
 
#Required
serial=$1
commonname=$serial
 
#Change to your company details
country=LK
state=WP
locality=CL
organization=wso2.com
organizationalunit=IT
email=administrator@wso2.com

#Optional
password=dummypassword

#CA information
ca_public_path=./ca_cert.pem
ca_private_path=./ca_private.pem
certificate_upload_ep='https://localhost:9443/api/certificate-mgt/v1.0/admin/certificates'
access_token_header='Authorization: Bearer a544fd77-9ca8-326e-a0ca-014f1567562d'

 
if [ -z "$serial" ]
then
    echo "Argument not present."
    echo "Useage $0 [common name]"
 
    exit 99
fi
 
echo "Generating key request for $serial"
 

#Generate a key
openssl genrsa -out $serial.key 2048 -noout
 
 
#Create the request
echo "Creating CSR"
openssl req -new -key $serial.key -out $serial.csr \
    -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
 
echo "---------------------------"
echo "-----Below is your CSR-----"
echo "---------------------------"
echo
cat $serial.csr
 
echo
echo "---------------------------"
echo "-----Below is your Key-----"
echo "---------------------------"
cat $serial.key


#Sign the CSR file with the CA private key to generate the client certificate
echo "Sign the CSR file with the CA private key to generate the client certificate"
openssl x509 -req -days 730 -in client.csr -CA $ca_public_path -CAkey $ca_private_path -set_serial $serial -out $serial.crt


echo "Convert the client certificate to the .pem format for future use."
openssl x509 -in $serial.crt -out $serial.pem

#Create payload to upload the certificate
echo "Convert the client certificate to into base64 format"
pem=$(cat client.pem | base64)
payload=$(echo -e "[ {\"serial\":\""$serial"\", \"pem\":\""$pem"\", \"tenantId \":\""0"\"} ]")

echo "upload the certificate into remote server\n\n"


curl -X POST --header 'Content-Type: application/json' --header 'Accept: text/html' --header "$access_token_header" -d "$payload" $certificate_upload_ep -k -v

echo $payload
#curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d $pem $certificate_upload_ep

#Todo : Copy private certificate into device 
#Todo : Get serial from device 