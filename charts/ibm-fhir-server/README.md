
![Version: 0.6.3](https://img.shields.io/badge/Version-0.6.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.10.2](https://img.shields.io/badge/AppVersion-4.10.2-informational?style=flat-square)

# The IBM FHIR Server Helm Chart

The [IBM FHIR Server](https://ibm.github.io/FHIR) implements version 4 of the HL7 FHIR specification
with a focus on performance and configurability.

This helm chart will help you install the IBM FHIR Server in a Kubernetes environment and uses
ConfigMaps and Secrets to support the wide range of configuration options available for the server.

## Sample usage

```sh
helm repo add alvearie https://alvearie.io/alvearie-helm
export POSTGRES_PASSWORD=$(openssl rand -hex 20)
helm upgrade --install --render-subchart-notes ibm-fhir-server alvearie/ibm-fhir-server --set postgresql.postgresqlPassword=${POSTGRES_PASSWORD} --set ingress.hostname=example.com --set 'ingress.tls[0].secretName=cluster-tls-secret'
```

This will install the latest version if the IBM FHIR Server using an included PostgreSQL database for persistence.
Note that `postgresql.postgresqlPassword` must be set for all upgrades that use the embedded postgresql chart,
otherwise [the postgresql password will be overwritten and lost](https://artifacthub.io/packages/helm/bitnami/postgresql#troubleshooting).

By default, the IBM FHIR Server will only serve HTTPS traffic.
With the [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx),
this means that users must set the following ingress annotation:
```
nginx.ingress.kubernetes.io/backend-protocol: HTTPS
```
This can be accomplished via `--set 'ingress.annotations.nginx\.ingress\.kubernetes\.io/backend-protocol=HTTPS'` or
from your values override file.
See https://github.com/Alvearie/alvearie-helm/blob/main/charts/ibm-fhir-server/values-nginx.yaml for an example.

## Customizing the FHIR server configuration
This helm chart uses a [named template](https://helm.sh/docs/chart_template_guide/named_templates/) to generate the `fhir-server-config.json` file which will control the configuration of the deployed FHIR server. The template name is `defaultFhirServerConfig` and it is defined in the `_fhirServerConfigJson.tpl` file. It uses many of this helm chart's values as the values of config properties within the generated `fhir-server-config.json` file.

This design gives the deployer of this helm chart a number of different options to customize the FHIR server configuration:
1. Use the `defaultFhirServerConfig` named template that is provided, but override values specified in the template to customize the configuration. Chart values are used to customize config properties in the following sections of the configuration:
    - core
    - resources
    - security
    - notifications
    - audit
    - persistence
    - bulkdata
2. Provide a custom named template. If this helm chart is being deployed from another helm chart:
    - In the deploying chart, create a custom fhir server config named template which specifies the exact configuration required.
    - Override the `fhirServerConfigTemplate` chart value, setting it to the name of the custom named template. This helm chart will then use the specified named template to generate its `fhir-server-config.json` file.
3. Provide a custom named template as above, but with the config properties within the template set to a mix of chart values provided by this helm chart and hard-coded values specific to the deployer's use case. With this approach, the deploying helm chart can decide how much of the configuration to make customizable to its users. If there are config properties for which values are not provided by this helm chart, but that the deploying helm chart wants to make customizable, it can define global chart values and use those in the provided custom named template. It is important to make the chart values global to allow them to be in scope for this helm chart.

We can demonstrate these approaches with the following sample section from the `defaultFhirServerConfig` named template in the `_fhirServerConfigJson.tpl` file:
```
"core": {
    "tenantIdHeaderName": "X-FHIR-TENANT-ID",
    "datastoreIdHeaderName": "X-FHIR-DSID",
    "originalRequestUriHeaderName": "X-FHIR-FORWARDED-URL",
    "serverRegistryResourceProviderEnabled": {{ .Values.serverRegistryResourceProviderEnabled }},
    ...
},
```

1. If the deployer just wants to change the `serverRegistryResourceProviderEnabled` config property, they can use the `defaultFhirServerConfig` named template provided and simply override the `serverRegistryResourceProviderEnabled` chart value when deploying this helm chart.
2. If the deployer does not want this value to be customizable, and always wants the value to be set to `true`, they can provide a custom named template where the value has been hard-coded to `true`:

    ```
    "core": {
        "tenantIdHeaderName": "X-FHIR-TENANT-ID",
        "datastoreIdHeaderName": "X-FHIR-DSID",
        "originalRequestUriHeaderName": "X-FHIR-FORWARDED-URL",
        "serverRegistryResourceProviderEnabled": true,
        ...
    },
    ```
    When deploying the chart, the deployer must override the `fhirServerConfigTemplate` chart value, setting it to the name of their custom named template. This helm chart will then use that template to generate its `fhir-server-config.json` file.
3. If the deployer wants to continue to allow the `serverRegistryResourceProviderEnabled` config property to be customizable, but they also want the `defaultPageSize` config property to be customizable, they can provide a custom named template where the "core" section takes the value of the `serverRegistryResourceProviderEnabled` config property from this helm chart's values file, and takes the value of the `defaultPageSize` config property from their own values file (as a global value):
    ```
    "core": {
        "tenantIdHeaderName": "X-FHIR-TENANT-ID",
        "datastoreIdHeaderName": "X-FHIR-DSID",
        "originalRequestUriHeaderName": "X-FHIR-FORWARDED-URL",
        "serverRegistryResourceProviderEnabled": {{ .Values.serverRegistryResourceProviderEnabled }},
        "defaultPageSize": {{ .Values.global.defaultPageSize }},
        ...
    },
    ```
    As above, when deploying the chart, the deployer must override the `fhirServerConfigTemplate` chart value, setting it to the name of their custom named template. This helm chart will then use that template to generate its `fhir-server-config.json` file.

For a complete list of configuration properties for the IBM FHIR Server, please see the [User's Guide](https://ibm.github.io/FHIR/guides/FHIRServerUsersGuide).

In addition to providing a default FHIR server configuration named template, this helm chart also provides default named templates for custom search parameters and datasources, both of which can be overridden by custom named templates in the same manner as the FHIR server configuration template.

The deployer can specify a custom search parameters named template which will be used in the generation of the `extension-search-parameters.json` file by overriding the `extensionSearchParametersTemplate` chart value.

The deployer can specify custom datasource named templates which will be used in the generation of the `datasource.xml` and `bulkdata.xml` files by overriding the `datasourcesTemplate` chart value. The default for this chart value is a datasources template for a Postgres database, but this helm chart also provides named templates for Db2, Db2 on Cloud, and Derby databases in the `_datasourcesXml.tpl` file.

## Using existing Secrets for sensitive data

This helm chart specifies chart values for the following pieces of sensitive data:

- Database password or api key:
    - `db.password`
    - `db.apiKey`
- FHIR server user and admin passwords:
    - `fhirUserPassword`
    - `fhirAdminPassword`
- Object storage configuration information:
    - `objectStorage.location`
    - `objectStorage.endpointUrl`
    - `objectStorage.accessKey`
    - `objectStorage.secretKey`

These values can be specified directly in the `values.yaml` file, or the deployer can specify names of existing Secrets from which to read them.

### Database password or api key

To have the `db.password` and `db.apiKey` values read from an existing Secret, the deployer must override the following chart values:

- `db.dbSecret` - this is set to the name of the Secret from which the database information will be read
- `db.passwordSecretKey` - this is set to the key of the key/value pair within the Secret that contains the password
- `db.apiKeySecretKey` - this is set to the key of the key/value pair within the Secret that contains the api key

If the `db.dbSecret` value is set, this helm chart will only look in the specified Secret for the password and api key. The `db.password` and `db.apiKey` chart values will be ignored.

### FHIR server user and admin passwords

To have the FHIR server user and admin passwords read from an existing Secret, the deployer must override the following chart values:

- `fhirPasswordSecret` - this is set to the name of the Secret from which the FHIR server user and admin passwords will be read
- `fhirUserPasswordSecretKey` - this is set to the key of the key/value pair within the Secret that contains the user password
- `fhirAdminPasswordSecretKey` - this is set to the key of the key/value pair within the Secret that contains the admin password

If the `fhirPasswordSecret` value is set, this helm chart will only look in the specified Secret for the FHIR server user and admin passwords. The `fhirUserPassword` and `fhirAdminPassword` chart values will be ignored.

### Object storage configuration information

To have object storage configuration information read from an existing Secret, the deployer must override the following chart values:

- `objectStorage.objectStorageSecret` - this is set to the name of the Secret from which the object storage configuration information will be read
- `objectStorage.locationSecretKey` - this is set to the key of the key/value pair within the Secret that contains the object storage location
- `objectStorage.endpointUrlSecretKey` - this is set to the key of the key/value pair within the Secret that contains the object storage endpoint URL
- `objectStorage.accessKeySecretKey` - this is set to the key of the key/value pair within the Secret that contains the object storage access key
- `objectStorage.secretKeySecretKey` - this is set to the key of the key/value pair within the Secret that contains the object storage secret key

If the `objectStorage.objectStorageSecret` value is set, this helm chart will only look in the specified Secret for the object storage configuration information. The `objectStorage.locationSecretKey`, `objectStorage.endpointUrlSecretKey`, `objectStorage.accessKeySecretKey`, and `objectStorage.secretKeySecretKey` chart values will be ignored.

## Using Secrets for custom keystore and truststore configuration

By default, the FHIR server's `server.xml` file includes the definition of a keystore (`fhirKeyStore.p12`) and a truststore (`fhirTrustStore.p12`) file. These files are provided only as examples and, while they may suffice in a test environment, the deployer should generate new keystore and truststore files for any installations where security is a concern.

Custom keystore and truststore files can be configured in the FHIR server via Secrets. This helm chart specifies the following chart values to allow the deployer to specify the names of Secrets which contain keystore or truststore data, and to specify the format of the keystore or truststore data:

- `keyStoreSecret` - this is set to the name of the Secret from which the keystore information will be read
- `keyStoreFormat` - this is set to the format of the keystore in the keystore Secret - must be either `PKCS12` or `JKS`
- `trustStoreSecret` - this is set to the name of the Secret from which the truststore information will be read
- `trustStoreFormat` - this is set to the format of the truststore in the truststore Secret - must be either `PKCS12` or `JKS`

The keystore Secret is expected to contain the following data:

| Key | Value |
|-----|-------|
|`fhirKeyStore`|The contents of the keystore file|
|`fhirKeyStorePassword`|The keystore password|

An example Secret might look like this (note that the `fhirKeyStore` value containing the base64-encoded contents of the file has been truncated for display purposes):

```
apiVersion: v1
kind: Secret
metadata:
  name: my-custom-keystore-secret
type: Opaque
data:
  fhirKeyStore: MIIa0AIBAzCCGpYGCSqGSIb3D...
  fhirKeyStorePassword: Y2hhbmdlLXBhc3N3b3Jk
```

If a keystore Secret is specified, the default keystore file will be replaced with the provided keystore file, named either `fhirKeyStore.p12` or `fhirKeyStore.jks` depending on the value specified in `keyStoreFormat`, and the default keystore definition in the `server.xml` file will be updated with the keystore filename and the provided keystore password.

Similarly, the truststore Secret is expected to contain the following data:

| Key | Value |
|-----|-------|
|`fhirTrustStore`|The contents of the truststore file|
|`fhirTrustStorePassword`|The truststore password|

If a truststore Secret is specified, the default truststore file will be replaced with the provided truststore file, named either `fhirTrustStore.p12` or `fhirTrustStore.jks` depending on the value specified in `trustStoreFormat`, and the default truststore definition in the `server.xml` file will be updated with the truststore filename and the provided truststore password.

# Chart info

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | string | Preferred zone anti-affinity | Pod affinity |
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
| containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"runAsUser":1001}` | security context for the server container |
| datasourcesTemplate | string | `"defaultPostgresDatasources"` | Template containing the datasources.xml content |
| db.apiKey | string | `nil` | The database apiKey. If apiKeySecret is set, the apiKey will be set from its contents. |
| db.apiKeySecretKey | string | `nil` | For the Secret specified in dbSecret, the key of the key/value pair containing the apiKey. This value will be ignored if the dbSecret value is not set. |
| db.certPath | string | `nil` |  |
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
| endpoints | object | A single entry for resourceType "Resource" that applies to all resource types | Control which interactions are supported for which resource type endpoints |
| endpoints.Resource.interactions | list | All interactions. | The set of enabled interactions for this resource type: [create, read, vread, history, search, update, patch, delete] |
| endpoints.Resource.profiles.atLeastOne | list | `nil` | Instances of this type must claim conformance to at least one of the listed profiles; nil means no profile conformance required |
| endpoints.Resource.searchIncludes | list | `nil` | Valid _include arguments while searching this resource type; nil means no restrictions |
| endpoints.Resource.searchParameters | object | `{"*":"*"}` | A mapping from enabled search parameter codes to search parameter definitions |
| endpoints.Resource.searchRevIncludes | list | `nil` | Valid _revInclude arguments while searching this resource type; nil means no restrictions |
| exposeHttpEndpoint | bool | `false` | if enabled, the server will listen to non-TLS requests |
| exposeHttpPort | int | `9080` | The port on which the server will listen to non-TLS requests. Will be ignored if exposeHttpEndpoint is false. |
| extensionSearchParametersTemplate | string | `"defaultSearchParameters"` | Template containing the extension-search-parameters.json content |
| extraEnv | string | `""` |  |
| extraJvmOptions | string | `""` |  |
| extraLabels | object | `{}` | Extra labels to apply to the created kube resources |
| extraVolumeMounts | string | `""` | Add additional volume mounts. Evaluated as a template. Must evaluate to a valid yaml list of volume mounts. |
| extraVolumes | string | `""` | Add additional volumes. Evaluated as a template. Must evaluate to a valid yaml list of volumes. |
| fhirAdminPassword | string | `"change-password"` | The fhirAdminPassword. If fhirPasswordSecret is set, the fhirAdminPassword will be set from its contents. |
| fhirAdminPasswordSecretKey | string | `nil` | For the Secret specified in fhirPasswordSecret, the key of the key/value pair containing the fhirAdminPassword. This value will be ignored if the fhirPasswordSecret value is not set. |
| fhirPasswordSecret | string | `nil` | The name of a Secret from which to retrieve fhirUserPassword and fhirAdminPassword. If this value is set, it is expected that fhirUserPasswordSecretKey and fhirAdminPasswordSecretKey will also be set. |
| fhirServerConfigTemplate | string | `"defaultFhirServerConfig"` | Template containing the fhir-server-config.json content |
| fhirUserPassword | string | `"change-password"` | The fhirUserPassword. If fhirPasswordSecret is set, the fhirUserPassword will be set from its contents. |
| fhirUserPasswordSecretKey | string | `nil` | For the Secret specified in fhirPasswordSecret, the key of the key/value pair containing the fhirUserPassword. This value will be ignored if the fhirPasswordSecret value is not set. |
| fullnameOverride | string | `nil` | Optional override for the fully qualified name of the created kube resources |
| image.pullPolicy | string | `"IfNotPresent"` | When to pull the image |
| image.repository | string | `"ibmcom/ibm-fhir-server"` | The repository to pull the IBM FHIR Server image from |
| image.tag | string | this chart's appVersion | IBM FHIR Server container image tag |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `true` |  |
| ingress.hostname | string | `"{{ .Release.Name }}.example.com"` | The default cluster hostname, used for both ingress.rules.host and ingress.tls.hosts. If you have more than one, you'll need to set overrides for the rules and tls separately. |
| ingress.rules[0].host | string | `"{{ tpl $.Values.ingress.hostname $ }}"` |  |
| ingress.rules[0].paths[0].path | string | `"/"` |  |
| ingress.rules[0].paths[0].pathType | string | `"Prefix"` |  |
| ingress.servicePort | string | `"https"` |  |
| ingress.tls[0].secretName | string | `""` |  |
| keyStoreFormat | string | `"PKCS12"` | For the keystore specified in keyStoreSecret, the keystore format (PKCS12 or JKS). This value will be ignored if the keyStoreSecret value is not set. |
| keyStoreSecret | string | `nil` | Secret containing the FHIR server keystore file and its password. The secret must contain the keys ''fhirKeyStore' (the keystore file contents in the format specified in keyStoreFormat) and 'fhirKeyStorePassword' (the keystore password) |
| keycloak.adminPassword | string | `"change-password"` | An initial keycloak admin password for creating the initial Keycloak admin user |
| keycloak.adminUsername | string | `"admin"` | An initial keycloak admin username for creating the initial Keycloak admin user |
| keycloak.config.enabled | bool | `true` |  |
| keycloak.config.image.pullPolicy | string | `"IfNotPresent"` |  |
| keycloak.config.image.repository | string | `"quay.io/alvearie/keycloak-config"` |  |
| keycloak.config.image.tag | string | `"0.4.1"` |  |
| keycloak.config.realms.test.clients.inferno.clientAuthenticatorType | string | `"client-secret"` |  |
| keycloak.config.realms.test.clients.inferno.consentRequired | bool | `true` |  |
| keycloak.config.realms.test.clients.inferno.defaultScopes[0] | string | `"launch/patient"` |  |
| keycloak.config.realms.test.clients.inferno.optionalScopes | list | all scopes defined by the `security.oauth` configuration. | OAuth 2.0 scopes supported by this client |
| keycloak.config.realms.test.clients.inferno.publicClient | bool | `true` |  |
| keycloak.config.realms.test.clients.inferno.redirectURIs[0] | string | `"http://localhost:4567/inferno/*"` |  |
| keycloak.config.realms.test.clients.inferno.serviceAccountsEnabled | bool | `false` |  |
| keycloak.config.realms.test.clients.inferno.standardFlowEnabled | bool | `true` |  |
| keycloak.config.realms.test.clients.infernoBulk.clientAuthenticatorType | string | `"client-jwt"` |  |
| keycloak.config.realms.test.clients.infernoBulk.consentRequired | bool | `false` |  |
| keycloak.config.realms.test.clients.infernoBulk.defaultScopes | list | `[]` |  |
| keycloak.config.realms.test.clients.infernoBulk.jwksUrl | string | `""` |  |
| keycloak.config.realms.test.clients.infernoBulk.optionalScopes | list | all scopes defined by the `security.oauth` configuration. | OAuth 2.0 scopes supported by this client |
| keycloak.config.realms.test.clients.infernoBulk.publicClient | bool | `false` |  |
| keycloak.config.realms.test.clients.infernoBulk.serviceAccountsEnabled | bool | `true` |  |
| keycloak.config.realms.test.clients.infernoBulk.standardFlowEnabled | bool | `false` |  |
| keycloak.config.ttlSecondsAfterFinished | int | `100` |  |
| keycloak.enabled | bool | `false` |  |
| keycloak.extraEnv | string | DB_VENDOR set to postgres and KEYCLOAK_USER_FILE/KEYCLOAK_PASSWORD_FILE set to the keycloak-admin mountPath | Extra environment variables for the Keycloak StatefulSet |
| keycloak.extraVolumeMounts | string | mount the keycloak-admin volume at /secrets/keycloak-admin | Extra volume mounts for the Keycloak StatefulSet |
| keycloak.extraVolumes | string | a single volume named keycloak-admin with contents from the keycloak-admin-secret | Extra volumes for the Keycloak StatefulSets |
| keycloak.image.pullPolicy | string | `"IfNotPresent"` |  |
| keycloak.image.repository | string | `"quay.io/alvearie/smart-keycloak"` |  |
| keycloak.image.tag | string | `"0.4.1"` |  |
| keycloak.postgresql.nameOverride | string | `"keycloak-postgres"` |  |
| keycloakConfigTemplate | string | `"defaultKeycloakConfig"` | Template with keycloak-config.json input for the Alvearie keycloak-config project |
| maxHeap | string | `""` | The value passed to the JVM via -Xmx to set the max heap size. |
| minHeap | string | The default minHeap in the ibm-fhir-server image; 768m in IBM FHIR Server 4.10.2 | The value passed to the JVM via -Xms to set the initial heap size. |
| nameOverride | string | `nil` | Optional override for chart name portion of the created kube resources |
| nodeSelector | object | `{}` | Node labels for Pod assignment |
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
| postgresql.containerSecurityContext.allowPrivilegeEscalation | bool | `false` |  |
| postgresql.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| postgresql.enabled | bool | `true` | enable an included PostgreSQL DB. if set to `false`, the connection settings under the `db` key are used |
| postgresql.existingSecret | string | `""` | Name of existing secret to use for PostgreSQL passwords. The secret must contain the keys `postgresql-password` (the password for `postgresqlUsername` when it is different from `postgres`), `postgresql-postgres-password` (which will override `postgresqlPassword`), `postgresql-replication-password` (which will override `replication.password`), and `postgresql-ldap-password` (used to authenticate on LDAP). The value is evaluated as a template. |
| postgresql.image.tag | string | `"14.1.0"` | the tag for the postgresql image |
| postgresql.postgresqlDatabase | string | `"fhir"` | name of the database to create. see: <https://github.com/bitnami/bitnami-docker-postgresql/blob/master/README.md#creating-a-database-on-first-run> |
| postgresql.postgresqlExtendedConf | object | `{"maxPreparedTransactions":24}` | Extended Runtime Config Parameters (appended to main or default configuration) |
| replicaCount | int | `2` | The number of replicas for the externally-facing FHIR server pods |
| resources.limits.ephemeral-storage | string | `"1Gi"` |  |
| resources.limits.memory | string | `"4Gi"` |  |
| resources.requests.ephemeral-storage | string | `"1Gi"` |  |
| resources.requests.memory | string | `"1Gi"` |  |
| restrictEndpoints | bool | `false` | Set to true to restrict the API to a particular set of resource type endpoints |
| schemaMigration.enabled | bool | `true` | Whether to execute a schema creation/migration job as part of the deploy |
| schemaMigration.image.pullPolicy | string | `"IfNotPresent"` | When to pull the image |
| schemaMigration.image.pullSecret | string | `"all-icr-io"` |  |
| schemaMigration.image.repository | string | `"ibmcom/ibm-fhir-schematool"` | The repository to pull the IBM FHIR Schema Tool image from |
| schemaMigration.image.tag | string | this chart's appVersion | IBM FHIR Schema Tool container image tag |
| schemaMigration.resources | object | `{}` | container resources for the schema migration job |
| schemaMigration.ttlSecondsAfterFinished | int | `100` | How many seconds to wait before cleaning up a finished schema migration job. This automatic clean-up can have unintended interactions with CI tools like ArgoCD; setting this value to nil will disable the feature. |
| security.jwtValidation.audience | string | `"https://{{ tpl $.Values.ingress.hostname $ }}/fhir-server/api/v4"` |  |
| security.jwtValidation.enabled | bool | `false` |  |
| security.jwtValidation.groupNameAttribute | string | `"group"` |  |
| security.jwtValidation.issuer | string | `"https://{{ tpl $.Values.ingress.hostname $ }}/auth/realms/test"` |  |
| security.jwtValidation.jwksUri | string | `"http://{{ template \"keycloak.fullname\" .Subcharts.keycloak }}-http/auth/realms/test/protocol/openid-connect/certs"` |  |
| security.jwtValidation.usersGroup | string | `"fhirUser"` |  |
| security.oauth.authUrl | string | `"https://{{ tpl $.Values.ingress.hostname $ }}/auth/realms/test/protocol/openid-connect/auth"` |  |
| security.oauth.enabled | bool | `false` |  |
| security.oauth.offlineAccessScopeEnabled | bool | `true` |  |
| security.oauth.onlineAccessScopeEnabled | bool | `true` |  |
| security.oauth.profileScopeEnabled | bool | `true` |  |
| security.oauth.regUrl | string | `"https://{{ tpl $.Values.ingress.hostname $ }}/auth/realms/test/clients-registrations/openid-connect"` |  |
| security.oauth.smart.capabilities | list | sso-openid-connect, launch-standalone, client-public, client-confidential-symmetric, permission-offline, context-standalone-patient, and permission-patient | SMART capabilities to advertise from the server |
| security.oauth.smart.enabled | bool | `false` |  |
| security.oauth.smart.fhirUserScopeEnabled | bool | `true` |  |
| security.oauth.smart.launchPatientScopeEnabled | bool | `true` |  |
| security.oauth.smart.resourceScopes | list | read access to number of resource types. | SMART resource scopes to advertise from the server |
| security.oauth.tokenUrl | string | `"https://{{ tpl $.Values.ingress.hostname $ }}/auth/realms/test/protocol/openid-connect/token"` |  |
| securityContext | object | `{}` | pod security context for the server |
| serverRegistryResourceProviderEnabled | bool | `false` | Indicates whether the server registry resource provider should be used by the FHIR registry component to access definitional resources through the persistence layer |
| tolerations | list | `[]` | Node taints to tolerate |
| topologySpreadConstraints | string | `nil` | Topology spread constraints template |
| traceSpec | string | `"*=info"` | The trace specification to use for selectively tracing components of the IBM FHIR Server. The log detail level specification is in the following format: `component1=level1:component2=level2` See https://openliberty.io/docs/latest/log-trace-configuration.html for more information. |
| transactionTimeout | string | `"120s"` |  |
| trustStoreFormat | string | `"PKCS12"` | For the truststore specified in trustStoreSecret, the truststore format (PKCS12 or JKS). This value will be ignored if the trustStoreSecret value is not set. |
| trustStoreSecret | string | `nil` | Secret containing the FHIR server truststore file and its password. The secret must contain the keys 'fhirTrustStore' (the truststore file contents in the format specified in trustStoreFormat) and 'fhirTrustStorePassword' (the truststore password) |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
