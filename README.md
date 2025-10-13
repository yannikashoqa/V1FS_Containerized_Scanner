# Vision One Containerized Scanner for ICAP Storage

AUTHOR		: Yanni Kashoqa

TITLE		: Vision One Containerized Scanner for ICAP Storage

DESCRIPTION	: These scripts will help with setting up Kubernetes, install a Load Ballancer, and install Vision One Containerized Scanner on a local linux system to provide Antimalware scanning for ICAP storage systems.  These scripts assume installing on a single node/master and has not been tested on multi node Kubernetes Clusters.

REQUIRMENTS
- Linux system: RHEL 9, Ubuntu 24
- Disabled Firewall and SE Linux
- Place all scripts and yaml files are in the same folder on the target server

INSTRUCTIONS
RHEL 9 (Multi-Node Kubernetes Cluster):
- Run the following script to install Kubernetes on the Master Node/Controller: Setup_Kubernetes\Install_Kubernetes_RHEL9_Master.sh
- Run the following script to install Kubernetes on the worker Nodes: Setup_Kubernetes\Install_Kubernetes_RHEL9_Node.sh
- Once completed run the following commands on the Master Node to make sure all pods are running: kubectl get pods -A
- Update Setup_LoadBallancer\PureLB_Config.yaml with the IP addresses and subnet mask to match your environment
- Run the PureLB installer on the Master Node: Setup_LoadBallancer\Install_PureLB.sh
- Once completed run the following commands to make sure all pods are running: kubectl get pods -A
- Update the values.yaml file with your autoscaling needs
- Run the V1FS installer on the Master Node: Install_V1FS_ICAP.sh
- Once completed run the following commands to make sure all pods are running: kubectl get pods -A

RHEL 9 (Single node All in One Cluster):
- Run the following script to install Kubernetes: Setup_Kubernetes\Install_Kubernetes_RHEL9.sh
- Once completed run the following commands to make sure all pods are running: kubectl get pods -A
- Update Setup_LoadBallancer\PureLB_Config.yaml with the IP addresses and subnet mask to match your environment
- Run the PureLB installer: Setup_LoadBallancer\Install_PureLB.sh
- Once completed run the following commands to make sure all pods are running: kubectl get pods -A
- Update the values.yaml file with your autoscaling needs
- Run the V1FS installer: Install_V1FS_ICAP.sh
- Once completed run the following commands to make sure all pods are running: kubectl get pods -A

Ubuntu 24 (Single node All in One Cluster):
- Run the following script to install Kubernetes: Setup_Kubernetes\Install_Kubernetes_Ubuntu24.sh
- Once completed run the following commands to make sure all pods are running: kubectl get pods -A
- Update Setup_LoadBallancer\MetalLB_Config.yaml with the IP addresses to match your environment
- Run the MetalLB installer: Setup_LoadBallancer\Install_MetalLB.sh
- Once completed run the following commands to make sure all pods are running: kubectl get pods -A
- Update the values.yaml file with your autoscaling needs
- Run the V1FS installer: Install_V1FS_ICAP.sh
- Once completed run the following commands to make sure all pods are running: kubectl get pods -A
