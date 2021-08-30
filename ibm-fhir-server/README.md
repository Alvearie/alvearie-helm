![Version: 0.0.5](https://img.shields.io/badge/Version-0.0.5-informational?style=flat-square) ![AppVersion: 4.9.0](https://img.shields.io/badge/AppVersion-4.9.0-informational?style=flat-square)

# The IBM FHIR Server Helm Chart
The [IBM FHIR Server](https://ibm.github.io/FHIR) implements version 4 of the HL7 FHIR specification
with a focus on performance and configurability.

This helm chart will help you install the IBM FHIR Server in a Kubernetes environment and uses
ConfigMaps and Secrets to support the wide range of configuration options available for the server.

## Sample usage
```
helm upgrade --install ibm-fhir-server . --values values.yaml --set 'ingress.hostname=cluster1-blue-250babbbe4c3000e15508cd07c1d282b-0000.us-east.containers.appdomain.cloud' --set 'ingress.tls[0].secretName=cluster1-blue-250babbbe4c3000e15508cd07c1d282b-0000'
```

## Prerequisites
To install the IBM FHIR Server via helm, you must first have a database.

To install a PostgreSQL database to the same cluster using helm, you can run the following command:
```
$ helm install my-release bitnami/postgresql --set fullnameOverride=postgres --set postgresqlExtendedConf.maxPreparedTransactions=100
```

For example if you target the default namespace and name the release "postgres",
then that would produce something like this:
```
$ helm install postgres bitnami/postgresql --set fullnameOverride=postgres --set postgresqlExtendedConf.maxPreparedTransactions=100

NAME: postgres
LAST DEPLOYED: Wed Jun 23 12:01:11 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 5432 on the following DNS name from within your cluster:

    postgres.default.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace default postgres -o jsonpath="{.data.postgresql-password}" | base64 --decode)

To connect to your database run the following command:

    kubectl run postgres-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.12.0-debian-10-r23 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host postgres -U postgres -d postgres -p 5432

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/postgres 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432
```

# Chart info

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| audit.enabled | bool | `false` |  |
| audit.geoCity | string | `nil` | The city where the server is running |
| audit.geoCountry | string | `nil` | The country where the server is running |
| audit.geoState | string | `nil` | The state where the server is running |
| audit.kafka.bootstrapServers | string | `nil` |  |
| audit.kafka.saslJaasConfig | string | `nil` |  |
| audit.kafka.saslMechanism | string | `"PLAIN"` |  |
| audit.kafka.securityProtocol | string | `"SASL_SSL"` |  |
| audit.kafka.sslEnabledProtocols | string | `"TLSv1.2"` |  |
| audit.kafka.sslEndpointIdentificationAlgorithm | string | `"HTTPS"` |  |
| audit.kafka.sslProtocol | string | `"TLSv1.2"` |  |
| audit.kafkaApiKey | string | `nil` |  |
| audit.kafkaServers | string | `nil` |  |
| audit.topic | string | `"FHIR_AUDIT_DEV"` | The target Kafka topic for audit events |
| audit.type | string | `"auditevent"` | `cadf` or `auditevent` |
| datasourcesTemplate | string | `"datasourcesXmlPostgres"` | Template containing the datasources.xml content |
| db.apiKey | string | `nil` | The database apiKey. If apiKeySecret is set, the apiKey will be set from its contents. |
| db.apiKeySecretKey | string | `nil` | For the Secret specified in dbSecret, the key of the key/value pair containing the apiKey. This value will be ignored if the dbSecret value is not set. |
| db.dbSecret | string | `"postgres"` | The name of a Secret from which to retrieve database information. If this value is set, it is expected that passwordSecretKey and/or apiKeySecretKey will also be set. |
| db.enableTls | bool | `false` |  |
| db.host | string | `"postgres"` |  |
| db.name | string | `"postgres"` |  |
| db.password | string | `nil` | The database password. If dbSecret is set, the password will be set from its contents. |
| db.passwordSecretKey | string | `"postgresql-password"` | For the Secret specified in dbSecret, the key of the key/value pair containing the password. This value will be ignored if the dbSecret value is not set. |
| db.pluginName | string | `nil` |  |
| db.port | int | `5432` |  |
| db.schema | string | `"fhirdata"` |  |
| db.securityMechanism | string | `nil` |  |
| db.sslConnection | bool | `true` |  |
| db.tenantKey | string | `nil` |  |
| db.type | string | `"postgresql"` |  |
| db.user | string | `"postgres"` |  |
| endpoints | list | A single entry for resourceType "Resource" that applies to all resource types | Control which interactions are supported for which resource type endpoints |
| endpoints[0] | object | `{"interactions":["create","read","vread","history","search","update","patch","delete"],"profiles":null,"resourceType":"Resource","searchIncludes":null,"searchParameters":[{"code":"*","url":"*"}],"searchRevIncludes":null}` | A valid FHIR resource type; use "Resource" for whole-system behavior |
| endpoints[0].interactions | list | All interactions. | The set of enabled interactions for this resource type: [create, read, vread, history, search, update, patch, delete] |
| endpoints[0].profiles | list | `nil` | Instances of this type must claim conformance to at least one of the listed profiles; nil means no profile conformance required |
| endpoints[0].searchIncludes | list | `nil` | Valid _include arguments while searching this resource type; nil means no restrictions |
| endpoints[0].searchParameters | list | `[{"code":"*","url":"*"}]` | A mapping from enabled search parameter codes to search parameter definitions |
| endpoints[0].searchRevIncludes | list | `nil` | Valid _revInclude arguments while searching this resource type; nil means no restrictions |
| extensionSearchParametersTemplate | string | `"extensionSearchParametersJsonDefault"` | Template containing the extension-search-parameters.json content |
| fhirAdminPassword | string | `"change-password"` | The fhirAdminPassword. If fhirPasswordSecret is set, the fhirAdminPassword will be set from its contents. |
| fhirAdminPasswordSecretKey | string | `nil` | For the Secret specified in fhirPasswordSecret, the key of the key/value pair containing the fhirAdminPassword. This value will be ignored if the fhirPasswordSecret value is not set. |
| fhirPasswordSecret | string | `nil` | The name of a Secret from which to retrieve fhirUserPassword and fhirAdminPassword. If this value is set, it is expected that fhirUserPasswordSecretKey and fhirAdminPasswordSecretKey will also be set. |
| fhirServerConfigTemplate | string | `"fhirServerConfigJsonDefault"` | Template containing the fhir-server-config.json content |
| fhirUserPassword | string | `"change-password"` | The fhirUserPassword. If fhirPasswordSecret is set, the fhirUserPassword will be set from its contents. |
| fhirUserPasswordSecretKey | string | `nil` | For the Secret specified in fhirPasswordSecret, the key of the key/value pair containing the fhirUserPassword. This value will be ignored if the fhirPasswordSecret value is not set. |
| fullnameOverride | string | `nil` | Optional override for the fully qualified name of the created kube resources |
| image.pullPolicy | string | `"Always"` |  |
| image.repository | string | `"ibmcom/ibm-fhir-server"` |  |
| image.tag | string | `"4.9.0"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `true` |  |
| ingress.hostname | string | `"fhir.example.com"` | The default cluster hostname, used for both ingress.rules.host and ingress.tls.hosts. If you have more than one, you'll need to set overrides for the rules and tls separately. |
| ingress.rules[0].host | string | `"{{ .Release.Name }}.{{ $.Values.ingress.hostname }}"` |  |
| ingress.rules[0].paths[0] | string | `"/"` |  |
| ingress.servicePort | string | `"https"` |  |
| ingress.tls[0].hosts[0] | string | `"{{ $.Values.ingress.hostname }}"` |  |
| ingress.tls[0].secretName | string | `""` |  |
| nameOverride | string | `nil` | Optional override for chart name portion of the created kube resources |
| notifications.kafka.bootstrapServers | string | `nil` |  |
| notifications.kafka.enabled | bool | `false` |  |
| notifications.kafka.saslJaasConfig | string | `nil` |  |
| notifications.kafka.saslMechanism | string | `"PLAIN"` |  |
| notifications.kafka.securityProtocol | string | `"SASL_SSL"` |  |
| notifications.kafka.sslEnabledProtocols | string | `"TLSv1.2"` |  |
| notifications.kafka.sslEndpointIdentificationAlgorithm | string | `"HTTPS"` |  |
| notifications.kafka.sslProtocol | string | `"TLSv1.2"` |  |
| notifications.kafka.topicName | string | `nil` |  |
| notifications.nats.channel | string | `nil` |  |
| notifications.nats.clientId | string | `nil` |  |
| notifications.nats.cluster | string | `nil` |  |
| notifications.nats.enabled | bool | `false` |  |
| notifications.nats.keystoreLocation | string | `nil` |  |
| notifications.nats.keystorePassword | string | `nil` |  |
| notifications.nats.servers | string | `nil` |  |
| notifications.nats.truststoreLocation | string | `nil` |  |
| notifications.nats.truststorePassword | string | `nil` |  |
| notifications.nats.useTLS | bool | `true` |  |
| objectStorage.accessKey | string | `nil` | The object storage access key. If objectStorageSecret is set, the access key will be set from its contents. |
| objectStorage.accessKeySecretKey | string | `nil` | For the Secret specified in objectStorageSecret, the key of the key/value pair containing the access key. This value will be ignored if the objectStorageSecret value is not set. |
| objectStorage.batchIdEncryptionKey | string | `nil` |  |
| objectStorage.bulkDataBucketName | string | `nil` | Bucket names must be globally unique |
| objectStorage.enabled | bool | `false` |  |
| objectStorage.endpointUrl | string | `nil` | The object storage endpoint URL. If objectStorageSecret is set, the endpoint URL will be set from its contents. |
| objectStorage.endpointUrlSecretKey | string | `nil` | For the Secret specified in objectStorageSecret, the key of the key/value pair containing the endpoint URL. This value will be ignored if the objectStorageSecret value is not set. |
| objectStorage.location | string | `nil` | The object storage location. If objectStorageSecret is set, the location will be set from its contents. |
| objectStorage.locationSecretKey | string | `nil` | For the Secret specified in objectStorageSecret, the key of the key/value pair containing the location. This value will be ignored if the objectStorageSecret value is not set. |
| objectStorage.objectStorageSecret | string | `nil` | The name of a Secret from which to retrieve object storage information. If this value is set, it is expected that locationSecretKey, endpointSecretKey, accessKeySecretKey, and secretKeySecretKey will also be set. |
| objectStorage.secretKey | string | `nil` | The object storage secret key. If objectStorageSecret is set, the secret key will be set from its contents. |
| objectStorage.secretKeySecretKey | string | `nil` | For the Secret specified in objectStorageSecret, the key of the key/value pair containing the secret key. This value will be ignored if the objectStorageSecret value is not set. |
| replicaCount | int | `2` | The number of replicas for the externally-facing FHIR server pods |
| resources.limits.ephemeral-storage | string | `"1Gi"` |  |
| resources.limits.memory | string | `"5Gi"` |  |
| resources.requests.ephemeral-storage | string | `"1Gi"` |  |
| resources.requests.memory | string | `"4Gi"` |  |
| restrictEndpoints | bool | `false` | Set to true to restrict the API to a particular set of resource type endpoints |
| schemaMigration.enabled | bool | `true` |  |
| schemaMigration.image.pullPolicy | string | `"Always"` |  |
| schemaMigration.image.pullSecret | string | `"all-icr-io"` |  |
| schemaMigration.image.repository | string | `"ibmcom/ibm-fhir-schematool"` |  |
| schemaMigration.image.tag | string | `"4.9.0"` |  |
| serverRegistryResourceProviderEnabled | bool | `false` | Indicates whether the server registry resource provider should be used by the FHIR registry component to access definitional resources through the persistence layer |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
