from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import (
    PublicSubnet, PrivateSubnet,
    InternetGateway, NATGateway,
    ElasticLoadBalancing, RouteTable,
)
from diagrams.aws.compute import EKS, EC2
from diagrams.aws.security import IAMRole
from diagrams.aws.storage import S3
from diagrams.aws.general import General
from diagrams.k8s.compute import Deployment, Pod
from diagrams.k8s.network import Service
from diagrams.onprem.vcs import Github
from diagrams.onprem.container import Docker
from diagrams.onprem.client import User

OUTPUT = "/Users/mokhlesurrahman/dev/personal/eks-node-app-project/architecture_diagram"

with Diagram(
    "EKS Node App - Architecture",
    filename=OUTPUT,
    show=False,
    direction="TB",
    graph_attr={
        "fontsize": "30",
        "bgcolor": "white",
        "pad": "1.0",
        "ranksep": "1.2",
        "nodesep": "0.8",
        "compound": "true",
    },
    outformat="png",
):

    user = User("End User")

    # ================================================================
    # CI/CD
    # ================================================================
    with Cluster("GitHub Actions CI/CD"):
        gh = Github("GitHub Repo")
        p1 = General("Pipeline 1\nTerraform Apply/Destroy\n(provisions infrastructure)")
        p2 = General("Pipeline 2\nDocker Build and Push\n(builds app image)")
        p3 = General("Pipeline 3\nHelmfile Deploy\n(deploys app to cluster)")

    dockerhub = Docker("Docker Hub\nmahin96/eks-node-app")
    tf_state = S3("S3 Bucket\nTerraform State")

    # ================================================================
    # AWS
    # ================================================================
    with Cluster("AWS Cloud - us-east-1"):

        # ── IAM ──
        with Cluster("IAM - Identity and Access Management"):
            cluster_role = IAMRole(
                "EKS Cluster Role\n\n"
                "Allows AWS EKS service\n"
                "to manage the cluster\n"
                "(create ENIs, manage\n"
                "networking, logging)"
            )
            node_role = IAMRole(
                "Node Group Role\n\n"
                "Allows EC2 worker nodes to:\n"
                "- pull images from ECR\n"
                "- register with EKS cluster\n"
                "- manage pod networking (CNI)"
            )

        # ── VPC ──
        with Cluster("VPC: 10.1.0.0/16"):

            igw = InternetGateway("Internet Gateway\n\nEntry/exit point\nfor all internet\ntraffic to VPC")

            # ── PUBLIC SUBNETS ──
            with Cluster(
                "PUBLIC SUBNETS\n"
                "Route: 0.0.0.0/0 goes to Internet Gateway\n"
                "Resources here get public IPs and direct internet access"
            ):
                pub_rt = RouteTable("Public Route Table\n0.0.0.0/0 -> IGW")

                with Cluster("us-east-1a | 10.1.1.0/24"):
                    pub1 = PublicSubnet("Public Subnet 1")
                    nat = NATGateway(
                        "NAT Gateway + EIP\n\n"
                        "Allows private subnet\n"
                        "resources to reach\n"
                        "the internet (outbound\n"
                        "only, no inbound)"
                    )

                with Cluster("us-east-1b | 10.1.2.0/24"):
                    pub2 = PublicSubnet("Public Subnet 2")
                    elb = ElasticLoadBalancing(
                        "AWS Load Balancer\n\n"
                        "Created automatically by\n"
                        "K8s LoadBalancer Service.\n"
                        "Receives user traffic on\n"
                        "port 80 and forwards to\n"
                        "pods on port 3000"
                    )

            # ── PRIVATE SUBNETS ──
            with Cluster(
                "PRIVATE SUBNETS\n"
                "Route: 0.0.0.0/0 goes to NAT Gateway\n"
                "Resources here have NO public IPs - isolated from direct internet access"
            ):
                priv_rt = RouteTable("Private Route Table\n0.0.0.0/0 -> NAT GW")

                # ── EVERYTHING INSIDE PRIVATE SUBNETS ──
                with Cluster("us-east-1a | 10.1.3.0/24"):
                    priv1 = PrivateSubnet("Private Subnet 1")

                    with Cluster("Worker Node 1 (EC2 t3.small)"):
                        node1 = EC2("EC2 Instance\n(no public IP)")
                        pod1 = Pod("App Pod(s)\nrunning here")

                with Cluster("us-east-1b | 10.1.4.0/24"):
                    priv2 = PrivateSubnet("Private Subnet 2")

                    with Cluster("Worker Node 2 (EC2 t3.small)"):
                        node2 = EC2("EC2 Instance\n(no public IP)")
                        pod2 = Pod("App Pod(s)\nrunning here")

            # ── EKS CONTROL PLANE ──
            with Cluster(
                "EKS Control Plane (managed by AWS)\n"
                "tf-eks-cluster-dev | K8s 1.33\n"
                "Has ENIs in all 4 subnets to communicate with worker nodes"
            ):
                eks = EKS("EKS API Server\n\nManaged by AWS.\nRuns masters, etcd,\nscheduler, etc.")

            # ── K8S OBJECTS ──
            with Cluster("Kubernetes Objects (deployed via Helmfile)"):
                deploy = Deployment("Deployment: nodejs-app\nreplicas managed by HPA")
                svc = Service("Service: nodejs-app\ntype: LoadBalancer\nport 80 -> targetPort 3000")
                hpa = General("HPA: nodejs-app\nmin 1 / max 20 replicas\nscale at CPU 85% or Mem 90%")

    # ================================================================
    # CONNECTIONS
    # ================================================================

    # -- CI/CD triggers --
    gh >> Edge(label="  trigger  ", style="dashed", color="blue") >> p1
    gh >> Edge(label="  trigger  ", style="dashed", color="blue") >> p2
    gh >> Edge(label="  trigger  ", style="dashed", color="blue") >> p3

    p1 >> Edge(label="stores state", color="orange") >> tf_state
    p1 >> Edge(label="creates VPC, subnets,\nIGW, NAT, IAM, EKS,\nnode group", color="orange") >> eks

    p2 >> Edge(label="pushes image", color="purple") >> dockerhub

    p3 >> Edge(label="deploys K8s\nresources to cluster", color="green") >> eks

    # -- INBOUND: user request hits the app --
    user >> Edge(
        label="1. User sends request",
        color="darkblue", style="bold"
    ) >> igw

    igw >> Edge(
        label="2. IGW routes to\nELB in public subnet",
        color="darkblue", style="bold"
    ) >> elb

    elb >> Edge(
        label="3. ELB forwards to\nK8s Service (NodePort)\non private worker nodes",
        color="darkblue", style="bold"
    ) >> svc

    svc >> Edge(
        label="4. Service routes\nto Pod on port 3000",
        color="darkblue", style="bold"
    ) >> pod1

    # -- OUTBOUND: private nodes reaching internet (e.g. pulling docker images) --
    node1 >> Edge(
        label="outbound request\n(e.g. docker pull)",
        color="brown", style="dashed"
    ) >> priv_rt

    priv_rt >> Edge(
        label="routes 0.0.0.0/0\nto NAT Gateway",
        color="brown", style="dashed"
    ) >> nat

    nat >> Edge(
        label="NAT translates\nprivate IP to public\nand sends via IGW",
        color="brown", style="dashed"
    ) >> igw

    # -- Public subnet routing --
    pub1 >> Edge(style="dotted", color="gray") >> pub_rt
    pub2 >> Edge(style="dotted", color="gray") >> pub_rt
    pub_rt >> Edge(style="dotted", color="darkgreen", label="default route") >> igw

    # -- Private subnet routing --
    priv1 >> Edge(style="dotted", color="gray") >> priv_rt
    priv2 >> Edge(style="dotted", color="gray") >> priv_rt

    # -- Image pull flow --
    dockerhub >> Edge(
        label="pods pull image\n(outbound via NAT->IGW)",
        style="dashed", color="purple"
    ) >> pod2

    # -- IAM role bindings --
    cluster_role >> Edge(
        style="dashed", color="firebrick",
        label="EKS service\nassumes this role"
    ) >> eks

    node_role >> Edge(
        style="dashed", color="firebrick",
        label="EC2 instances\nassume this role"
    ) >> node1

    node_role >> Edge(style="dashed", color="firebrick") >> node2

    # -- EKS manages worker nodes --
    eks >> Edge(label="manages and\nschedules pods onto", color="black") >> node1
    eks >> Edge(label="manages", color="black") >> node2

    # -- K8s object relationships --
    deploy >> Edge(label="creates") >> pod1
    deploy >> Edge(label="creates") >> pod2
    hpa >> Edge(label="scales replicas", style="dashed") >> deploy
    svc >> Edge(label="load balances to", style="dotted") >> pod2

print("Done: architecture_diagram.png")
