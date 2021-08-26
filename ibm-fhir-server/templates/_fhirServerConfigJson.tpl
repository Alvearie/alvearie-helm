{{/* vim: set filetype=mustache: */}}
{{/*
The default fhir-server-config.json.
*/}}
{{- define "fhirServerConfigJsonDefault" }}
    {
        "__comment": "FHIR Server configuration",
        "fhirServer": {
            "core": {
                "tenantIdHeaderName": "X-FHIR-TENANT-ID",
                "datastoreIdHeaderName": "X-FHIR-DSID",
                "originalRequestUriHeaderName": "X-FHIR-FORWARDED-URL",
                "checkReferenceTypes": true,
                "conditionalDeleteMaxNumber": 10,
                "serverRegistryResourceProviderEnabled": {{ .Values.serverRegistryResourceProviderEnabled }},
                "disabledOperations": ""
            },
            "search": {
                "useStoredCompartmentParam": true
            },
            "resources": {
                "open": {{ not .Values.restrictEndpoints }}
                {{- range $i, $endpoint := .Values.endpoints }}
                {{- if $endpoint.resourceType }},
                "{{ $endpoint.resourceType }}": {
                    {{- if $endpoint.searchIncludes }}
                    "searchIncludes": {{ toJson $endpoint.searchIncludes }}
                    {{- end}}
                    {{- if $endpoint.searchRevIncludes }}
                    {{- if $endpoint.searchIncludes }},{{- end }}
                    "searchRevIncludes": {{ toJson $endpoint.searchRevIncludes }}
                    {{- end}}
                    {{- if $endpoint.profiles }}
                    {{- if or $endpoint.searchIncludes $endpoint.searchRevIncludes }},{{- end }}
                    "profiles": {
                        "atLeastOne": {{ toJson $endpoint.profiles }}
                    }
                    {{- end}}
                    {{- if $endpoint.searchParameters }}
                    {{- if or $endpoint.searchIncludes $endpoint.searchRevIncludes $endpoint.searchProfiles }},{{- end }}
                    "searchParameters": {
                        {{- $lastIndex := sub (len $endpoint.searchParameters) 1 }}
                        {{- range $j, $param := $endpoint.searchParameters }}
                        "{{ $param.code }}": "{{ $param.url }}"{{ if not (eq $j $lastIndex) }},{{ end }}
                        {{- end }}
                    }
                    {{- end}}
                    {{- if $endpoint.interactions }}
                    {{- if or $endpoint.searchIncludes $endpoint.searchRevIncludes $endpoint.searchProfiles $endpoint.searchParameters }},{{- end }}
                    "interactions": {{ toJson $endpoint.interactions }}
                    {{- end}}
                }
                {{- end }}
                {{- end }}
            },
            "security": {
                "cors": true,
                "basic": {
                    "enabled": true
                },
                "certificates": {
                    "enabled": true
                },
                "oauth": {
                    "enabled": false,
                    "regUrl": "https://<host>:9443/oauth2/endpoint/oauth2-provider/registration",
                    "authUrl": "https://<host>:9443/oauth2/endpoint/oauth2-provider/authorize",
                    "tokenUrl": "https://<host>:9443/oauth2/endpoint/oauth2-provider/token",
                    "smart": {
                        "enabled": false,
                        "scopes": ["openid", "profile", "fhirUser", "launch/patient", "patient/*.*", "offline_access"],
                        "capabilities": [
                            "sso-openid-connect",
                            "launch-standalone",
                            "client-public",
                            "client-confidential-symmetric",
                            "permission-offline",
                            "context-standalone-patient",
                            "permission-patient"
                        ]
                    }
                }
            },
            "notifications": {
                "common": {
                    "__comment_includeResourceTypes": [
                        "QuestionnaireResponse",
                        "CarePlan",
                        "MedicationAdministration",
                        "Device",
                        "DeviceComponent",
                        "DeviceMetric",
                        "MedicationOrder",
                        "Observation"
                    ]
                },
                "websocket": {
                    "__comment": "only enable this for single-tenant, single-server deployments",
                    "enabled": false
                },
                "kafka": {
                    {{- if .Values.notifications.kafka.enabled }}
                    "enabled": true,
                    {{- else }}
                    "enabled": false,
                    {{- end }}
                    "topicName": "{{ .Values.notifications.kafka.topicName }}",
                    "connectionProperties": {
                        "group.id": "securing-kafka-group",
                        "bootstrap.servers": "{{ .Values.notifications.kafka.bootstrapServers }}",
                        "sasl.jaas.config": "{{ .Values.notifications.kafka.saslJaasConfig }}",
                        "sasl.mechanism": "{{ .Values.notifications.kafka.saslMechanism }}",
                        "security.protocol": "{{ .Values.notifications.kafka.securityProtocol }}",
                        "ssl.protocol": "{{ .Values.notifications.kafka.sslProtocol }}",
                        "ssl.enabled.protocols": "{{ .Values.notifications.kafka.sslEnabledProtocols }}",
                        "ssl.endpoint.identification.algorithm": "{{ .Values.notifications.kafka.sslEndpointIdentificationAlgorithm }}"
                        "ssl.truststore.location": "resources/security/kafka.client.truststore.p12",
                        "ssl.truststore.password": "change-password",
                        "ssl.keystore.location": "resources/security/kafka.client.keystore.p12",
                        "ssl.keystore.password": "change-password",
                        "ssl.key.password": "change-password",
                        "ssl.truststore.type": "PKCS12",
                        "ssl.keystore.type": "PKCS12",
                        "acks": "all",
                        "retries": "60",
                        "request.timeout.ms": "10000",
                        "max.block.ms": "60000",
                        "max.in.flight.requests.per.connection": "5"
                    }
                },
                "nats": {
                    {{- if .Values.notifications.nats.enabled }}
                    "enabled": true,
                    {{- else }}
                    "enabled": false,
                    {{- end }}
                    "cluster": "{{ .Values.notifications.nats.cluster }}",
                    "channel": "{{ .Values.notifications.nats.channel }}",
                    "clientId": "{{ .Values.notifications.nats.clientId }}",
                    "servers": "{{ .Values.notifications.nats.servers }}",
                    {{- if .Values.notifications.nats.useTLS }}
                    "useTLS": false,
                    {{- else }}
                    "enabled": false,
                    {{- end }}
                    "truststoreLocation": "resources/security/nats.client.truststore.jks",
                    "truststorePassword": "change-password",
                    "keystoreLocation": "resources/security/nats.client.keystore.jks",
                    "keystorePassword": "change-password"
                }
            },
            "audit": {
                {{- if .Values.audit.enabled }}
                "serviceClassName" : "com.ibm.fhir.audit.impl.KafkaService",
                "serviceProperties" : {
                    "load": "config",
                    "mapper": "{{ .Values.audit.type }}",
                    "auditTopic": "{{ .Values.audit.topic }}",
                    "geoCity": "{{ .Values.audit.geoCity }}",
                    "geoState": "{{ .Values.audit.geoState }}",
                    "geoCounty": "{{ .Values.audit.geoCountry }}",
                    "kafka" : {
                        "bootstrap.servers": "{{ .Values.audit.kafka.bootstrapServers }}",
                        "sasl.jaas.config": "{{ .Values.audit.kafka.saslJaasConfig }}",
                        "sasl.mechanism": "{{ .Values.audit.kafka.saslMechanism }}",
                        "security.protocol": "{{ .Values.audit.kafka.securityProtocol }}",
                        "ssl.protocol": "{{ .Values.audit.kafka.sslProtocol }}",
                        "ssl.enabled.protocols": "{{ .Values.audit.kafka.sslEnabledProtocols }}",
                        "ssl.endpoint.identification.algorithm": "{{ .Values.audit.kafka.sslEndpointIdentificationAlgorithm }}"
                    },
                    "kafkaServers": "{{ .Values.audit.kafkaServers }}",
                    "kafkaApiKey": "{{ .Values.audit.kafkaApiKey }}"
                }
                {{- else }}
                "serviceClassName" : "com.ibm.fhir.audit.impl.NopService",
                "serviceProperties" : {
                }
                {{- end }}
            },
            "persistence": {
                "factoryClassname": "com.ibm.fhir.persistence.jdbc.FHIRPersistenceJDBCFactory",
                "common": {
                    "__comment": "Configuration properties common to all persistence layer implementations",
                    "updateCreateEnabled": true
                },
                "jdbc": {
                    "__comment": "Configuration properties for the JDBC persistence implementation",
                    "enableCodeSystemsCache": true,
                    "enableParameterNamesCache": true,
                    "enableResourceTypesCache": true
                },
                "datasources": {
                    "default": {
                        "type": "{{ .Values.db.type }}",
                        "currentSchema": "{{ .Values.db.schema }}"
                        {{- if eq .Values.db.type "derby" }}
                        "jndiName": "jdbc/bootstrap_default_default",
                        {{- else if eq .Values.db.type "postgresql" }}
                        "searchOptimizerOptions": {
                            "from_collapse_limit": 12,
                            "join_collapse_limit": 12
                        }
                        {{- else if eq .Values.db.type "db2" }}
                        "tenantKey": "{{ .Values.db.tenantKey }}",
                        "hints" : {
                          "search.reopt": "ONCE"
                        }
                        {{- end }}
                    }
                }
            },
            "bulkdata": {
                "enabled": true,
                "core": {
                    "api": {
                        "url": "https://localhost:9443/ibm/api/batch",
                        "user": "fhiradmin",
                        "password": "{{ .Values.fhirAdminPassword }}",
                        "truststore": "resources/security/fhirTrustStore.p12",
                        "truststorePassword": "change-password", 
                        "trustAll": true
                    },
                    "cos" : { 
                        "partUploadTriggerSizeMB": 10,
                        "objectSizeThresholdMB": 200,
                        "objectResourceCountThreshold": 200000,
                        "useServerTruststore": true,
                        "presignedExpiry": 86400
                    },
                    "file" : { 
                        "writeTriggerSizeMB": 1,
                        "sizeThresholdMB": 200,
                        "resourceCountThreshold": 200000
                    },
                    "pageSize": 100,
                    {{- if .Values.objectStorage.batchIdEncryptionKey }}
                    "batchIdEncryptionKey": {{ .Values.objectStorage.batchIdEncryptionKey }},
                    {{- else }}
                    "batchIdEncryptionKey": "change-password",
                    {{- end }}
                    "maxPartitions": 3, 
                    "maxInputs": 5,
                    "maxChunkReadTime": "90000",
                    "systemExportImpl": "fast",
                    "defaultExportProvider": "default",
                    "defaultImportProvider": "default"
                },
                "storageProviders": {
                    "default" : {
                        {{- if .Values.objectStorage.enabled }}
                        "type": "ibm-cos",
                        "bucketName": "{{ .Values.objectStorage.bulkDataBucketName }}",
                        "location": "${COS_LOCATION}",
                        "endpointInternal": "${COS_ENDPOINT_INTERNAL}",
                        "endpointExternal": "${COS_ENDPOINT_EXTERNAL}",
                        {{- else }}
                        "type": "file",
                        "_type": "ibm-cos|aws-s3|file|https|azure-blob",
                        "validBaseUrls": [],
                        "fileBase": "/output/bulkdata",
                        {{- end }}
                        "auth" : {
                            "type": "hmac",
                            "accessKeyId": "key",
                            "secretAccessKey": "secret"
                        },
                        "enableParquet": false,
                        "disableBaseUrlValidation": true,
                        "disableOperationOutcomes": true,
                        "duplicationCheck": false, 
                        "validateResources": false, 
                        "create": false,
                        "presigned": true
                    }
                }
            },
            "operations": {
                "erase": {
                    "enabled": true,
                    "allowedRoles": [
                        "FHIROperationAdmin",
                        "FHIRUsers"
                    ]
                }
            }
        }
    }
{{- end }}
