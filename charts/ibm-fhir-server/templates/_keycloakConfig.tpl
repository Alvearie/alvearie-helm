{{/* vim: set filetype=mustache: */}}

{{/*
Helper method for constructing a SMART scope string from a dict with patient, user, and system scopes
*/}}
{{- define "scopeListFIXME" -}}
  {{- range $context, $value := . }}
    {{- range $i, $patientScope := $value }}
      {{- if ne $i 0 }}, {{ end -}}
      {{- range $j, $resourceType := $patientScope.resourceTypes }}
        {{- if ne $j 0 }}, {{ end -}}
        "{{ $context }}/{{ $resourceType }}.{{ $patientScope.permission }}"
      {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "scopeList" -}}
  {{- range $i, $patientScope := .patient }}
    {{- if ne $i 0 }}, {{ end }}
    {{- range $j, $resourceType := $patientScope.resourceTypes }}
      {{- if ne $j 0 }}, {{ end -}}
      "patient/{{ $resourceType }}.{{ $patientScope.permission }}"
    {{- end }}
  {{- end }}
  {{- if .patient }}, {{ end }}
  {{- range $i, $userScope := .user }}
    {{- range $j, $resourceType := $userScope.resourceTypes }}
      {{- if ne $j 0 }}, {{ end -}}
      "user/{{ $resourceType }}.{{ $userScope.permission }}"
    {{- end }}
  {{- end }}
  {{- if or .patient .user }}, {{ end }}
  {{- range $i, $systemScope := .system }}
    {{- if ne $i 0 }}, {{ end }}
    {{- range $j, $resourceType := $systemScope.resourceTypes }}
      {{- if ne $j 0 }}, {{ end -}}
      "system/{{ $resourceType }}.{{ $systemScope.permission }}"
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Helper method for constructing scope description / consent text
*/}}
{{- define "scopeText" -}}
{{- if eq .permission "*" -}}
  Read/write
{{- else -}}
  {{ .permission }}
{{- end }} access to all{{ if ne .resourceType "*" }} {{ .resourceType }}{{ end }} data for the {{ .context }}
{{- end -}}

{{/*
Helper method for constructing the scope definition
*/}}
{{- define "scopeDef" -}}
"{{ .context }}/{{ .resourceType }}.{{ .permission }}": {
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
The default keycloak-config.json.
*/}}
{{- define "defaultKeycloakConfig" -}}
    {
      "keycloak": {
        "serverUrl": "http://{{ template "keycloak.fullname" .Subcharts.keycloak }}-http/auth",
        "adminUser": "{{ .Values.keycloak.adminUsername }}",
        "adminPassword": "${KEYCLOAK_PASSWORD}",
        "adminClientId": "admin-cli",
        "realms": {
          {{- range $realmName, $realmConfig := .Values.keycloak.realms }}
          "{{ $realmName }}": {
            "enabled": true,
            "clientScopes": {
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
              "online_access": {
                "protocol": "openid-connect",
                "description": "Request a refresh_token that can be used to obtain a new access token to replace an expired one, and that will be usable for as long as the end-user remains online.",
                "attributes": {
                  "consent.screen.text": "Retain access while you are online"
                }
              }
              {{- range $patientScope := $realmConfig.scopes.patient }},
              {{- range $j, $resourceType := $patientScope.resourceTypes }}
              {{- if ne $j 0 }},{{ end }}
              {{- $scope := dict "context" "patient" "resourceType" $resourceType "permission" $patientScope.permission }}
              {{- include "scopeDef" $scope | nindent 14 }}
              {{- end }}
              {{- end }}
              {{- range $userScope := $realmConfig.scopes.user }},
              {{- range $j, $resourceType := $userScope.resourceTypes }}
              {{- if ne $j 0 }},{{ end }}
              {{- $scope := dict "context" "user" "resourceType" $resourceType "permission" $userScope.permission }}
              {{- include "scopeDef" $scope | nindent 14 }}
              {{- end }}
              {{- end }}
              {{- range $systemScope := $realmConfig.scopes.system }},
              {{- range $j, $resourceType := $systemScope.resourceTypes }}
              {{- if ne $j 0 }},{{ end }}
              {{- $scope := dict "context" "system" "resourceType" $resourceType "permission" $systemScope.permission }}
              {{- include "scopeDef" $scope | nindent 14 }}
              {{- end }}
              {{- end }}
            },
            "defaultDefaultClientScopes": ["launch/patient"],
            "defaultOptionalClientScopes": [
              "fhirUser",
              "offline_access",
              "online_access",
              "profile",
              {{ include "scopeList" $realmConfig.scopes }}
            ],
            "clients": {
              "inferno": {
                "consentRequired": true,
                "publicClient": true,
                "bearerOnly": false,
                "enableDirectAccess": false,
                "rootURL": "http://localhost:4567/inferno",
                "redirectURIs": ["http://localhost:4567/inferno/*",
                "http://localhost:4567/inferno/*"],
                "adminURL": "http://localhost:4567/inferno",
                "webOrigins": ["http://localhost:4567"],
                "defaultClientScopes": ["launch/patient"],
                "optionalClientScopes": [
                  "fhirUser",
                  "offline_access",
                  "online_access",
                  "profile",
                  {{ include "scopeList" $realmConfig.scopes }}
                ]
              },
              "infernoBulk": {
                "consentRequired": false,
                "publicClient": false,
                "standardFlowEnabled": false,
                "serviceAccountsEnabled": true,
                "clientAuthenticatorType": "client-jwt",
                "attributes": {
                  "use.jwks.url": "true",
                  "jwks.url": "https://apache/inferno.public.json"
                },
                "rootURL": "http://localhost:4567/inferno",
                "redirectURIs": ["http://localhost:4567/inferno/*",
                "http://localhost:4567/inferno2/*"],
                "adminURL": "http://localhost:4567/inferno",
                "webOrigins": ["http://localhost:4567"],
                "defaultClientScopes": ["system/*.read"],
                "optionalClientScopes": [
                  {{- range $i, $systemScope := $realmConfig.scopes.system }}
                    {{- if ne $i 0 }}, {{ end }}
                    {{- range $j, $resourceType := $systemScope.resourceTypes }}
                      {{- if ne $j 0 }}, {{ end -}}
                      "system/{{ $resourceType }}.{{ $systemScope.permission }}"
                    {{- end }}
                  {{- end -}}
                ]
              }
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
