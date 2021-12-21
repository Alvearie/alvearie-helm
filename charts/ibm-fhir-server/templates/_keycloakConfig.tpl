{{/* vim: set filetype=mustache: */}}
{{/*
The default keycloak-config.json.
*/}}
{{- define "defaultKeycloakConfig" -}}
    {
      "keycloak": {
        {{- if .Values.keycloak.enabled }}
        "serverUrl": "http://{{ template "keycloak.fullname" $.Subcharts.keycloak }}-http/auth",
        {{- end }}
        "adminUser": "{{ .Values.keycloak.adminUsername }}",
        "adminPassword": "${KEYCLOAK_PASSWORD}",
        "adminClientId": "admin-cli",
        "realms": {
          {{- range $realmName, $realmConfig := .Values.keycloak.config.realms }}
          "{{ $realmName }}": {
            "enabled": true,
            "clientScopes": {
              {{- if $.Values.security.oauth.smart.fhirUserScopeEnabled }}
              "fhirUser": {
                "protocol": "openid-connect",
                "description": "Permission to retrieve current logged-in user",
                "attributes": {
                  "consent.screen.text": "Permission to retrieve current logged-in user"
                },
                "mappers": {
                  "fhirUser Mapper": {
                    "protocol": "openid-connect",
                    "protocolmapper": "oidc-patient-prefix-usermodel-attribute-mapper",
                    "config": {
                      "user.attribute": "resourceId",
                      "claim.name": "fhirUser",
                      "jsonType.label": "String",
                      "id.token.claim": "true",
                      "access.token.claim": "false",
                      "userinfo.token.claim": "true"
                    }
                  }
                }
              },
              {{- end }}
              {{- if $.Values.security.oauth.smart.launchPatientScopeEnabled }}
              "launch/patient": {
                "protocol": "openid-connect",
                "description": "Used by clients to request a patient-scoped access token",
                "attributes": {
                  "display.on.consent.screen": "false"
                },
                "mappers": {
                  "Patient ID Claim Mapper": {
                    "protocol": "openid-connect",
                    "protocolmapper": "oidc-usermodel-attribute-mapper",
                    "config": {
                      "user.attribute": "resourceId",
                      "claim.name": "patient_id",
                      "jsonType.label": "String",
                      "id.token.claim": "false",
                      "access.token.claim": "true",
                      "userinfo.token.claim": "false"
                    }
                  },
                  "Patient ID Token Mapper": {
                    "protocol": "openid-connect",
                    "protocolmapper": "oidc-usersessionmodel-note-mapper",
                    "config": {
                      "user.session.note": "patient_id",
                      "claim.name": "patient",
                      "jsonType.label": "String",
                      "id.token.claim": "false",
                      "access.token.claim": "false",
                      "access.tokenResponse.claim": "true"
                    }
                  },
                  "Group Membership Mapper": {
                    "protocol": "openid-connect",
                    "protocolmapper": "oidc-group-membership-mapper",
                    "config": {
                      "claim.name": "group",
                      "full.path": "false",
                      "id.token.claim": "true",
                      "access.token.claim": "true",
                      "userinfo.token.claim": "true"
                    }
                  }
                }
              },
              {{- end }}
              {{- if $.Values.security.oauth.onlineAccessScopeEnabled }}
              "online_access": {
                "protocol": "openid-connect",
                "description": "Request a refresh_token that can be used to obtain a new access token to replace an expired one, and that will be usable for as long as the end-user remains online.",
                "attributes": {
                  "consent.screen.text": "Retain access while you are online"
                }
              }
              {{- end }}
              {{- range $scope := $.Values.security.oauth.smart.resourceScopes }},
              {{- include "scopeDef" $scope | nindent 14 }}
              {{- end }}
            },
            "defaultDefaultClientScopes": [],
            "defaultOptionalClientScopes": {{ include "scopeList" $ }},
            "clients": {
              {{- $delim := "" }}
              {{- range $clientId, $clientConfig := $realmConfig.clients}}
              {{- $delim }}
              "{{ $clientId }}": {
                "consentRequired": {{ $clientConfig.consentRequired }},
                "publicClient": {{ $clientConfig.publicClient }},
                "redirectURIs": {{ toJson $clientConfig.redirectURIs }},
                "standardFlowEnabled": {{ $clientConfig.standardFlowEnabled }},
                "serviceAccountsEnabled": {{ $clientConfig.serviceAccountsEnabled }},
                "clientAuthenticatorType": "{{ $clientConfig.clientAuthenticatorType }}",
                {{- if $clientConfig.jwksUrl }}
                "attributes": {
                  "use.jwks.url": "true",
                  "jwks.url": "{{ $clientConfig.jwksUrl }}"
                },
                {{- end }}
                "defaultClientScopes": {{ toJson $clientConfig.defaultScopes }},
                "optionalClientScopes":
                  {{- if $clientConfig.optionalScopes }}
                    {{- toJson $clientConfig.optionalScopes }}
                  {{- else }}
                    {{- include "scopeList" $ }}
                  {{- end }}
              }
              {{- $delim = ","}}
              {{- end }}
            },
            "authenticationFlows": {
              "SMART App Launch": {
                "description": "browser based authentication",
                "providerId": "basic-flow",
                "builtIn": false,
                "authenticationExecutions": {
                  "SMART Login": {
                    "requirement": "ALTERNATIVE",
                    "userSetupAllowed": false,
                    "authenticatorFlow": true,
                    "description": "Username, password, otp and other auth forms.",
                    "providerId": "basic-flow",
                    "authenticationExecutions": {
                      "Audience Validation": {
                        "authenticator": "audience-validator",
                        "requirement": "DISABLED",
                        "priority": 10,
                        "authenticatorFlow": false,
                        "configAlias": "localhost",
                        "config": {
                          "audiences": "${FHIR_BASE_URL}"
                        }
                      },
                      "Username Password Form": {
                        "authenticator": "auth-username-password-form",
                        "requirement": "REQUIRED",
                        "priority": 20,
                        "authenticatorFlow": false
                      },
                      "Patient Selection Authenticator": {
                        "authenticator": "auth-select-patient",
                        "requirement": "REQUIRED",
                        "priority": 30,
                        "authenticatorFlow": false,
                        "configAlias": "internal.fhir.url",
                        "config": {
                          "internalFhirUrl": "${FHIR_BASE_URL}"
                        }
                      }
                    }
                  }
                }
              }
            },
            "browserFlow": "SMART App Launch",
            "groups": {
              "fhirUser": {
              }
            },
            "defaultGroups": ["fhirUser"],
            "users": {
              "fhiruser": {
                "enabled": true,
                "password": "change-password",
                "passwordTemporary": false,
                "attributes": {
                  "resourceId": ["Patient1"]
                },
                "groups": ["fhirUser"]
              }
            },
            "eventsConfig": {
              "saveLoginEvents": true,
              "expiration": 23328000,
              "types": [
                "FEDERATED_IDENTITY_LINK",
                "LOGOUT",
                "LOGIN_ERROR",
                "IDENTITY_PROVIDER_LINK_ACCOUNT",
                "REFRESH_TOKEN",
                "FEDERATED_IDENTITY_LINK_ERROR",
                "IDENTITY_PROVIDER_POST_LOGIN",
                "IDENTITY_PROVIDER_LINK_ACCOUNT_ERROR",
                "CODE_TO_TOKEN_ERROR",
                "IDENTITY_PROVIDER_FIRST_LOGIN",
                "REFRESH_TOKEN_ERROR",
                "IDENTITY_PROVIDER_POST_LOGIN_ERROR",
                "LOGOUT_ERROR",
                "CODE_TO_TOKEN",
                "LOGIN",
                "IDENTITY_PROVIDER_FIRST_LOGIN_ERROR"
              ],
              "saveAdminEvents": true
            }
          }
          {{- end }}
        }
      }
    }
{{- end -}}

{{/*
Helper method for constructing the scope definition for a SMART resource scope
*/}}
{{- define "scopeDef" -}}
"{{ . }}": {
  "protocol": "openid-connect",
  "description": "{{ include "scopeText" . }}",
  "attributes": {
    "consent.screen.text": "{{ include "scopeText" . }}"
  },
  "mappers": {
    "Audience Mapper": {
      "protocol": "openid-connect",
      "protocolmapper": "oidc-audience-mapper",
      "config": {
        "included.custom.audience": "${FHIR_BASE_URL}",
        "access.token.claim": "true"
      }
    }
  }
}
{{- end -}}

{{/*
Helper method for constructing the scope description / consent text for a SMART resource scope
*/}}
{{- define "scopeText" -}}
{{- $scopeParts := regexSplit "[/.]" . 3 }}
{{- $context := index $scopeParts 0 }}
{{- $resourceType := index $scopeParts 1 }}
{{- $permission := index $scopeParts 2 }}
{{- if eq $permission "*" -}}
  Read/write
{{- else -}}
  {{ $permission }}
{{- end }} access to all{{ if ne $resourceType "*" }} {{ $resourceType }}{{ end }} data for the {{ $context }}
{{- end -}}
