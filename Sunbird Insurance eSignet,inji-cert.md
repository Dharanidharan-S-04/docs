**Sunbird Insurance eSignet,inji-certify deploymnet**


first check the running eSignet pointing to which properties file 

add this in the existing signet deployment yaml



&#x20; - name: active_profile_env

&#x20;   value: default,mosipid



\--------------------------------------------------------



**deploy new eSignet for insurance:**



create dns for esignet-insurance

scale down all the deployment to 0 in esignet namespace

rename the db mosip_esignet to mosip_esignet_old



\--------command for renaming----------

psql -h api-internal.<domain>.idencode.link -U postgres -d postgres

give the postgres password



ALTER DATABASE mosip_esignet RENAME TO mosip_esignet_old;



if ur getting an error like ERROR: database "mosip_esignet" is being accessed by other users



* then see who is connected ---
SELECT pid, usename, application_name, client_addr

FROM pg_stat_activity

WHERE datname = 'mosip_esignet';  



* terminate all other connections ---

SELECT pg_terminate_backend(pid)

FROM pg_stat_activity

WHERE datname = 'mosip_esignet'

&#x20; AND pid <> pg_backend_pid();



then again run this command

ALTER DATABASE mosip_esignet RENAME TO mosip_esignet_old;



now u ca see the name of mosip_esignet got changed to mosip_esignet_old



\--------------------------------------------------------

add mosipid.esignet.insurance.host placeholder in config-server

and also captcha



clone https://github.com/dean-org/esignet/tree/1.6.2-sun this repo



cd esignet/db_scripts/mosip_esignet

chmod +x deploy-sunbird.sh



vi deploy.properties



DB_SERVERIP=api-internal.<domain-name>.idencode.link

DB_PORT=5432

SU_USER=postgres

DEFAULT_DB_NAME=postgres

MOSIP_DB_NAME=mosip_esignet_sunbird

DML_FLAG=1





./deploy-sunbird.sh deploy.properties

it will create a db then once db got created then rename it to mosip_esignet_sunbird 

then rename the mosip_esignet_old to mosip_esignet 

\-----------------------------

Rename databases after creation

•	Rename the newly created DB:  mosip_esignet → mosip_esignet_sunbird

•	Revert the old DB name back:  mosip_esignet_old → mosip_esignet

&#x20;



cd esignet/deploy/softhsm

./install.sh

once softhsm pod got created 



cd esignet/deploy/redis

./install.sh



cd esignet/deploy/esignet-with-plugins

./install.sh

Is Prometheus Service Monitor Operator deployed in the k8s cluster? (y/n):y

Do you have public domain \& valid SSL? (Y/n)

Y: if you have public domain \& valid ssl certificate

n: If you don't have a public domain and a valid SSL certificate. Note: It is recommended to use this option only in development environments. 

y

For PKCS12 mounted keys, opt 'y' to enable volume (y/n) \[ default: n ]: n  
 select 3 sunbird-rc-plugin



edit deployment yaml



&#x20;- name: >-

&#x20;               MOSIP_ESIGNET_AUTHENTICATOR_DEFAULT_AUTH_FACTOR_KBI_FIELD_DETAILS

&#x20;             value: >-

&#x20;               {{'id': 'policyNumber', 'type':'text', 'format':'', 'maxLength':

&#x20;               50, 'regex':

&#x20;               '^\\s\*\[+-]?(\\d+|\\d\*\\.\\d+|\\d+\\.\\d\*)(\[Ee]\[+-]?\\d\*)?\\s\*$'},{'id':'fullName',

&#x20;               'type':'text', 'format':'', 'maxLength': 50, 'regex':

&#x20;               '^\[A-Za-z\\s]{1,}\[\\.]{0,1}\[A-Za-z\\s]{0,}$'},{'id':'dob',

&#x20;               'type':'date', 'format':'yyyy-MM-dd'}}



add this after   MOSIP_ESIGNET_AUTHENTICATOR_DEFAULT_AUTH_FACTOR_KBI_INDIVIDUAL_ID_FIELD this



copy esignet-sunbird-softhsm pin from secret and add it for mosip.kernel.keymanager.hsm.keystore-pass= this variable in esignet-insurance.properties file



cd esignet/deploy/oidc-ui

./install.sh



add the properties files with the reference of  https://github.com/dean-org/sunbird-properties/tree/main this repo



update the redis password in esignet-insurance.properties



~~-----------------------------------------------------------------------------------------------------------------------------~~



**inji certify sunbird insurance:**



create dns for the certify-insurance



clone https://github.com/dean-org/inji-certify-sunbird/tree/0.13.0-sun  this repo



rename th~~e~~ inji_certify db to inji_certify_old 


ALTER DATABASE inji_certify RENAME TO inji_certify_old;



cd inji-certify-sunbird/db_scripts/inji_certify/

chmod +x deploy.sh

./deploy.sh deploy.property



ALTER DATABASE inji_certify RENAME TO sunbird_inji_certify;

ALTER DATABASE inji_certify_old RENAME TO inji_certify;



CREATE USER sunbirduser WITH PASSWORD '<db-common-pass>';

ALTER DATABASE sunbird_inji_certify OWNER TO sunbirduser;




psql -h api-internal.<domain>.idencode.link -U postgres -d sunbird_inji_certify

GRANT USAGE ON SCHEMA certify TO sunbirduser;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA certify TO sunbirduser;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA certify TO sunbirduser;

GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA certify TO sunbirduser;

ALTER DEFAULT PRIVILEGES IN SCHEMA certify

GRANT ALL ON TABLES TO sunbirduser;

ALTER DEFAULT PRIVILEGES IN SCHEMA certify

GRANT ALL ON SEQUENCES TO sunbirduser;

ALTER DEFAULT PRIVILEGES IN SCHEMA certify

GRANT ALL ON FUNCTIONS TO sunbirduser;



run the below apis 



POST https://injicertify-insurance.togodemo.idencode.link/v1/certify/credential-configurations

{

&#x20; "credentialConfigKeyId": "LifeInsuranceCredential",

&#x20; "credentialFormat": "ldp_vc",

&#x20; "scope": "life_insurance_vc_ldp",

&#x20; "contextURLs": \[

&#x20;   "https://www.w3.org/2018/credentials/v1"

&#x20; ],

&#x20; "credentialTypes": \[

&#x20;   "VerifiableCredential",

&#x20;   "LifeInsuranceCredential"

&#x20; ],

&#x20; "didUrl": "did:jwk",

&#x20; "signatureCryptoSuite": "Ed25519Signature2020",

&#x20; "signatureAlgo": "Ed25519",

&#x20; "keyManagerAppId": "CERTIFY_VC_SIGN_ED25519",

&#x20; "keyManagerRefId": "ED25519_SIGN",

&#x20; "credentialSubjectDefinition": {

&#x20;   "fullName": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Name",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "policyName": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Policy Name",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "policyNumber": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Policy Number",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "policyIssuedOn": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Policy Issued On",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "policyExpiresOn": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Policy Expires On",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "mobile": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Phone Number",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "dob": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Date of Birth",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "gender": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Gender",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "benefits": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Benefits",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "email": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Email Id",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   }

&#x20; },

&#x20; "displayOrder": \[

&#x20;   "fullName",

&#x20;   "policyName",

&#x20;   "policyNumber",

&#x20;   "policyIssuedOn",

&#x20;   "policyExpiresOn",

&#x20;   "mobile",

&#x20;   "dob",

&#x20;   "gender",

&#x20;   "benefits",

&#x20;   "email"

&#x20; ],

&#x20; "metaDataDisplay": \[

&#x20;   {

&#x20;     "name": "Life Insurance Credential",

&#x20;     "locale": "en",

&#x20;     "logo": {

&#x20;       "url": "https://inji.github.io/inji-config/logos/StayProtectedInsurance.png",

&#x20;       "alt_text": "a square logo of a MOSIP"

&#x20;     },

&#x20;     "background_color": "#12107c",

&#x20;     "background_image": {

&#x20;       "uri": "https://inji.github.io/inji-config/vcbackground/default-background.png"

&#x20;     },

&#x20;     "text_color": "#FFFFFF"

&#x20;   }

&#x20; ]

}





POST https://injicertify-insurance.togodemo.idencode.link/v1/certify/credential-configurations



{

&#x20; "credentialConfigKeyId": "InsuranceCredential",

&#x20; "credentialFormat": "ldp_vc",

&#x20; "scope": "sunbird_rc_insurance_vc_ldp",

&#x20; "contextURLs": \[

&#x20;   "https://www.w3.org/2018/credentials/v1"

&#x20; ],

&#x20; "credentialTypes": \[

&#x20;   "VerifiableCredential",

&#x20;   "InsuranceCredential"

&#x20; ],

&#x20; "didUrl": "did:jwk",

&#x20; "signatureCryptoSuite": "Ed25519Signature2020",

&#x20; "signatureAlgo": "Ed25519",

&#x20; "keyManagerAppId": "CERTIFY_VC_SIGN_ED25519",

&#x20; "keyManagerRefId": "ED25519_SIGN",

&#x20; "credentialSubjectDefinition": {

&#x20;   "fullName": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Name",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "policyName": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Policy Name",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "policyNumber": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Policy Number",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "policyIssuedOn": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Policy Issued On",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "policyExpiresOn": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Policy Expires On",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "mobile": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Phone Number",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "dob": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Date of Birth",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "gender": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Gender",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "benefits": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Benefits",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   },

&#x20;   "email": {

&#x20;     "display": \[

&#x20;       {

&#x20;         "name": "Email Id",

&#x20;         "locale": "en"

&#x20;       }

&#x20;     ]

&#x20;   }

&#x20; },

&#x20; "displayOrder": \[

&#x20;   "fullName",

&#x20;   "policyName",

&#x20;   "policyNumber",

&#x20;   "policyIssuedOn",

&#x20;   "policyExpiresOn",

&#x20;   "mobile",

&#x20;   "dob",

&#x20;   "gender",

&#x20;   "benefits",

&#x20;   "email"

&#x20; ],

&#x20; "metaDataDisplay": \[

&#x20;   {

&#x20;     "name": "Insurance Credential",

&#x20;     "locale": "en",

&#x20;     "logo": {

&#x20;       "url": "https://inji.github.io/inji-config/logos/StayProtectedInsurance.png",

&#x20;       "alt_text": "a square logo of a MOSIP"

&#x20;     },

&#x20;     "background_color": "#12107c",

&#x20;     "background_image": {

&#x20;       "uri": "https://api.dev-int-inji.mosip.net/inji/veridonia-logo.png"

&#x20;     },

&#x20;     "text_color": "#FFFFFF"

&#x20;   }

&#x20; ]

}



