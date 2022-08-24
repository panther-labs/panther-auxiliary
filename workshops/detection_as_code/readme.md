## panther_analysis_tool (PAT)
```
$ pip install panther_analysis_tool

$ panther_analysis_tool --version
$ panther_analysis_tool check-connection --api-host DOMAIN --api-token TOKEN
$ panther_analysis_tool test --path custom_okta_rules/
$ panther_analysis_tool upload --path custom_okta_rules/ --api-host DOMAIN --api-token TOKEN
```

## Detection Rep Clone
```
$ mkdir detection-workshop && cd detection-workshop 
$ git clone https://github.com/panther-labs/panther-analysis.git 
$ mkdir panther-analysis/custom_okta_rules && cd panther-analysis
$ cp okta_rules/okta_api_key_revoked.* custom_okta_rules/
```

## Sample Event 1 - API Revoked
```
{
	"actor": {
		"alternateId": "user@example.com",
		"displayName": "Test User",
		"id": "00u3q14ei6KUOm4Xi2p4",
		"type": "User"
	},
	"debugContext": {},
	"displayMessage": "Revoke API token",
	"eventType": "system.api_token.revoke",
	"legacyEventType": "api.token.revoke",
	"outcome": {
		"result": "SUCCESS"
	},
	"published": "2021-01-08 21:28:34.875",
	"request": {},
	"severity": "INFO",
	"target": [{
		"alternateId": "unknown",
		"details": null,
		"displayName": "test_key",
		"id": "00Tpki36zlWjhjQ1u2p4",
		"type": "Token"
	}],
	"uuid": "2a992f80-d1ad-4f62-900e-8c68bb72a21b",
	"version": "0"
}
```

## Sample Event 2 - API Created
```
{
	"actor": {
		"alternateid": "user@example.com",
		"displayname": "Test User",
		"id": "00ukqvyth9S0ebnmp5d6",
		"type": "User"
	},
	"eventType": "system.api_token.create",
	"legacyEventType": "api.token.create",
	"outcome": {
		"result": "SUCCESS"
	},
	"target": [
		{
			"id": "00Tm32hazYCWuKK0e5d6",
			"type": "Token",
			"alternateid": "unknown",
			"displayname": "example-token"
		}
	]
}
```

## Helpful links
[Panther Analysis Repo](https://github.com/panther-labs/panther-analysis)

[.py Template](https://github.com/panther-labs/panther-analysis/blob/master/templates/example_rule.py)

[.yml Template](https://github.com/panther-labs/panther-analysis/blob/master/templates/example_rule.yml)

[Docs: Writing Detections](https://docs.panther.com/writing-detections)

[CI/CD Onboarding Guide](https://docs.panther.com/guides/ci-cd-onboarding-guide)

[Github Actions Onboarding Guide](https://docs.panther.com/guides/github-actions-onboarding-guide)
