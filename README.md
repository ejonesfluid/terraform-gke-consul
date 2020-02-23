## Introduction

The terraform (v0.12+) code deploys highly-available production ready Consul on GKE using Helm charts.

## Installation

1. Download and install [Terraform](https://www.terraform.io/).

2. Download, install, and configure the [Google Cloud SDK](https://cloud.google.com/sdk/). You will need
   to configure your default application credentials so Terraform can run.

3. Install the [kubernetes CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (aka `kubectl`)

4. Create terraform.tfvars with required variables:

    ```text
    $ cd terraform/
    ```

    ```
    # GKE cluster options
    region                          = "northamerica-northeast1"
    project                         = "consul-priject"
    kubernetes_instance_type        = "n1-standard-2"

    # k8s options
    kubernetes_nodes_per_zone       = 1

    # Consul options
    num_consul_pods                 = 3
    ```

5. Run Terraform

    ```text
    $ terraform init
    $ terraform plan
    $ terraform apply
    ```

## Interact with Consul

1. Check the deployment status using `kubectl`.

    ```text
    $ gcloud container clusters get-credentials CLUSTER_NAME --region=REGION --project=PROJECT
    $ kubectl get all -n consul

    NAME                                          TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                                                                   AGE
    service/backend-consul-connect-injector-svc   ClusterIP   10.0.89.200   <none>        443/TCP                                                                   12m
    service/backend-consul-dns                    ClusterIP   10.0.90.195   <none>        53/TCP,53/UDP                                                             12m
    service/backend-consul-server                 ClusterIP   None          <none>        8500/TCP,8301/TCP,8301/UDP,8302/TCP,8302/UDP,8300/TCP,8600/TCP,8600/UDP   12m
    service/backend-consul-ui                     ClusterIP   10.0.90.105   <none>        80/TCP                                                                    12m

    NAME                            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
    daemonset.apps/backend-consul   3         3         3       3            3           <none>          12m

    NAME                                                                 READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/backend-consul-connect-injector-webhook-deployment   1/1     1            1           12m

    NAME                                                                           DESIRED   CURRENT   READY   AGE
    replicaset.apps/backend-consul-connect-injector-webhook-deployment-f88dfb76c   1         1         1       12m

    NAME                                     READY   AGE
    statefulset.apps/backend-consul-server   3/3     12m

    NAME                                       COMPLETIONS   DURATION   AGE
    job.batch/backend-consul-server-acl-init   1/1           83s        12m
    ```

2. Check Consul members status.

    ```text
    $ kubectl exec backend-consul-server-0 -n consul -- consul members

    Node                                   Address          Status  Type    Build  Protocol  DC   Segment
    backend-consul-server-0                10.0.93.11:8301  alive   server  1.6.2  2         dc1  <all>
    backend-consul-server-1                10.0.92.8:8301   alive   server  1.6.2  2         dc1  <all>
    backend-consul-server-2                10.0.94.8:8301   alive   server  1.6.2  2         dc1  <all>
    gke-consul-default-pool-3bbea03d-9728  10.0.92.7:8301   alive   client  1.6.2  2         dc1  <default>
    gke-consul-default-pool-88110088-s9b3  10.0.93.9:8301   alive   client  1.6.2  2         dc1  <default>
    gke-consul-default-pool-9c4df9d1-j8cw  10.0.94.6:8301   alive   client  1.6.2  2         dc1  <default>
    ```
 
## Cleaning Up

   ```
   $ terraform destroy
   ```
 

