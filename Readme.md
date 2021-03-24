### Deployment and Configuration of SUSE CaaS Platform 4.2.5 on VMware vSphere 7.0

####  Build Scenario 1 - one Admin Node, one Master Nodes, two Worker Nodes

```
Futures of this build:

   Deployment on VMware vSphere 7.0
   Build standard SLES-15.1 templates using Packer and  standard AutoYaST installation method.
   Enable vSphere Cloud Provider Integration 
   Deploy NGINX Ingress Controller and exposes HTTP and HTTPS routes from the outside to services created inside the cluster. 
   Deploy and configure MetalLB Load Balancer
   Deploy NFS client provisioner
   Configure vSphere Storage using Static Provisioning and Dynamic Provisioning
   Deploy and configure Prometheus, Prometheus Alert Manager and Grafana
   Deploy and configure Stratos and Kubernetes Dashboard
   Enable Centralized Logging using rsyslog and log-agent-rsyslog
   Deploy couple of example apps including MongoDB, Mongo Express, Nginx and Nginx Hello App

```

#### Credits

```
   SUSECON Digital 2020 - Dwain Sims - Build a workingCaaSP cluster on a KVM host
   HOL-1111: https://www.youtube.com/watch?v=AbGwEfdFM1g
   Dwain Sims - dwain.sims@suse.com
```
#### Goal

```
   Automate the build of a fully operational CaaSP environment while providing all operational tools 
   necessary to successfully run the environment.
```

#### CaaSP 4.2.5 component versions

```
   1. SUSE Linux Enterprise Server 15 SP1    4.12.14-197.83-default
   2. CAASP-RELEASE-VERSION                  4.2.5
   3. KUBELET-VERSION                        v1.17.13 
   4. CONTAINER-RUNTIME                      cri-o://1.16.1
```

#### Preliminary Plan

```
1. Create SLES 15.1 images. Using Packer, and standard AutoYaST installation method build two vSphere VM Templates.
   1.1 Template 1: SLES-15.1 + GNOME    - this is used to build the admin node
   1.2 Template 2: SLES-15.1 + no X/GUI - this is used to build the Kubernetes nodes

2. Dploy kubernetes nodes with terraform
   2.1 Deploy the admin node
   2.2 Deploy two Kubernetes master node
   2.3 Deploy two Kubernetes worker nodes

3. Configure NGINX External Load Balancer

SUSE CaaS Platform requires a load balancer to distribute workload between the deployed master nodes of the cluster.
The load balancer needs access to the following ports:
    - port 6443 on the apiserver (all master nodes) in the cluster
    - port 3200 (Dex) on all master and worker nodes in the cluster for RBAC authentication.
    - port 3201 (Gangway) on all master and worker nodes in the cluster for RBAC authentication.

4. Configure NFS Server

5. Configure rsyslog server and enable centralized logging

6. Create kubernetes clusters with skuba
   - Enable vSphere CPI (Cloud Provider Integration)

7. Deploy and Configure Metal Load Balancer
   MetalLB is a load-balancer implementation for bare metal Kubernetes clusters, using standard routing protocols.

8. Configure NFS Storage

9. Configure vSphere Storage
   - Create Static and Dynamic Persistent Volumes

10. Deploy and configure NGINX ingress controller

11. Deploy and configure Kubernetes Dashboard - Installation For Subdomain using ingress routes

12. Deploy and configure Prometheus - Installation For Subdomain using ingress routes

13. Deploy and configure Grafana - Installation For Subdomain using ingress routes
    - Add pre-built Grafana dashboards to monitor the SUSE CaaS Platform system

14. Deploy and configure Stratos - Installation For Subdomain using ingress routes

15. Configure centralized Logging using rsyslog and log-agent-rsyslog

16. Deploy example apps  - Installation For Subdomain using ingress routes
   5.1 Create namespace ns-mongodb. Deploy MongoDB and Mongo Express
   5.2 Create namespace ns-nginx. Deploy NGINX
   5.3 Create namespace ns-nginx-hello-app. Deploy NGINX hello-app

```

#### Node provisioning

```
   Admin Server      caasp4-admin.flexlab.local
   Master Node 1     caasp4-master1.flexlab.local
   Master Node 2     caasp4-master2.flexlab.local
   Worker Node 1     caasp4-worker1.flexlab.local
   Worker Node 2     caasp4-worker2.flexlab.local

   Admin Server:     Image: SLES-15.1-GNOME  vCPUs: 2    Memory: 16GB   DIsk: 40GB
   Master Server:    Image: SLES-15.1-noX    vCPUs: 2    Memory: 16GB   DIsk: 40GB
   Worker Server:    Image: SLES-15.1-noX    vCPUs: 2    Memory: 16GB   DIsk: 40GB
```

#### OS Installation, extensions and modules

```
Example deployment configuration files for each deployment scenario are installed under /usr/share/caasp/autoyast.

Image: SLES-15.1-GNOME (image used to build admin server) -> installed extensions or modules

S  | Repository                                   | Internal Name                     | Name                               | Version 
---+----------------------------------------------+-----------------------------------+---------------------+--------------+--------
i+ | SLE-Module-Basesystem15-SP1-Pool             | sle-module-basesystem             | Basesystem                         | 15.1-0
i+ | SLE-Module-Containers15-SP1-Pool             | sle-module-containers             | Containers                         | 15.1-0
i+ | SLE-Module-Desktop-Applications15-SP1-Pool   | sle-module-desktop-applications   | Desktop Applications               | 15.1-0
i+ | SLE-Module-DevTools15-SP1-Pool               | sle-module-development-tools      | Development Tools                  | 15.1-0
i+ | SLE-Module-Public-Cloud15-SP1-Pool           | sle-module-public-cloud           | Public Cloud                       | 15.1-0
i+ | SLE-Module-Server-Applications15-SP1-Pool    | sle-module-server-applications    | Server Applications                | 15.1-0
i+ | SLE-Module-Web-Scripting15-SP1-Pool          | sle-module-web-scripting          | Web and Scripting                  | 15.1-0 
i+ | SLE-Product-SLES15-SP1-Pool                  | SLES                              | SUSE Linux Enterprise Server 15    | 15.1-0
i+ | SUSE-CAASP-4.0-Pool                          | caasp                             | SUSE CaaS Platform 4.0 GMC1)       | 4.0-0


Image: SLES-15.1-noX (image used to build kubernetes nodes) -> installed extensions or modules

S  | Repository                                   | Internal Name                     | Name                               | Version 
---+----------------------------------------------+-----------------------------------+---------------------+--------------+--------
i+ | SLE-Module-Basesystem15-SP1-Pool             | sle-module-basesystem             | Basesystem                         | 15.1-0
i+ | SLE-Module-Containers15-SP1-Pool             | sle-module-containers             | Containers                         | 15.1-0
i+ | SLE-Product-SLES15-SP1-Pool                  | SLES                              | SUSE Linux Enterprise Server 15    | 15.1-0
i+ | SUSE-CAASP-4.0-Pool                          | caasp                             | SUSE CaaS Platform 4.0 GMC1)       | 4.0-0
```

#### Skuba

```
   SUSE CaaS Platform uses the skuba package to bootstrap the cluster.
   https://github.com/SUSE/skuba
```

#### Kubik

```
   SUSE CaaS Platform is based on openSUSE Kubic - Certified Kubernetes distribution & container-related technologies.
   https://kubic.opensuse.org/
```

#### Storage

```
   The Admin server is configured as a NFS server providing [/caasp4-storage] Kubernetes Cluster storage
   Shared file system: [/caasp4-storage]

   The vSphere cloud provider is be enabled with SUSE CaaS Platform to allow Kubernetes pods to use VMWare vSphere Virtual Machine Disk (VMDK) volumes as persistent storage.

   The folowwing StorageClasses are defined during the installation:
   NAME                          PROVISIONER
   nfs-client                    cluster.local/caasp4-storage-nfs-client-provisioner 
   vsphere-dynamic (default)     kubernetes.io/vsphere-volume 
   vsphere-static                no-provisioning              
```

#### RSYSLOG server

```
   The Admin server [ caasp4-admin ] is configured as a RSYSLOG Server.
   Kubernetes nodes are configured to send remote SYSLOG messages to the admin server [ caasp4-admin ].
   
   Syslog file location on caasp4-admin:
         /var/log/caasp4-admin
         /var/log/caasp4-master1
         /var/log/caasp4-worker1
         /var/log/caasp4-worker2
```

#### Building the CaaSP environment

```
Login to the Admin Server [caasp4-admin] as [caaspadm] and cd to [scripts] directory.


1.   Distribute the public keys to master and worker nodes
     \> caaspadm@caasp4-admin:~/scripts> ./50_enable_ssh_trust.sh

2.   Build CaaSP Cluster
      \> caaspadm@caasp4-admin:~/scripts> ./51_build_casp4_cluster.sh

   ***** skuba cluster status / wait till all nodes are in Ready State  *****

3.   Configuring Kubernetes Networking via Metal Load Balancer.
      \> caaspadm@caasp4-admin:~/scripts> ./52_deploy_metallb.sh

4.   Deploy NFS client provisioner
      \> caaspadm@caasp4-admin:~/scripts> ./53_deploy_nfs_provisioner.sh

5.   Configure vSphere Storage
      \> caaspadm@caasp4-admin:~/scripts> ./54_configure_vsphere_storage.sh

6.   Deploy and configure NGINX ingress controller and Kubernetes Dashboard.
      \> caaspadm@caasp4-admin:~/scripts> ./55_deploy_ingress_controller.sh

7.   Deploy and configure Prometheus and Grafana
      \> caaspadm@caasp4-admin:~/scripts> ./56_deploy_prometheus.sh

8.   Deploy Stratos via Helm with access to the Kubernetes Dashboard.
     Add pre-built Grafana dashboards to monitor the SUSE CaaS Platform system
      \> caaspadm@caasp4-admin:~/scripts> ./57_deploy_stratos.sh

9.   Enable entralized Logging using rsyslog and log-agent-rsyslog
      > caaspadm@caasp4-admin:~/scripts> ./58_enable_centralized_logging.sh

```

#### Run sample Apps in the Kubernetes Cluster

```
9.    Run example apps

      \> caaspadm@caasp4-admin:~/scripts> ./60_deploy_apps.sh

      Example #1: Deploy MongoDB and Mongo Express (Namespace: ns-mongodb)
      Example #2: Deploy NGINX (Namespace: ns-nginx)
      Example #3: Deploy NGINX hello-app (Namespace: ns-nginx-hello-app)

```


#### Terraform Requirements

```
1. vsphere_tag_category and vsphere_tag must exist
   To create the category and tag execute: cd helpers/tags && terraform apply

2. deploy_vsphere_folder and deploy_vsphere_sub_folder must exist
   To create vSphere folder and sub-folder execute: cd helpers/folders && terraform apply
```

#### Terraform Execution

```
To deploy a new VM first create the VM configuration file and place the configuration file in vm-deployment directory.

   \> terraform init

Init - The first command to run for a new configuration is terraform init, which initializes various local settings and data that will be used by subsequent commands. This command will also automatically download and install any provider defined in the configuration.

   If the vCenter credentials are managed via GPG and Pass, set the apropiate environment variables

   export TF_VAR_provider_vsphere_host=$(pass provider_vsphere_host)

   export TF_VAR_provider_vsphere_user=$(pass provider_vsphere_user)

   export TF_VAR_provider_vsphere_password=$(pass provider_vsphere_password)


   \> terraform plan

Plan - The terraform plan command is used to create an execution plan. Terraform performs a refresh, unless explicitly disabled, and then determines what actions are necessary to achieve the desired state specified in the configuration files.

   \> terraform apply

   \> terraform apply -auto-approve

Apply - The terraform apply command is used to apply the changes required to reach the desired state of the configuration.

   \> terraform destroy

   \> terraform destroy -auto-approve

Destroy - Resources can be destroyed using the terraform destroy command, which is similar to terraform apply, but it behaves as if all of the resources have been removed from the configuration.
```

#### Stratos Console
![Stratos](https://github.com/jmnicolescu/terraform-vsphere-deploy-caasp-2m/blob/main/jpg/caasp4-stratos.jpg)

#### Kubernetes Dashboard
![Kubernetes Dashboard](https://github.com/jmnicolescu/terraform-vsphere-deploy-caasp-2m/blob/main/jpg/caasp4-k8s-dashboard.jpg)

#### Prometheus Dashboard
![Prometheus Dashboard](https://github.com/jmnicolescu/terraform-vsphere-deploy-caasp-2m/blob/main/jpg/caasp4-prometheus.jpg)

#### Grafana Dashboard
![Grafana](https://github.com/jmnicolescu/terraform-vsphere-deploy-caasp-2m/blob/main/jpg/caasp4-grafana.jpg)

#### Mongo Express
![Mongo Express](https://github.com/jmnicolescu/terraform-vsphere-deploy-caasp-2m/blob/main/jpg/caasp4-mongo-express.jpg)

#### vCenter Console
![vCenter Console](https://github.com/jmnicolescu/terraform-vsphere-deploy-caasp-2m/blob/main/jpg/caasp4-vcenter.jpg)