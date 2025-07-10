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

This script downloads a file of given path from a Kubernetes pod(s) to the local machine.
If the file is `/var/log/abc.log` and the pod name is `app-12345`, the file will be downloaded to `app-12345-abc.log` in the current directory.

** Pre-requisites:**

It requires a `gtimeout` to be installed on the local machine. For macOS, you can install it using Homebrew:
```bash
brew install coreutils
```

**Constraints:**

- For each pod the download will timeout after 5 minutes.

### Usage

```bash
./kube-download.sh <POD_PREFIX> <FILE_PATH> [NAMESPACE]
```

- **POD_PREFIX**: The prefix of the pod name to match. It can be a substring of the pod name.
- **FILE_PATH**: The path of the file to download from the pod(s).
- **NAMESPACE**: The namespace of the pod(s). If not provided, it defaults to "default".

### Examples

```bash
./kube-download.sh postfix /var/log/postfix/mail.log
```

```bash
./kube-download.sh collector /var/log/collector/app.log default
```

## helm-clean

This script is used to clean up failed Helm releases in a Kubernetes cluster.

### Usage

```bash
./helm-clean.sh
```