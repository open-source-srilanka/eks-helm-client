# Docker EKS Helm Client Agent

![Scrutinizer build (GitHub/Bitbucket)](https://img.shields.io/scrutinizer/build/g/open-source-srilanka/eks-helm-client/master)
![Docker Pulls](https://img.shields.io/docker/pulls/projectoss/eks-helm-client)
![Docker Image Version (latest semver)](https://img.shields.io/docker/v/projectoss/eks-helm-client)
![Made With Love By (ProjectOSS)](https://img.shields.io/badge/made%20with%20love%20by-ProjectOSS-orange)

## Overview

The Docker EKS Helm Client Agent is a specialized Docker image that acts as a Helm client, allowing you to install and upgrade Helm charts in AWS EKS clusters — enabling seamless management of Kubernetes deployments. It provides a convenient, portable solution for interacting with Helm charts without the need to install Helm, kubectl, or the AWS CLI on your local machine or CI/CD pipelines.

On startup, the container **automatically configures kubectl** by fetching your EKS cluster's CA certificate and endpoint via the AWS CLI, then generating a kubeconfig. Your commands run only after this setup is complete.

## Component Versions

| Component | Version |
|---|---|
| Kubernetes (kubectl) | 1.31.3 |
| Helm | 3.16.3 |
| AWS IAM Authenticator | 0.6.28 |
| Base image | alpine:3.20 |

## Supported Architectures

- `linux/amd64`
- `linux/arm64`

## Prerequisites

The container requires the following environment variables at runtime:

| Variable | Description |
|---|---|
| `REGION_CODE` | AWS region where your EKS cluster is hosted (e.g. `us-east-1`) |
| `CLUSTER_NAME` | Name of your EKS cluster |

AWS credentials must also be available to the container. These can be provided via `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`, an IAM instance role, or the `aws-actions/configure-aws-credentials` GitHub Action.

> **Note:** The container validates `REGION_CODE` and `CLUSTER_NAME` on startup and will exit immediately if either is missing.

## How It Works

The container entrypoint (`entrypoint.sh`) performs the following steps automatically before executing your command:

1. Validates that `REGION_CODE` and `CLUSTER_NAME` are set
2. Fetches the cluster CA certificate via `aws eks describe-cluster`
3. Fetches the cluster API endpoint via `aws eks describe-cluster`
4. Generates a kubeconfig at `/opt/kubernetes/config` using these values
5. Verifies kubectl client configuration
6. Executes the command you passed in

You do **not** need to run `aws eks update-kubeconfig` manually — this is handled automatically.

## Usage

```
projectoss/eks-helm-client:latest
```

### Sample Jenkins Pipeline Stage

```groovy
environment {
    AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    REGION_CODE           = "<your-region-code>"
    CLUSTER_NAME          = "<your-cluster-name>"
}

stage('Deploy Helm Chart') {
    agent {
        docker {
            image 'projectoss/eks-helm-client:latest'
        }
    }
    steps {
        // No need to run aws eks update-kubeconfig — entrypoint handles this automatically
        sh 'helm repo add bitnami https://charts.bitnami.com/bitnami'
        sh 'helm repo update'
        sh 'helm install bitnami/mysql --generate-name'
    }
}
```


For more detailed usage instructions, please refer to the [Jenkinsfile](https://github.com/open-source-srilanka/examples/blob/master/eks-helm-client/Jenkinsfile) in this repository. 

### Sample GitHub Actions Workflow

```yaml
steps:
  - name: Configure AWS Credentials
    uses: aws-actions/configure-aws-credentials@v2.2.0
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      aws-region: <your-region-code>

  - name: Deploy Helm Chart
    uses: docker://projectoss/eks-helm-client:latest
    env:
      REGION_CODE: <your-region-code>
      CLUSTER_NAME: <your-cluster-name>
    with:
      args: >
        bash -c "
          helm repo add bitnami https://charts.bitnami.com/bitnami;
          helm repo update;
          helm install bitnami/mysql --generate-name
        "
```
For more detailed usage instructions, please refer to the [action.yaml](https://github.com/open-source-srilanka/examples/blob/master/eks-helm-client/.github/workflows/action.yaml) in this repository.

## Security Notes

- The container runs as a **non-root user** (`kubectl`, uid 1000) for improved security.
- The kubeconfig is written to `/opt/kubernetes/config`, owned by the `kubectl` user.
- AWS authentication uses `aws eks get-token` via `aws-iam-authenticator`, configured automatically in the generated kubeconfig.

## Contributing

We welcome contributions from the community! To contribute:

1. **Fork the Repository**: Click the "Fork" button at the top right of this repository.
2. **Clone the Fork**: Clone the forked repository to your local machine.
3. **Make Changes**: Implement your desired changes or improvements.
4. **Commit Changes**: Commit with a clear, descriptive message.
5. **Push Changes**: Push your changes to your forked repository.
6. **Create Pull Request**: Open a pull request against the original repository.
7. **Wait for Review**: A maintainer will review your PR and may request changes.
8. **Celebrate**: Once merged, your contribution is part of the project!

Please ensure your code follows the project's coding guidelines and includes appropriate tests for any new functionality.

## License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Copyright (c) 2023 [Dinush Chathurya](https://dinushchathurya.me/) @ [Open Source Srilanka](https://github.com/open-source-srilanka)
