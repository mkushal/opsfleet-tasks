
# Istio Mutual TLS Demonstration on EKS

This Proof of Concept (POC) demonstrates setting up Istio on an existing Amazon EKS cluster and configuring mutual TLS (mTLS) between two sample services (service-a and service-b) runn
ing on Kubernetes. The POC is designed to showcase how to secure communication between microservices using Istio capabilities.

## Step 1: Create an EKS Cluster
You can create the EKS cluster using the AWS CLI or AWS Management Console. 

## Step 2: Download & Install Istio

Go to the Istio release page to download the installation file for your OS, or download and extract the latest release automatically (Linux or macOS):

```
curl -L https://istio.io/downloadIstio | sh -
```
Move to the Istio package directory. For example, if the package is istio-1.23.3
```
cd istio-1.23.3
```
Add the istioctl client to your path (Linux or macOS):
```
export PATH=$PWD/bin:$PATH
```
Install Istio using the demo profile:
```
istioctl install --set profile=demo -y
```
Verify the Istio installation:
```
 kubectl get pod -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-egressgateway-84455c865-hmnts     1/1     Running   0          34m
istio-ingressgateway-679755c9c9-fhk99   1/1     Running   0          34m
istiod-77d68488bc-qxlpk                 1/1     Running   0          34m
```

Label your desired namespace for automatic Istio sidecar injection:
```
kubectl label namespace default istio-injection=enabled
```

## Step 3: Deploy Sample Services with mTLS Enabled

You’ll deploy two sample applications (service-a and service-b) that communicate over HTTP but will be secured via mTLS.

```
helm upgrade --install mtls-demo ./mtls-demo -n <namespace>
```

This helm chart contains below.
- manifest files deployment of service-a & service-b
- PeerAuthentication policy to enforce mTLS (This policy enforces strict mTLS mode in the specific namespace, meaning all service-to-service communication must be over mTLS.)
- DestinationRule to enforce mTLS for traffic destined to both services (This ensures that Istio uses mutual TLS for all traffic within the specific namespace.)


## Step 4: Verify mTLS Between Services

Get the Pods:

```
kubectl get pod -n iversion
NAME                         READY   STATUS    RESTARTS   AGE
service-a-586fd5479d-htkmf   2/2     Running   0          35m
service-b-68fdd76df4-k5q72   2/2     Running   0          35m
```

Exec into service-a and send a request to service-b:

```
kubectl exec -it service-a-586fd5479d-htkmf -n iversion -- bash
root@service-a-586fd5479d-htkmf:/# curl http://service-b.iversion.svc.cluster.local:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

Check the Proxy Configuration for service-a:

```
istioctl proxy-config cluster <pod-name> -n iversion --fqdn service-b.iversion.svc.cluster.local
```

Look for tls_context or mode: ISTIO_MUTUAL in the output, which indicates mTLS is enabled between service-a and service-b.

Verify PeerAuthentication Policy

Ensure there is a PeerAuthentication policy in place that enforces mTLS.

```
kubectl get peerauthentication -n iversion
```
Look for a PeerAuthentication resource with mtls mode set to STRICT, which will enforce mTLS within the iversion namespace.

Verify DestinationRule for mTLS

Check that there’s a DestinationRule with ISTIO_MUTUAL TLS mode for service-b:

```
kubectl get destinationrule -n iversion -o yaml
```
You should see a rule that applies ISTIO_MUTUAL mode for connections to service-b (or for all services in the namespace). Here’s an example of the expected output:

```
trafficPolicy:
  tls:
    mode: ISTIO_MUTUAL
```

