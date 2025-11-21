# Util Scripts for Kubernetes

## kubeswitch
This script is used to switch between different Kubernetes contexts by managing the ~/.kube/config file.
It uses a directory defined by the KUBE_CONFIG_VAULT environment variable to store the context files.
When the `KUBE_CONFIG_VAULT` variable is not set, it defaults to ~/.local_kube_vault.
The script also provides a help message for usage instructions.

### Usage

```bash
./kubeswitch.sh COMMAND <CONTEXT_NAME>
```
**COMMAND** can be one of the following:

-   list: List all available contexts.
-   apply: Apply to a specified context.
-   delete: Delete a specified context.
-   save: save to a new context.
-   help: Show help message.

**CONTEXT_NAME:**

Context names are derived from the directory structure under the KUBE_CONFIG_VAULT directory which is case-insensitive. 

### Examples

```bash
./kubeswitch.sh list
./kubeswitch.sh apply my-context
./kubeswitch.sh delete my-context
./kubeswitch.sh save my-context
```

## kube-download

This script downloads a file of a given path from Kubernetes pod(s) to the local machine. If the file is `/var/log/abc.log` and the pod name is `app-12345`, the file will be downloaded to `app-12345-abc.log` in the current directory. If the user specifies an output file path (e.g., `/abc/app.log`), the pod name will be prepended at the file level, resulting in `/abc/app-12345-app.log`.

**Pre-requisites:**

It requires `gtimeout` to be installed on the local machine. For macOS, you can install it using Homebrew:
```bash
brew install coreutils
```

**Constraints:**

- For each pod, the download will timeout after 5 minutes.

### Usage

```bash
./kube-download.sh [-n namespace] [-o output_file] <pod_prefix> <file_path>
```

- **pod_prefix**: The prefix of the pod name to match. It can be a substring of the pod name.
- **file_path**: The path of the file to download from the pod(s).
- **namespace**: The namespace of the pod(s). If not provided, it defaults to "default".
- **output_file**: The local file path where the downloaded file will be saved. The pod name will be prepended at the file level.

### Examples

```bash
./kube-download.sh -n default -o /abc/app.log postfix /var/log/postfix/mail.log
```

This will download the file to `/abc/postfix-<pod_name>-app.log`.

```bash
./kube-download.sh collector /var/log/collector/app.log default
```

This will download the file to `collector-<pod_name>-app.log` in the current directory.

## kube-log-pull

This script downloads multiple log files from Kubernetes pods based on a JSON configuration file. It processes each log entry in the JSON file, skipping logs where `download` is set to `false` and downloading logs where `download` is `true`.

**Pre-requisites:**

- The script requires `jq` to parse the JSON file. Install it using your package manager (e.g., `brew install jq` on macOS).

### JSON Configuration

The JSON file should have the following structure:

```json
{
  "output-folder": "target/logs",
  "logs": [
    {
      "download": true,
      "name": "example",
      "pod-selector": "example-",
      "namespace": "default",
      "files": ["/var/log/example/app.log"]
    }
  ]
}
```

- **output-folder**: The base folder where logs will be saved.
- **logs**: An array of log configurations.
  - **download**: Whether to download the logs (`true` or `false`).
  - **name**: A name for the log group.
  - **pod-selector**: The prefix of the pod name to match.
  - **namespace**: The namespace of the pods.
  - **files**: A list of file paths to download from the pods.

### Usage

```bash
./kube-log-pull.sh [path/to/log-files.json]
```

- If no JSON file is provided, the script defaults to `log-files.json` in the current directory.

### Examples

```bash
./kube-log-pull.sh /path/to/log-files.json
```

This will download the logs specified in the JSON file to the `output-folder`, organizing them by log group and pod name.

For example, if the JSON specifies:
```json
{
  "output-folder": "target/logs",
  "logs": [
    {
      "download": true,
      "name": "manager",
      "pod-selector": "manager-",
      "namespace": "default",
      "files": ["/var/log/manager/app.log"]
    }
  ]
}
```

The downloaded file will be saved as:
```
target/logs/manager/<pod_name>-app.log
```

### Notes
There is a bug in the script when the remote file is simultaneously written while being downloaded, the download process will hang. 
A typical case is mail.log file in postfix server. 