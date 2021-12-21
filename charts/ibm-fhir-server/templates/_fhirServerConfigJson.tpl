{{/* vim: set filetype=mustache: */}}
{{/*
The default fhir-server-config.json.
*/}}
{{- define "defaultFhirServerConfig" }}
    {
        "__comment": "FHIR Server configuration",
        "fhirServer": {
            "core": {
                "serverRegistryResourceProviderEnabled": {{ .Values.serverRegistryResourceProviderEnabled }},
                {{- if .Values.ingress.enabled }}
                "externalBaseUrl": "https://{{ tpl .Values.ingress.hostname $ }}/fhir-server/api/v4",
                {{- end}}
                "disabledOperations": "",
                "defaultPrettyPrint": true
            },
            "search": {
                "useStoredCompartmentParam": true
            },
            "resources": {
                "open": {{ not .Values.restrictEndpoints }}
                {{- range $endpoint, $conf := .Values.endpoints }},
                "{{ $endpoint }}": {{ toPrettyJson $conf | indent 16 }}
                {{- end }}
            },
            "security": {
                "cors": true,
                {{- if not .Values.security.oauth.enabled }}
                "basic": {
                    "enabled": true
                },
                "certificates": {
                    "enabled": true,
                    "authFilter": {
                        "enabled": false
                    }
                }
                {{- else }}
                "oauth": {
                    "enabled": true,
                    {{- if .Values.security.oauth.regUrl }}
                    "regUrl": {{ tpl .Values.security.oauth.regUrl $ | quote }},
                    {{- end }}
                    "authUrl": {{ tpl .Values.security.oauth.authUrl $ | quote }},
                    "tokenUrl": {{ tpl .Values.security.oauth.tokenUrl $ | quote }},
                    "smart": {
                        "enabled": {{ .Values.security.oauth.smart.enabled }},
                        "scopes": {{ include "scopeList" $ }},
                        "capabilities": {{ toJson .Values.security.oauth.smart.capabilities }}
                    }
                }
                {{- end }}
            },
            "notifications": {
                "kafka": {
                    {{- if not .Values.notifications.kafka.enabled }}
                    "enabled": false
                    {{- else }}
                    "enabled": true,
                    "topicName": "{{ .Values.notifications.kafka.topicName }}",
                    "connectionProperties": {
                        "bootstrap.servers": "{{ .Values.notifications.kafka.bootstrapServers }}",
                        "sasl.jaas.config": "{{ .Values.notifications.kafka.saslJaasConfig }}",
                        "sasl.mechanism": "{{ .Values.notifications.kafka.saslMechanism }}",
                        "security.protocol": "{{ .Values.notifications.kafka.securityProtocol }}",
                        "ssl.protocol": "{{ .Values.notifications.kafka.sslProtocol }}",
                        "ssl.enabled.protocols": "{{ .Values.notifications.kafka.sslEnabledProtocols }}",
                        "ssl.endpoint.identification.algorithm": "{{ .Values.notifications.kafka.sslEndpointIdentificationAlgorithm }}"
                    }
                    {{- end }}
                },
                "nats": {
                    {{- if not .Values.notifications.nats.enabled }}
                    "enabled": false
                    {{- else }}
                    "enabled": true,
                    "cluster": "{{ .Values.notifications.nats.cluster }}",
                    "channel": "{{ .Values.notifications.nats.channel }}",
                    "clientId": "{{ .Values.notifications.nats.clientId }}",
                    "servers": "{{ .Values.notifications.nats.servers }}"
                    {{- if .Values.notifications.nats.useTLS }},
                    "useTLS": true,
                    "truststoreLocation": "resources/security/nats.client.truststore.jks",
                    "truststorePassword": "change-password",
                    "keystoreLocation": "resources/security/nats.client.keystore.jks",
                    "keystorePassword": "change-password"
                    {{- end }}
                    {{- end }}
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
                        "currentSchema": "{{ .Values.db.schema }}",
                        {{- if eq .Values.db.type "derby" }}
                        "jndiName": "jdbc/bootstrap_default_default"
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
                {{- if not .Values.objectStorage.enabled }}
                "enabled": false
                {{- else }}
                "enabled": true,
                "core": {
                    "api": {
                        "url": "https://localhost:9443/ibm/api/batch",
                        "user": "fhiradmin",
                        "password": "${FHIR_ADMIN_PASSWORD}",
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
                    "pageSize": 100,
                    {{- if .Values.objectStorage.batchIdEncryptionKey }}
                    "batchIdEncryptionKey": {{ .Values.objectStorage.batchIdEncryptionKey }},
                    {{- end }}
                    "maxPartitions": 3,
                    "maxInputs": 5
                },
                "storageProviders": {
                    "default" : {
                        "type": "ibm-cos",
                        "location": "${COS_LOCATION}",
                        "endpointInternal": "${COS_ENDPOINT_INTERNAL}",
                        "endpointExternal": "${COS_ENDPOINT_EXTERNAL}",
                        "auth" : {
                            "type": "hmac",
                            "accessKeyId": "${COS_ACCESS_KEY}",
                            "secretAccessKey": "${COS_SECRET_KEY}"
                        },
                        "bucketName": "{{ .Values.objectStorage.bulkDataBucketName }}",
                        "disableOperationOutcomes": true,
                        "presigned": true
                    }
                }
                {{- end }}
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
