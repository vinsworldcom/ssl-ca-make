include config.mk

all:
	@echo
	@echo "SSL Certificate Authority Helper"
	@echo
	@echo "Using OpenSSL: $(OPENSSL)"
	$(OPENSSL) version
	@echo
	@echo "Usage:"
	@echo "    make target"
	@echo
	@echo "Where target is:"
	@echo "  New Certificates:"
	@echo "    new-root-ca      - Create Root CA key and cert"
	@echo "    new-inter-ca     - Create Intermediate CA key and cert"
	@echo "    new-server-cert  - Create a new server key and cert signed by Inter. CA"
	@echo "    new-client-cert  - Create a new client key and cert signed by Inter. CA"
	@echo
	@echo "  Shortcuts:"
	@echo "    mutual-auth-pair - Create new-server-cert and new-client-cert"
	@echo "    sign-inter-ca    - Sign a provided Inter. CA CSR"
	@echo "    new-server-csr   - Create a server key and CSR"
	@echo "    new-client-csr   - Create a client key and CSR"
	@echo "    sign-server-cert - Sign a provided server CSR"
	@echo "    sign-client-cert - Sign a provided client CSR"
	@echo "    new-client-p12   - Create a PKCS12 from client key, cert and CA chain"
	@echo
	@echo "  Clean:"
	@echo "    clean-client     - remove all client keys and certs"
	@echo "    clean-server     - remove all server keys and certs"
	@echo "    clean            - remove all keys and certs below Inter. CA"
	@echo "    clean-inter      - remove Inter. CA and all keys and certs below"
	@echo "    realclean        - DELETE ALL KEYS AND CERTS INCLUDING ROOT!!!"
	@echo
	@echo "  Testing:"
	@echo "    server           - Test Certificates wtih OpenSSL s_server"
	@echo "    client           - Connect to OpenSSL s_server with s_client"
	@echo

.PHONY: all clean-client clean-server clean clean-inter realclean \
        mutual-auth-pair sign-inter-ca new-server-csr new-client-csr \
        sign-server-cert sign-client-cert client-p12 \
        new-root-ca new-inter-ca new-server-cert new-client-cert \
        server client

########################################
# Clean
clean-client:
	$(RM_F) $(CLIENTKEY) $(CLIENTCSR) $(CLIENTCRT) $(CLIENTP12)

clean-server:
	$(RM_F) $(SERVERKEY) $(SERVERCSR) $(SERVERCRT) $(SERVERTRUST)

clean: clean-client clean-server

clean-inter: clean
	$(RM_F) $(INTERKEY) $(INTERCRT) $(INTERCSR) $(CATRUST) index.* serial* *.pem

realclean: clean-inter
	$(RM_F) $(ROOTKEY) $(ROOTCRT)

########################################
# Shortcuts
mutual-auth-pair: new-server-cert new-client-cert $(SERVERTRUST)

sign-inter-ca: new-root-ca $(INTERCRT)

new-server-csr: $(SERVERKEY) $(SERVERCSR)

new-client-csr: $(CLIENTKEY) $(CLIENTCSR)

sign-server-cert: new-root-ca new-inter-ca $(SERVERCRT)

sign-client-cert: new-root-ca new-inter-ca $(CLIENTCRT)

new-client-p12: new-root-ca new-inter-ca $(CATRUST) $(CLIENTKEY) $(CLIENTCRT) $(CLIENTP12)

########################################
# Environment
$(INDEX):
	@echo
	@echo Creating Index...
	touch $(INDEX)

$(INDEXATTR):
	@echo
	@echo Creating Index Attributes...
	touch $(INDEXATTR)

$(SERIAL):
	@echo
	@echo Creating Serial...
	echo 1000 > $(SERIAL)

########################################
# Root CA
new-root-ca: $(ROOTCRT)

$(ROOTCRT): $(ROOTKEY)
	@echo
	@echo Creating Root CA certificate...
	$(OPENSSL) req -config $(ROOTCONF) -new -sha256 -key $(ROOTKEY) -x509 -days $(ROOTDAYS)  -extensions v3_ca -out $(ROOTCRT)

$(ROOTKEY):
	@echo
	@echo Creating Root CA key...
	$(OPENSSL) genrsa -out $(ROOTKEY) $(ROOTBITS)

########################################
# Intermediate CA
new-inter-ca: $(DATABASE) new-root-ca $(INTERKEY) $(INTERCRT) $(CATRUST)

$(INTERCRT): $(INTERCSR)
	@echo
	@echo Creating Intermediate CA certificate...
	$(OPENSSL) ca -config $(ROOTCONF) -extensions v3_intermediate_ca -days $(INTERDAYS) -notext -in $(INTERCSR) -out $(INTERCRT)

$(INTERCSR):
	@echo
	@echo Creating Intermediate CA certificate signing request...
	$(OPENSSL) req -config $(INTERCONF) -new -sha256 -key $(INTERKEY) -out $(INTERCSR)

$(INTERKEY):
	@echo
	@echo Creating Intermediate CA key...
	$(OPENSSL) genrsa -out $(INTERKEY) $(INTERBITS)

########################################
# Server
new-server-cert: new-root-ca new-inter-ca $(SERVERKEY) $(SERVERCRT)

$(SERVERCRT): $(SERVERCSR)
	@echo
	@echo Creating Server certificate...
	$(OPENSSL) ca -config $(INTERCONF) -extensions server_cert -days $(SERVERDAYS) -notext -in $(SERVERCSR) -out $(SERVERCRT)

$(SERVERCSR):
	@echo
	@echo Creating Server certificate signing request...
	$(OPENSSL) req -config $(INTERCONF) -new -sha256 -key $(SERVERKEY) -out $(SERVERCSR)

$(SERVERKEY):
	@echo
	@echo Creating Server key...
	$(OPENSSL) genrsa -out $(SERVERKEY) $(SERVERBITS)

########################################
# Client
new-client-cert: new-root-ca new-inter-ca $(CLIENTKEY) $(CLIENTCRT)

$(CLIENTCRT): $(CLIENTCSR)
	@echo
	@echo Creating Client certificate...
	$(OPENSSL) ca -config $(INTERCONF) -extensions usr_cert -days $(CLIENTDAYS) -notext -in $(CLIENTCSR) -out $(CLIENTCRT)

$(CLIENTCSR):
	@echo
	@echo Creating Client certificate signing request...
	$(OPENSSL) req -config $(INTERCONF) -new -sha256 -key $(CLIENTKEY) -out $(CLIENTCSR)

$(CLIENTKEY):
	@echo
	@echo Creating Client key...
	$(OPENSSL) genrsa -out $(CLIENTKEY) $(CLIENTBITS)

$(CLIENTP12):
	@echo
	@echo Creating Client PKCS12...
	$(OPENSSL) pkcs12 -export -out $(CLIENTP12) -inkey $(CLIENTKEY) -in $(CLIENTCRT) -certfile $(CATRUST)

########################################
# Trust chains
$(CATRUST): $(ROOTCRT) $(INTERCRT)
	@echo
	@echo Create CA Trust Chain...
	cat $(ROOTCRT) $(INTERCRT) > $(CATRUST)
	@echo Verify CA Trust Chain...
	$(OPENSSL) verify -CAfile $(CATRUST) $(INTERCRT)

$(SERVERTRUST): $(ROOTCRT) $(INTERCRT) $(SERVERCRT)
	@echo
	@echo Create Server Trust Chain...
	cat $(ROOTCRT) $(INTERCRT) $(SERVERCRT) > $(SERVERTRUST)
	@echo Verify Server Trust Chain...
	$(OPENSSL) verify -CAfile $(SERVERTRUST) $(SERVERCRT)

########################################
# Test
server: new-server-cert $(SERVERTRUST)
	@echo
	@echo Running server at $(SERVERADDR):$(SERVERPORT)...
	$(OPENSSL) s_server -CAfile $(SERVERCAFILE) -key $(SERVERKEY) -cert $(SERVERCRT) -accept $(SERVERPORT) -www -Verify $(SERVERDEPTH)

client: new-client-cert $(SERVERTRUST)
	@echo
	@echo Connecting to server at $(SERVERADDR):$(SERVERPORT)...
	@echo " " | $(OPENSSL) s_client -CAfile $(CLIENTCAFILE) -key $(CLIENTKEY) -cert $(CLIENTCRT) -connect $(SERVERADDR):$(SERVERPORT)
