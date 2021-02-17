package bitte

import (
	"encoding/json"
	"tool/cli"
	"tool/os"
	"tool/exec"
	"tool/http"
	"strings"
)

#jobName:       string @tag(job)
#namespaceName: string @tag(namespace)

command: render: {
	env: os.Getenv & {
		NOMAD_NAMESPACE: string
	}

	display: cli.Print & {
		_job: rendered[env.NOMAD_NAMESPACE][#jobName]
		text: json.Indent(json.Marshal(_job), "", "  ")
	}
}

command: run: {
	environment: os.Getenv & {
		NOMAD_NAMESPACE:   "catalyst-dryrun" | "catalyst-fund3"
		CONSUL_HTTP_TOKEN: string
		NOMAD_ADDR:        string
		NOMAD_TOKEN:       string
	}

	vault_token: exec.Run & {
		cmd:    "vault print token"
		stdout: string
	}

	curl: http.Post & {
		url: "\(environment.NOMAD_ADDR)/v1/jobs"
		request: {
			header: {
				"X-Nomad-Token": environment.NOMAD_TOKEN
				"X-Vault-Token": strings.TrimSpace(vault_token.stdout)
			}
			body: json.Marshal(rendered[environment.NOMAD_NAMESPACE][#jobName] & {
				Job: ConsulToken: environment.CONSUL_HTTP_TOKEN
			})
		}
	}

	result: cli.Print & {
		text: curl.response.body
	}
}

command: list: {
	environment: os.Getenv & {
		NOMAD_NAMESPACE: "catalyst-dryrun" | "catalyst-fund3"
	}

	display: cli.Print & {
		_keys: [ for k, v in rendered[environment.NOMAD_NAMESPACE] {k}]
		text: json.Indent(json.Marshal(_keys), "", "  ")
	}
}

command: dbSyncInstance: {
	environment: os.Getenv & {
		NOMAD_NAMESPACE: "catalyst-dryrun" | "catalyst-fund3"
	}

	display: cli.Print & {
		text: #namespaces[environment.NOMAD_NAMESPACE].vars.#dbSyncInstance
	}
}