
# EKS Cluster with Karpenter and Graviton Instances

This Terraform module deploys an Amazon EKS cluster with Karpenter as the autoscaler, leveraging both x86 and ARM (Graviton) instances for optimized price/performance.

## Prerequisites

- Terraform installed locally
- AWS CLI configured with permissions for creating EKS resources
- kubectl installed and configured

## Usage

1. **Clone the repository**

   ```sh
   git clone <repo-url>
   cd technical-tasks/2
   ```

2. **Edit `terraform.tfvars`**

   Specify the following variables:
   - `region` - The AWS region where EKS will be deployed.
   - `cluster_name` - Name of the EKS cluster.
   - `vpc_id` - The VPC ID where EKS will be deployed.
   - `subnet_ids` - List of subnet IDs within the VPC.

3. **Deploy the infrastructure**

   Run the following commands to initialize Terraform and apply the configurations.

   ```sh
   terraform init
   terraform apply
   ```

4. **Post-Deployment**

   Once the cluster is created, configure kubectl to connect to the new cluster:

   ```sh
   aws eks --region <region> update-kubeconfig --name <cluster_name>
   ```

## Using the Cluster

### Running a Pod on x86 or ARM (Graviton) Nodes

The Karpenter provisioner in this setup is configured to support both `x86` and `ARM64` architectures. You can specify the architecture using node selectors in your deployment manifests.

1. **Run an x86 Pod:**

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-x86
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: nginx-x86
     template:
       metadata:
         labels:
           app: nginx-x86
       spec:
         nodeSelector:
           kubernetes.io/arch: amd64
         containers:
         - name: nginx
           image: nginx
   ```

2. **Run an ARM (Graviton) Pod:**

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-arm
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: nginx-arm
     template:
       metadata:
         labels:
           app: nginx-arm
       spec:
         nodeSelector:
           kubernetes.io/arch: arm64
         containers:
         - name: nginx
           image: nginx
   ```

Deploy these files with `kubectl apply -f <filename>.yaml` to test deployments on x86 or ARM nodes.
