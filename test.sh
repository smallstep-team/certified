set -e -x

export PATH="$(cd "$(dirname "$0")" && pwd)/bin:$PATH"

#cd "$(mktemp -d)"
#trap "rm -rf \"$PWD\"" EXIT INT QUIT TERM

# Test that you don't need a CA to generate a CSR.
certified-csr C="US" ST="CA" L="San Francisco" O="Certified" CN="No-CA"
openssl req -in "etc/ssl/no-ca.csr" -noout -text |
grep -q "Subject: C=US, ST=CA, L=San Francisco, O=Certified, CN=No-CA"
test ! -f "etc/certs/no-ca.crt"

# Test that you don't needa CA to self-sign a certificate.
certified-crt --self-signed CN="No-CA"
openssl x509 -in "etc/ssl/certs/no-ca.crt" -noout -text |
grep -q "Issuer: CN=No-CA, C=US, L=San Francisco, O=Certified, ST=CA"
openssl x509 -in "etc/ssl/certs/no-ca.crt" -noout -text |
grep -q "Subject: CN=No-CA, C=US, L=San Francisco, O=Certified, ST=CA"

# Test that we can generate a CA even after self-signing a certificate.
certified-ca C="US" ST="CA" L="San Francisco" O="Certified" CN="Certified CA"
openssl x509 -in "etc/ssl/certs/ca.crt" -noout -text |
grep -q "Issuer: C=US, ST=CA, L=San Francisco, O=Certified, CN=Certified CA"
openssl x509 -in "etc/ssl/certs/ca.crt" -noout -text |
grep -q "Subject: C=US, ST=CA, L=San Francisco, O=Certified, CN=Certified CA"

# Test that we can sign a certificate with our CA.
certified CN="Certificate"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "Version: 3"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "Issuer: C=US, ST=CA, L=San Francisco, O=Certified, CN=Certified CA"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "Subject: CN=Certificate, C=US, L=San Francisco, O=Certified, ST=CA"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "Public-Key: (2048 bit)"

# Test that we can't reissue a certificate without revoking it first.
certified CN="Certificate" && false

# Test that we can revoke and reissue a certificate.
certified --revoke CN="Certificate"
openssl crl -in "etc/ssl/crl/ca.crl" -noout -text |
grep -q "Revoked Certificates:"
certified CN="Certificate"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "Subject: CN=Certificate, C=US, L=San Francisco, O=Certified, ST=CA"

# Test that we can generate 4096-bit certificates.
certified --bits="4096" CN="4096"
openssl x509 -in "etc/ssl/certs/4096.crt" -noout -text |
grep -q "Public-Key: (4096 bit)"

# Test that we can generate certificates only valid until tomorrow.
certified --days="1" CN="Tomorrow"
openssl x509 -in "etc/ssl/certs/tomorrow.crt" -noout -text |
grep -q "$(date -d"tomorrow" +"%b %e %H:%M:%S %Y")"

# Test that we can change the name of the certificate file.
certified --name="filename" CN="certname"
openssl x509 -in "etc/ssl/certs/filename.crt" -noout -text |
grep -q "Subject: CN=certname"

# Test that we can add subject alternative names to a certificate.
certified CN="SAN" +"127.0.0.1" +"example.com"
openssl x509 -in "etc/ssl/certs/san.crt" -noout -text |
grep -q "DNS:example.com"
openssl x509 -in "etc/ssl/certs/san.crt" -noout -text |
grep -q "IP Address:127.0.0.1"

# Test that we can add DNS wildcards to a certificate.
certified CN="Wildcard" +"*.example.com"
openssl x509 -in "etc/ssl/certs/wildcard.crt" -noout -text |
grep -F -q "DNS:*.example.com"

# Test that we can't add double DNS wildcards to a certificate.
certified CN="Double Wildcard" +"*.*.example.com" && false

set +x
echo >&2
echo "PASS" >&2
