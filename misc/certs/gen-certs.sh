#!/bin/bash

# ================================
# 1. Generate the private key for Root CA
# ================================
# Generate the private key for the Root CA using ECC (secp384r1 curve)
# Store in the certs directory, .key files will be ignored by git
openssl ecparam -genkey -name secp384r1 -out certs/ecc-ca.key

# ================================
# 2. Generate the certificate for Root CA
# ================================
# Generate the self-signed Root CA certificate (valid for 10 years)
# This will create `ecc-ca.crt` using the `ecc-ca.key`
openssl req -x509 -new -SHA512 -key certs/ecc-ca.key -subj "/CN=MilanSue's Root CA 1" -days 3650 -out certs/ecc-ca.crt

# ================================
# 3. Generate the private key for the server
# ================================
# Generate the private key for the server using ECC (secp384r1 curve)
# Store in the certs directory
openssl ecparam -genkey -name secp384r1 -out certs/ecc-server.key

# ================================
# 4. Generate the Certificate Signing Request (CSR) for the server
# ================================
# Generate the CSR for the server certificate using the private key and config file
openssl req -new -SHA512 -key certs/ecc-server.key -out certs/ecc-server.csr -config ecc-csr.conf

# ================================
# 5. Sign the server certificate with the Root CA's certificate
# ================================
# Sign the server certificate (`ecc-server.csr`) using the Root CA's private key (`ecc-ca.key`) and certificate (`ecc-ca.crt`)
openssl x509 -req -SHA512 -in certs/ecc-server.csr -CA certs/ecc-ca.crt -CAkey certs/ecc-ca.key \
  -CAcreateserial -out certs/ecc-server.crt -days 3650 \
  -extensions v3_ext -extfile ecc-csr.conf

# ================================
# 6. Display certificate information
# ================================
# Display the details of the Root CA certificate
openssl x509 -noout -text -in certs/ecc-ca.crt

# Display the details of the server certificate
openssl x509 -noout -text -in certs/ecc-server.crt
