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
$ helm install my-release bitnami/postgresql --set fullnameOverride=postgres
```

For example if you target the default namespace and name the release "postgres",
then that would produce something like this:
```
$ helm install postgres bitnami/postgresql --set fullnameOverride=postgres
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
![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![AppVersion: 4.8.3](https://img.shields.io/badge/AppVersion-4.8.3-informational?style=flat-square)

Helm chart for the IBM FHIR Server

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| audit.enabled | bool | `false` |  |
| audit.geoCity | string | `nil` | The city where the server is running |
| audit.geoCountry | string | `nil` | The country where the server is running |
| audit.geoState | string | `nil` | The state where the server is running |
| audit.kafka | object | `{"bootstrapServers":null,"saslJaasConfig":null,"saslMechanism":"PLAIN","securityProtocol":"SASL_SSL","sslEnabledProtocols":"TLSv1.2","sslEndpointIdentificationAlgorithm":"HTTPS","sslProtocol":"TLSv1.2"}` | Kafka connection properties |
| audit.kafkaApiKey | string | `nil` |  |
| audit.kafkaServers | string | `nil` |  |
| audit.topic | string | `"FHIR_AUDIT_DEV"` | The target Kafka topic for audit events |
| audit.type | string | `"auditevent"` | `cadf` or `auditevent` |
| db.enableTls | bool | `false` |  |
| db.host | string | `"postgres-postgresql"` |  |
| db.name | string | `"postgres"` |  |
| db.passwordSecret | string | `"postgres-postgresql"` |  |
| db.port | int | `5432` |  |
| db.schema | string | `"fhirdata"` |  |
| db.type | string | `"postgresql"` |  |
| db.username | string | `"postgres"` |  |
| fhirAdminPassword | string | `"change-password"` |  |
| fhirUserPassword | string | `"change-password"` |  |
| image.pullPolicy | string | `"Always"` |  |
| image.pullSecret | string | `"all-icr-io"` |  |
| image.repository | string | `"ibmcom/ibm-fhir-server"` |  |
| image.tag | string | `"4.8.3"` |  |
| ingestionReplicas | int | `3` |  |
| ingress.enabled | bool | `true` |  |
| ingress.hostname | string | `"cluster1-blue-250babbbe4c3000e15508cd07c1d282b-0000.us-east.containers.appdomain.cloud"` |  |
| ingress.hosts[0] | string | `"cluster1-blue-250babbbe4c3000e15508cd07c1d282b-0000.us-east.containers.appdomain.cloud"` |  |
| ingress.tls[0].hosts[0] | string | `"cluster1-blue-250babbbe4c3000e15508cd07c1d282b-0000.us-east.containers.appdomain.cloud"` |  |
| ingress.tls[0].secretName | string | `nil` |  |
| objectStorage.accessKey | string | `nil` |  |
| objectStorage.batchIdEncryptionKey | string | `nil` |  |
| objectStorage.bulkdataBucketName | string | `nil` | Bucket names must be globally unique |
| objectStorage.enabled | bool | `false` |  |
| objectStorage.endpointUrl | string | `nil` |  |
| objectStorage.location | string | `nil` |  |
| objectStorage.secretKey | string | `nil` |  |
| replicaCount | int | `2` |  |
| resources.limits.ephemeral-storage | string | `"1Gi"` |  |
| resources.limits.memory | string | `"5Gi"` |  |
| resources.requests.ephemeral-storage | string | `"1Gi"` |  |
| resources.requests.memory | string | `"4Gi"` |  |
| schemaMigration.enabled | bool | `true` |  |
| schemaMigration.image.pullPolicy | string | `"Always"` |  |
| schemaMigration.image.pullSecret | string | `"all-icr-io"` |  |
| schemaMigration.image.repository | string | `"ibmcom/ibm-fhir-schematool"` |  |
| schemaMigration.image.tag | string | `"4.8.3"` |  |
| service.internalPort | int | `9443` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
