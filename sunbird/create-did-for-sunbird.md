in .env file WEB_DID_BASE_URL=
add a value for this like  WEB_DID_BASE_URL=https://dharanidharan-s-04.github.io/mosipid-did/sunbird:b1189cf0-ba99-4f11-affb-2482859c1d93

docker exec -it registry_and_credentialling-registry-1 curl -X POST http://identity:3332/did/generate -H "Content-Type: application/json" -d '{"method":"author"}'

this will create the did, check weather it is resolving or not 

 docker exec -it registry_and_credentialling-identity-1 /bin/sh
 app # curl http://localhost:3332/did/resolve/did:web:dharanidharan-s-04.github.io:mosipid-did:sunbird:b1189cf0-ba99-4f11-affb-2482859c1d93

 wil get 
 {"@context":["https://www.w3.org/ns/did/v1"],"id":"did:web:dharanidharan-s-04.github.io:mosipid-did:sunbird:b1189cf0-ba99-4f11-affb-2482859c1d93","alsoKnownAs":[],"service":[{"id":"CredentialsService","type":"CredentialDIDService"}],"verificationMethod":[{"id":"did:web:dharanidharan-s-04.github.io:mosipid-did:sunbird:b1189cf0-ba99-4f11-affb-2482859c1d93#key-0","type":"Ed25519VerificationKey2020","@context":"https://w3id.org/security/suites/ed25519-2020/v1","controller":"did:web:dharanidharan-s-04.github.io:mosipid-did:sunbird:b1189cf0-ba99-4f11-affb-2482859c1d93","publicKeyMultibase":"z6Mkii583oVYho8XdsLR9wqZ5b12BY9gPTQcsXfHzuJQMAiu"}],"authentication":["did:web:dharanidharan-s-04.github.io:mosipid-did:sunbird:b1189cf0-ba99-4f11-affb-2482859c1d93#key-0"],"assertionMethod":["did:web:dharanidharan-s-04.github.io:mosipid-did:sunbird:b1189cf0-ba99-4f11-affb-2482859c1d93#key-0"]}/
 like this 

 it will be inside identity table under registry db.
