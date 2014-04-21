/System/Library/OpenSSL/misc/CA.pl -newreq
rob@Laura: ~/Source/home/minimal-rack/ssl/ > cat newcert.pem demoCA/cacert.pem > clientsigned-cert.pem
rob@Laura: ~/Source/home/minimal-rack/ssl/ > openssl rsa -in newkey.pem -out clientsigned-key.prm
openssl ca -config /System/Library/OpenSSL/openssl.cnf -days 180 -spkac dynamic-client/1.spkac -out dynamic-client/1-signed -notext
10009  /System/Library/OpenSSL/misc/CA.pl -newreq
10010  /System/Library/OpenSSL/misc/CA.pl -sign
10011  mkdir server
10012  cat newcert.pem demoCA/cacert.pem > server/laura-cert.pem
10013  openssl rsa -in newkey.pem -out server/laura-key.pem
10014  ls lo*
10015  cd server/
10016  mv laura-cert.pem laura-chain.pem
10017  cd ..
10018  cp newcert.pem server/laura-cert.pem
10019  openssl x509 -in server/laura-chain.pem -inform pem -out server/laura-chain.der -outform der


10026  /System/Library/OpenSSL/misc/CA.pl -newreq
10027  /System/Library/OpenSSL/misc/CA.pl -sign
10029  openssl rsa -in newkey.pem -out clientkeys/robsphone-key.pem
10030  mv newcert.pem clientkeys/robsphone-cert.pem
10031  mv newreq.pem clientkeys/robsphone-req.pem
10032  cd clientkeys/
10034  openssl pkcs12 -export -in robsphone-cert.pem -inkey robsphone-key.pem -out robsphone.p12


