# Environment
OPENSSL   = /usr/bin/openssl
RM_F      = rm -f 
INDEX     = index.txt
INDEXATTR = index.txt.attr
SERIAL    = serial
DATABASE  = $(INDEX) $(INDEXATTR) $(SERIAL)

# Root CA
ROOTKEY  = CA.key
ROOTCRT  = CA.crt
ROOTBITS = 4096
ROOTDAYS = 3650
ROOTCONF = openssl-root.cnf

# Intermediate CA
INTERKEY  = CA_Intermediary.key
INTERCRT  = CA_Intermediary.crt
INTERCSR  = CA_Intermediary.csr
INTERBITS = 4096
INTERDAYS = 3650
INTERCONF = openssl-inter.cnf

# Server Cert
SERVERKEY  = ServerCert_signedByCAIntermediary.key
SERVERCRT  = ServerCert_signedByCAIntermediary.crt
SERVERCSR  = ServerCert_signedByCAIntermediary.csr
SERVERBITS = 2048
SERVERDAYS = 375

# Client Cert
CLIENTKEY  = ClientCert_signedByCAIntermediary.key
CLIENTCRT  = ClientCert_signedByCAIntermediary.crt
CLIENTCSR  = ClientCert_signedByCAIntermediary.csr
CLIENTP12  = ClientCert_signedByCAIntermediary.p12
CLIENTBITS = 2048
CLIENTDAYS = 375

# Trust chain
CATRUST     = ca-chain.crt
SERVERTRUST = server-chain.crt

# Test Client / Server
SERVERADDR   = localhost
SERVERPORT   = 44430
SERVERDEPTH  = 3
SERVERCAFILE = $(SERVERTRUST)
CLIENTCAFILE = $(SERVERTRUST)
