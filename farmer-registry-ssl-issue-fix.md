# TLS Certificate Configuration for Python Application in Kubernetes

## 1. Problem

The Farmer Registry Staff Portal Python application running in Kubernetes needed to communicate securely with services using the internal OpenG2P TLS certificates.

The application was running in the `dev` namespace as:

```text
Deployment: farmer-registry-staff-portal-api
Container: staff-portal-api
```

The Keycloak endpoint was:

```text
https://keycloak.dev.openg2p.test
```

The server certificate was issued by the internal CA:

```text
OpenG2P Local CA
```

Initially, OpenSSL reported:

```text
Verify return code: 19 (self signed certificate in certificate chain)
```

This indicated that the internal CA was not trusted by the default system certificate store.

---

# 2. Verify the Server Certificate

The Keycloak server certificate was checked using:

```bash
openssl s_client \
  -connect keycloak.dev.openg2p.test:443 \
  -servername keycloak.dev.openg2p.test \
  -showcerts \
  </dev/null
```

The certificate chain contained:

```text
0: *.dev.openg2p.test
1: OpenG2P Local CA
```

The server certificate had:

```text
Subject: CN=*.dev.openg2p.test
Issuer:  CN=OpenG2P Local CA
```

The server certificate SHA-256 fingerprint was:

```text
2E:02:7E:94:A0:4C:31:BE:E3:89:DA:F6:B9:1D:EB:BF:68:0C:92:69:AB:D3:8F:3D:36:F2:A8:C3:C8:6E:17:96
```

---

# 3. Extract the OpenG2P Local CA Certificate

The second certificate in the server certificate chain was extracted:

```bash
openssl s_client \
  -connect keycloak.dev.openg2p.test:443 \
  -servername keycloak.dev.openg2p.test \
  -showcerts \
  </dev/null 2>/dev/null |
awk '
/BEGIN CERTIFICATE/ { n++ }
n == 2 { print }
/END CERTIFICATE/ && n == 2 { exit }
' > /tmp/openg2p-ca.pem
```

The extracted certificate was verified:

```bash
openssl x509 \
  -in /tmp/openg2p-ca.pem \
  -noout \
  -subject \
  -issuer \
  -dates \
  -fingerprint \
  -sha256
```

Result:

```text
subject=C = XX, ST = OpenG2P, L = OpenG2P, O = OpenG2P, CN = OpenG2P Local CA

issuer=C = XX, ST = OpenG2P, L = OpenG2P, O = OpenG2P, CN = OpenG2P Local CA

notBefore=Jul 19 18:20:13 2026 GMT
notAfter=Jul 16 18:20:13 2036 GMT

SHA256 Fingerprint=
4A:EE:9E:F2:70:B6:9F:43:B5:A0:C2:1D:ED:A1:56:E4:7B:59:A1:C8:E9:15:92:42:C8:14:37:B9:C9:71:B5:2A
```

Because the issuer and subject are the same, this is the self-signed root CA.

---

# 4. Verify the CA Against the Kubernetes Secret

The Kubernetes Secret used by the application was:

```text
farmer-registry-truststore
```

The CA certificate stored in the Secret was checked using:

```bash
kubectl -n dev get secret farmer-registry-truststore \
  -o jsonpath='{.data.ca\.crt}' | base64 -d | \
  openssl x509 -noout -subject -issuer -fingerprint -sha256
```

The result was:

```text
subject=C = XX, ST = OpenG2P, L = OpenG2P, O = OpenG2P, CN = OpenG2P Local CA

issuer=C = XX, ST = OpenG2P, L = OpenG2P, O = OpenG2P, CN = OpenG2P Local CA

SHA256 Fingerprint=
4A:EE:9E:F2:70:B6:9F:43:B5:A0:C2:1D:ED:A1:56:E4:7B:59:A1:C8:E9:15:92:42:C8:14:37:B9:C9:71:B5:2A
```

This matched the CA extracted from the Keycloak server.

Therefore:

```text
Keycloak CA fingerprint
        =
Kubernetes Secret CA fingerprint
```

The correct CA was already stored in Kubernetes.

---

# 5. Verify TLS Using the CA

The CA was explicitly supplied to OpenSSL:

```bash
openssl s_client \
  -connect keycloak.dev.openg2p.test:443 \
  -servername keycloak.dev.openg2p.test \
  -CAfile /tmp/openg2p-ca.pem \
  </dev/null
```

The important result was:

```text
Verification: OK

Verify return code: 0 (ok)
```

This proved that the certificate chain was valid when the correct OpenG2P Local CA was trusted.

---

# 6. Mount the CA Certificate into the Python Application

The Kubernetes Deployment uses the Secret:

```yaml
volumes:
  - name: truststore-vol
    secret:
      secretName: farmer-registry-truststore
```

The Secret is mounted into the application container:

```yaml
volumeMounts:
  - mountPath: /opt/truststore
    name: truststore-vol
    readOnly: true
```

The certificate therefore becomes available inside the Python container at:

```text
/opt/truststore/ca.crt
```

---

# 7. Configure Python to Use the CA

The application Deployment contains:

```yaml
- name: SSL_CERT_FILE
  value: /opt/truststore/ca.crt
```

This tells Python/OpenSSL-based TLS clients to use the OpenG2P CA certificate when validating TLS connections.

The configuration was verified inside the actual application container:

```bash
kubectl -n dev exec -it deploy/farmer-registry-staff-portal-api \
  -c staff-portal-api -- \
  python -c "import os; print(os.environ.get('SSL_CERT_FILE')); print(os.path.exists('/opt/truststore/ca.crt')); print(os.path.getsize('/opt/truststore/ca.crt'))"
```

Output:

```text
/opt/truststore/ca.crt
True
2009
```

This confirmed:

* `SSL_CERT_FILE` is configured correctly.
* The certificate exists inside the Python container.
* Kubernetes successfully mounted the Secret.

---

# 8. Verify the Certificate from the Python Container

The application container did not contain the `openssl` command:

```text
sh: openssl: not found
```

This was not a certificate problem. It simply meant the application image did not include the OpenSSL CLI.

Instead, the TLS connection was tested directly using Python.

---

# 9. Test HTTPS from the Actual Python Application

The following command was executed inside the application container:

```bash
kubectl -n dev exec -it deploy/farmer-registry-staff-portal-api \
  -c staff-portal-api -- \
  python -c "import urllib.request; r=urllib.request.urlopen('https://keycloak.dev.openg2p.test', timeout=10); print(r.status); print(r.geturl())"
```

Result:

```text
200
https://keycloak.dev.openg2p.test/admin/master/console/
```

This was the final verification.

It proved that the Python application container can:

1. Resolve the Keycloak hostname.
2. Establish an HTTPS connection.
3. Validate the Keycloak certificate.
4. Trust the OpenG2P Local CA.
5. Successfully communicate with Keycloak.

---

# 10. Final Architecture

The final certificate flow is:

```text
                   Kubernetes
                       |
                       v
          Secret: farmer-registry-truststore
                       |
                       | ca.crt
                       v
             /opt/truststore/ca.crt
                       |
                       v
             SSL_CERT_FILE
                       |
                       v
              Python Application
                       |
                       | HTTPS
                       v
        keycloak.dev.openg2p.test:443
                       |
                       v
             *.dev.openg2p.test
                       |
                       | issued by
                       v
              OpenG2P Local CA
```

---

# 11. Important Configuration

The relevant Kubernetes configuration is:

```yaml
volumes:
  - name: truststore-vol
    secret:
      secretName: farmer-registry-truststore

containers:
  - name: staff-portal-api
    env:
      - name: SSL_CERT_FILE
        value: /opt/truststore/ca.crt

    volumeMounts:
      - mountPath: /opt/truststore
        name: truststore-vol
        readOnly: true
```

The important point is that the application does not need the private key of the server certificate.

It only needs to trust the **CA certificate** that issued the server certificate.

---

# 12. About NODE_TLS_REJECT_UNAUTHORIZED

The Deployment currently contains:

```yaml
- name: NODE_TLS_REJECT_UNAUTHORIZED
  value: '0'
```

This is a Node.js environment variable and is not the proper mechanism for configuring TLS verification in a Python application.

It disables TLS certificate verification for Node.js applications and should not be used as the permanent solution for certificate trust.

The correct solution for this Python application is:

```text
OpenG2P Local CA
        ↓
Kubernetes Secret
        ↓
/opt/truststore/ca.crt
        ↓
SSL_CERT_FILE
        ↓
Python TLS verification
```

If `NODE_TLS_REJECT_UNAUTHORIZED=0` was added only during troubleshooting and is not required by another component, it should be removed after confirming there is no dependency on it.

---

# 13. Final Verification Checklist

| Check                                   | Result |
| --------------------------------------- | ------ |
| Keycloak server certificate exists      | ✅      |
| Certificate issued by OpenG2P Local CA  | ✅      |
| OpenG2P Local CA extracted              | ✅      |
| CA fingerprint verified                 | ✅      |
| Kubernetes Secret contains same CA      | ✅      |
| Secret mounted into Python container    | ✅      |
| `/opt/truststore/ca.crt` exists         | ✅      |
| `SSL_CERT_FILE` configured              | ✅      |
| OpenSSL verification using CA           | ✅      |
| Python HTTPS verification               | ✅      |
| Keycloak HTTPS request returns HTTP 200 | ✅      |

## Final Status

**TLS certificate configuration for the Python application is working successfully.**

The root cause was that the internal **OpenG2P Local CA** was not trusted by the application's default trust configuration.

The issue was resolved by making the correct CA certificate available through a Kubernetes Secret, mounting that Secret into the Python container, and configuring:

```text
SSL_CERT_FILE=/opt/truststore/ca.crt
```

The final Python HTTPS test returned:

```text
200
```

confirming successful and verified TLS communication with Keycloak.
