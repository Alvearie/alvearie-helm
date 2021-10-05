
![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.9.2](https://img.shields.io/badge/AppVersion-4.9.2-informational?style=flat-square)

# The IBM FHIR Server Helm Chart

The [IBM FHIR Server](https://ibm.github.io/FHIR) implements version 4 of the HL7 FHIR specification
with a focus on performance and configurability.

This helm chart will help you install the IBM FHIR Server in a Kubernetes environment and uses
ConfigMaps and Secrets to support the wide range of configuration options available for the server.

## Sample usage

```sh
helm repo add alvearie https://alvearie.io/alvearie-helm
helm upgrade --install --render-subchart-notes ibm-fhir-server alvearie/ibm-fhir-server --values values.yaml --set 'ingress.hostname=example.com' --set 'ingress.tls[0].secretName=cluster-tls-secret'
```

This will install the latest version if the IBM FHIR Server using an included PostgreSQL database for persistence.

## Customizing the FHIR server configuration
This helm chart uses a [named template](https://helm.sh/docs/chart_template_guide/named_templates/) to generate the `fhir-server-config.json` file which will control the configuration of the deployed FHIR server. The template name is `defaultFhirServerConfig` and it is defined in the `_fhirServerConfigJson.tpl` file. It uses many of this helm chart's values as the values of config properties within the generated `fhir-server-config.json` file.

This design gives the deployer of this helm chart a number of different options to customize the FHIR server configuration:
1. Use the `defaultFhirServerConfig` named template that is provided, but override values specified in the template to customize the configuration. Chart values are used to customize config properties in the following sections of the configuration:
    - core
    - resources
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
| datasourcesTemplate | string | `"defaultPostgresDatasources"` | Template containing the datasources.xml content |
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
| endpoints[0].interactions | list | All interactions. | The set of enabled interactions for this resource type: [create, read, vread, history, search, update, patch, delete] |
| endpoints[0].profiles | list | `nil` | Instances of this type must claim conformance to at least one of the listed profiles; nil means no profile conformance required |
| endpoints[0].resourceType | string | `"Resource"` | A valid FHIR resource type; use "Resource" for whole-system behavior |
| endpoints[0].searchIncludes | list | `nil` | Valid _include arguments while searching this resource type; nil means no restrictions |
| endpoints[0].searchParameters | list | `[{"code":"*","url":"*"}]` | A mapping from enabled search parameter codes to search parameter definitions |
| endpoints[0].searchRevIncludes | list | `nil` | Valid _revInclude arguments while searching this resource type; nil means no restrictions |
| extensionSearchParametersTemplate | string | `"defaultSearchParameters"` | Template containing the extension-search-parameters.json content |
| extraEnv | string | `""` |  |
| extraJvmOptions | string | `""` |  |
| extraLabels | object | `{}` | Extra labels to apply to the created kube resources |
| fhirAdminPassword | string | `"change-password"` | The fhirAdminPassword. If fhirPasswordSecret is set, the fhirAdminPassword will be set from its contents. |
| fhirAdminPasswordSecretKey | string | `nil` | For the Secret specified in fhirPasswordSecret, the key of the key/value pair containing the fhirAdminPassword. This value will be ignored if the fhirPasswordSecret value is not set. |
| fhirPasswordSecret | string | `nil` | The name of a Secret from which to retrieve fhirUserPassword and fhirAdminPassword. If this value is set, it is expected that fhirUserPasswordSecretKey and fhirAdminPasswordSecretKey will also be set. |
| fhirServerConfigTemplate | string | `"defaultFhirServerConfig"` | Template containing the fhir-server-config.json content |
| fhirUserPassword | string | `"change-password"` | The fhirUserPassword. If fhirPasswordSecret is set, the fhirUserPassword will be set from its contents. |
| fhirUserPasswordSecretKey | string | `nil` | For the Secret specified in fhirPasswordSecret, the key of the key/value pair containing the fhirUserPassword. This value will be ignored if the fhirPasswordSecret value is not set. |
| fullnameOverride | string | `nil` | Optional override for the fully qualified name of the created kube resources |
| image.pullPolicy | string | `"Always"` |  |
| image.repository | string | `"ibmcom/ibm-fhir-server"` |  |
| image.tag | string | `"4.9.2"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `true` |  |
| ingress.hostname | string | `"{{ .Release.Name }}.example.com"` | The default cluster hostname, used for both ingress.rules.host and ingress.tls.hosts. If you have more than one, you'll need to set overrides for the rules and tls separately. |
| ingress.rules[0].host | string | `"{{ tpl $.Values.ingress.hostname $ }}"` |  |
| ingress.rules[0].paths[0] | string | `"/"` |  |
| ingress.servicePort | string | `"https"` |  |
| ingress.tls[0].secretName | string | `""` |  |
| maxHeap | string | `"4096m"` |  |
| minHeap | string | `"1024m"` |  |
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
| postgresql.containerSecurityContext.allowPrivilegeEscalation | bool | `false` |  |
| postgresql.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| postgresql.enabled | bool | `true` | enable an included PostgreSQL DB. if set to `false`, the connection settings under the `db` key are used |
| postgresql.existingSecret | string | `""` | Name of existing secret to use for PostgreSQL passwords. The secret must contain the keys `postgresql-password` (the password for `postgresqlUsername` when it is different from `postgres`), `postgresql-postgres-password` (which will override `postgresqlPassword`), `postgresql-replication-password` (which will override `replication.password`), and `postgresql-ldap-password` (used to authenticate on LDAP). The value is evaluated as a template. |
| postgresql.image.tag | string | `"13.4.0-debian-10-r37"` | the tag for the postgresql image |
| postgresql.postgresqlDatabase | string | `"fhir"` | name of the database to create. see: <https://github.com/bitnami/bitnami-docker-postgresql/blob/master/README.md#creating-a-database-on-first-run> |
| postgresql.postgresqlExtendedConf | object | `{"maxPreparedTransactions":24}` | Extended Runtime Config Parameters (appended to main or default configuration) |
| replicaCount | int | `2` | The number of replicas for the externally-facing FHIR server pods |
| resources.limits.ephemeral-storage | string | `"1Gi"` |  |
| resources.limits.memory | string | `"5Gi"` |  |
| resources.requests.ephemeral-storage | string | `"1Gi"` |  |
| resources.requests.memory | string | `"2Gi"` |  |
| restrictEndpoints | bool | `false` | Set to true to restrict the API to a particular set of resource type endpoints |
| schemaMigration.enabled | bool | `true` |  |
| schemaMigration.image.pullPolicy | string | `"Always"` |  |
| schemaMigration.image.pullSecret | string | `"all-icr-io"` |  |
| schemaMigration.image.repository | string | `"ibmcom/ibm-fhir-schematool"` |  |
| schemaMigration.image.tag | string | `"4.9.1"` |  |
| security.oauthAuthUrl | string | `nil` |  |
| security.oauthEnabled | bool | `false` |  |
| security.oauthRegUrl | string | `nil` |  |
| security.oauthTokenUrl | string | `nil` |  |
| security.smartCapabilities | list | sso-openid-connect, launch-standalone, client-public, client-confidential-symmetric, permission-offline, context-standalone-patient, and permission-patient | SMART capabilities to advertise from the server |
| security.smartEnabled | bool | `false` |  |
| security.smartScopes | list | openid, profile, fhirUser, launch/patient, offline_access, and a set of patient/<resource>.read scopes for a number of resource types. | OAuth 2.0 scopes to advertise from the server |
| serverRegistryResourceProviderEnabled | bool | `false` | Indicates whether the server registry resource provider should be used by the FHIR registry component to access definitional resources through the persistence layer |
| traceSpec | string | `"*=info"` | The trace specification to use for selectively tracing components of the IBM FHIR Server. The log detail level specification is in the following format: `component1=level1:component2=level2` See https://openliberty.io/docs/latest/log-trace-configuration.html for more information. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
