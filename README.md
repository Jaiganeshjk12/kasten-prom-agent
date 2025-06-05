# Prometheus Agent Helm Chart for Veeam Kasten

This Helm chart deploys a Prometheus Agent for Kasten in your Kubernetes cluster, configured to scrape metrics from Kasten's prometheus instance and remotely write them to a central Prometheus server or compatible remote storage endpoint.

## Features

* Deploys Prometheus Agent in agent mode (`--enable-feature=agent`).
* Configurable `remote_write` URL.
* Supports basic authentication for `remote_write` using a Kubernetes Secret for the password.
* Conditionally enables TLS for `remote_write` by mounting a CA certificate from a Kubernetes Secret.
* Role-Based Access Control (RBAC) scoped to the agent's namespace for pod, service, and endpointslice discovery.
* Configurable scrape configurations with default relabeling rules and an example `cluster` label.

## Prerequisites

* Kubernetes/Openshift cluster (recent versions recommended)
* Helm v3.x
* A central Prometheus server or remote storage endpoint configured to receive remote write metrics.

## Installation

1.  **Add the helm repository for the kasten prometheus agent:**
    If you have downloaded the chart files locally, point the helm commands to the local chart file.
    ```bash
        helm repo add kasten-prom-agent https://jaiganeshjk12.github.io/kasten-prom-agent/
        helm repo update
        ```
2.  **Prepare Secrets (if using Basic Auth or TLS):**

    * **For Basic Authentication Password:**
        Create a Kubernetes Secret containing the password for your remote write endpoint. By default, the chart expects a key named `password`.
        ```bash
        kubectl create secret generic my-prometheus-password-secret \
          --from-literal=password='your_secure_password' \
          -n kasten-io
        ```

    * **For TLS CA Certificate:**
        If your remote write endpoint uses TLS and requires a custom CA certificate for verification, create a Kubernetes Secret containing the CA certificate. By default, the chart expects a key named `ca.crt`.
        ```bash
        # Assuming your CA certificate is in a file named 'ca.crt'
        kubectl create secret generic my-ca-cert-secret \
          --from-file=ca.crt \
          -n kasten-io
        ```

3.  **Install the Chart:**

    Navigate to the directory containing the `prometheus-agent-chart` folder (e.g., if `prometheus-agent-chart` is in your current directory).

    ```bash
    helm install k10-prom-agent kasten-prom-agent/kasten-prom-agent  \
      --namespace kasten-io \
      --set remoteWrite.url="https://your-central-prometheus:9090/api/v1/write" \
      --set clusterName="<UniqueClusterName>" \
      --set remoteWrite.tls.enabled=true \
      --set remoteWrite.tls.caCertSecretName=my-ca-cert-secret \
      --set remoteWrite.basicAuth.enabled=true \
      --set remoteWrite.basicAuth.username=<USERNAME-FOR-REMOTE-RECEIVER> \
      --set remoteWrite.basicAuth.passwordSecretName=my-prometheus-password-secret
      # Add other --set flags as needed (see Configuration section)
    ```

## Configuration

The following table lists the configurable parameters of the Prometheus Agent Helm chart and their default values. These can be overridden using `--set` flags during `helm install` or by providing a custom `values.yaml` file.

Here’s a markdown table summarizing all the configurable values from your Helm values file, including their descriptions and default values:

| Key                                     | Description                                                                                                                      | Default Value                        |
|------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| image.repository                        | Prometheus docker image repository.                                                                                              | prom/prometheus                      |
| image.tag                               | Prometheus image tag.                                                                                                            | v2.50.0                              |
| image.pullPolicy                        | Image pull policy.                                                                                                               | IfNotPresent                         |
| replicaCount                            | Number of Prometheus Agent replicas.                                                                                             | 1                                    |
| kasten.namespace                        | Namespace in which Kasten is installed. Used for the scrape config discovery endpoint                                                                                                  | kasten-io                            |
| remoteWrite.url                         | URL of the central Prometheus server or compatible remote storage endpoint                                                                    | "" |
| remoteWrite.basicAuth.enabled           | Enable basic authentication for remote write.                                                                                    | false                                |
| remoteWrite.basicAuth.username          | Username for basic authentication.                                                             | ""                                   |
| remoteWrite.basicAuth.passwordSecretName| Name of Kubernetes Secret containing the basic auth password.                                                                    | ""                                   |
| remoteWrite.basicAuth.passwordSecretKey | Key within the secret that holds the password.                                                                                   | password                             |
| remoteWrite.tls.enabled                 | Enable TLS for remote write.                                                                                                     | false                                |
| remoteWrite.tls.caCertSecretName        | Name of Kubernetes Secret containing the CA certificate.                                                                         | ""                                   |
| remoteWrite.tls.caCertSecretKey         | Key within the secret that holds the CA certificate.                                                                             | ca.crt                               |
| remoteWrite.tls.insecure_skip_verify         | Toggle to skip TLS verification                                                                             | false                               |
| clusterName                             | Label added to all metrics exported by this agent to identify the cluster.                                                       | example-cluster                      |
| resources.limits.cpu                    | CPU resource limit for the Prometheus Agent pod.                                                                                 | 200m                                 |
| resources.limits.memory                 | Memory resource limit for the Prometheus Agent pod.                                                                              | 256Mi                                |
| resources.requests.cpu                  | CPU resource request for the Prometheus Agent pod.                                                                               | 100m                                 |
| resources.requests.memory               | Memory resource request for the Prometheus Agent pod.                                                                            | 128Mi                                |
