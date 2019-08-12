# Introduction

This Makefile helps in the creation of a Root Certificate Authority (CA), an 
Intermediary CA - which is used to sign server and client certificates.  It 
also can create client and server keys and certificates as well as test 
server and client interaction with the OpenSSL `s_server` and `s_client` 
commands.

----

# Notes

In the `openssl req` commands to create the Certificate Signing Request (CSR), 
make sure to use __different__ Common Names (CN) for each certificate 
(i.e., Root, Intermediary, client and server)!

----

# Usage

Get detailed usage information:

    make

To simply create a mutual authentication client / server pair:

    make mutual-auth-pair

To clean up everything and start again:

    make realclean

----

# Details

## Prep Environment

    touch index.txt
    echo 1000 > serial

## CA Certificate

    openssl genrsa -out CA.key 4096
    openssl req -config openssl-root.cnf -new -sha256 -key CA.key -x509 -days 3650  -extensions v3_ca -out CA.crt

## Intermediary CA Certificate

    openssl genrsa -out CA_Intermediary.key 4096
    openssl req -config openssl-inter.cnf -new -sha256 -key CA_Intermediary.key -out CA_Intermediary.csr
    openssl ca -config openssl-root.cnf -extensions v3_intermediate_ca -days 3650 -notext -in CA_Intermediary.csr -out CA_Intermediary.crt

## Server Certificate Signed by Intermediary CA

    openssl genrsa -out ServerCert_signedByCAIntermediary.key 2048
    openssl req -config openssl-inter.cnf -new -sha256 -key ServerCert_signedByCAIntermediary.key -out ServerCert_signedByCAIntermediary.csr
    openssl ca -config openssl-inter.cnf -extensions server_cert -days 375 -notext -in ServerCert_signedByCAIntermediary.csr -out ServerCert_signedByCAIntermediary.crt

## Create Trust Chain

    cat CA.crt CA_Intermediary.crt ServerCert_signedByCAIntermediary.crt > server-chain.crt
    openssl verify -CAfile server-chain.crt ServerCert_signedByCAIntermediary.crt

## Client Certificate Signed by Intermediary CA

    openssl genrsa -out ClientCert_signedByCAIntermediary.key 2048
    openssl req -config openssl-inter.cnf -new -sha256 -key ClientCert_signedByCAIntermediary.key -out ClientCert_signedByCAIntermediary.csr
    openssl ca -config openssl-inter.cnf -extensions usr_cert -days 375 -notext -in ClientCert_signedByCAIntermediary.csr -out ClientCert_signedByCAIntermediary.crt

## Testing

    openssl s_server -CAfile server-chain.crt -key ServerCert_signedByCAIntermediary.key -cert ServerCert_signedByCAIntermediary.crt -accept 44430 -www -Verify 3

    openssl s_client -CAfile server-chain.crt -key ClientCert_signedByCAIntermediary.key -cert ClientCert_signedByCAIntermediary.crt -connect localhost:44430

----

# References

https://jamielinux.com/docs/openssl-certificate-authority/index.html

https://community.axway.com/s/feed/0D52X000065Ykx2SAC
