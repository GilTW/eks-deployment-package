# EKS Deployment Terraform Package

## Description
Welcome to the EKS Deployment Terraform Package!  
Here you will find a Terraform package built to deploy an EKS cluster with an OIDC Provider configured to assume IAM roles in order to access AWS resources outside of the EKS Cluster scope.

## How It Works?
By creating an OIDC Provider for our EKS cluster we allow our Kubernetes Service Accounts to exchange tokens (Assume Role) with AWS STS in order to receive temporary credentials which will be used by the Pods configured with the corresponding Service Account to access the required AWS Resources.  
Inside the Pod's containers you can seamlessly use AWS SDK (Boto3, JS-AWS-SDK, etc..) for communicating with AWS Resources (S3, SQS, SNS, etc...).

## Pre-Requisities  
* Create [AWS Account](https://aws.amazon.com/free/?trk=2d3e6bee-b4a1-42e0-8600-6f2bb4fcb10c&sc_channel=ps&ef_id=CjwKCAjwrJ-hBhB7EiwAuyBVXYb0-moEkVoJq8MrolFAGE9tD9Hags-ONRUULLB5Ht8Qsg4_UfIQehoCiLkQAvD_BwE:G:s&s_kwcid=AL!4422!3!645125273261!e!!g!!aws!19574556887!145779846712&all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=*all) & [IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) with permission to create the relevant resources
* Install [Terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) (v1.1.2 or higher)
* Install [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) (v0.35 or higher)
* Install [AWS-CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (Recommended 2.11.7 or higher)
    * Configure your access keys and secret keys
    ```console
    > aws configure
    AWS Access Key ID: IAM_USER_ACCESS_KEY
    AWS Secret Access Key: IAM_USER_SECRET_KEY
    Default region name: DEFAULT_REGION_CODE (e.g: eu-central-1)
    Default output format: OUTPUT_FORMAT (Can be left blank)
    ```

## Project Structure
```
.  
├── environment                 # TF Package Components
│   ├── eks-cluster             # EKS Cluster TF Component
│   ├── eks-service-accounts    # EKS Service Accounts TF Component
│   ├── networking              # Netowrking TF Component 
│   ├── env.hcl                 # TF Package Configurations
├── shared-modules              # Shared TF Modules
├── templates                   # Terragrunt Generate Template Files 
└── README.md
```

### Package Configuration File (env.hcl)
This is the main configuration file for the entire package and it has 2 sections:
* locals - mainly contains settings for the entire terraform and terragrunt core which creates the backend bucket, defines the state files locations and generates a tf-settings file containing the default configurations for this package components.

    | Variable            | Description                            |   
    | ------------------- | -------------------------------------- |
    | `deployment_region` | The AWS region in which to deploy the package's components |
    | `project_name`      | The name of the project to be prefixed in the terraform backend bucket and components' resources' names |

* inputs - these are the settings that will be used to configure the package's components settings.

    | Variable                      | Type   | Related Component   | Description                                                             |   
    | ----------------------------- | ------ | ------------------- | ----------------------------------------------------------------------- |
    | `project`                     | String | Common              | Used from locals                                                        |
    | `vpc_cidr`                    | String | Networking          | The CIDR to be used for the VPC network address space                   |
    | `number_of_azs`               | String | Networking          | The number of availability zones to span over when creating VPC subnets |
    | `cluster_name`                | String | EKS Cluster         | The name of the cluster to be used as a suffix to the project name      |
    | `k8s_version`                 | String | EKS Cluster         | The kubernetes version to be installed in EKS                           |
    | `node_groups`                 | Map    | EKS Cluster         | The cluster's node groups key-value configuration where the key is the node group name and the values supported are as follows: <ul><li>ami_type - image type to load on the node group's machines</li><li>capacity_type - what kind of provisioning capacity to use (e.g: spot, on-demand)</li><li>disk_size - disk size to be attached to the node group's machines by GB</li><li>instance_types - list of instance types to be provisioned by the node group</li><li>scaling_config - configuration block for setting the min, max and desired count of intances to be applied in the node group<ul><li>desired_size - the ammount of instances to provision in launch</li><li>max_size - the maximum ammount of instances the node group is allowed to scale up to</li><li>min_size - the minimum ammount of instances the node group is allowed to scale in to</li></ul></li></ul> |
    | `public_subnet_ids`           | List   | EKS Cluster         | Public subnets ids for the cluster if not using Networking component    |
    | `private_subnet_ids`          | List   | EKS Cluster         | Private subnets ids for the cluster if not using Networking component   |
    | `cluster_public_access_cidrs` | List   | EKS Cluster         | Public IP CIDR's to be allowed to access EKS API Server remotely        |
    | `eks_service_accounts`        | Map    | EKS Service Account | The service key-value configuration where the key is the service account name and the values supported as as follows: <ul><li>k8s_namespace - the namespace in which to create the service account</li><li>iam_policies - the IAM role's policies to create for the service account<ul><li>policy_name - the name of the policy can be either a name of Managed policy or a name for a custom policy to be created</li><li>policy_type - the type of the policy can be "MANAGED", "CUSTOM" or "CUSTOM_INLINE" (which doesn't create an actual policy)</li><li>custom_permissions - the permissions block which supports the fields "effect", "actions", "resources" and "conditions"</li></ul></li></ul> |

    For adding new configuration variables it is required to modify the target component so it will be able to utilize the new variables appropriately.

### Networking Component (Optional)
This component is optional if you have an existing VPC setup with its complimentary networking resources.  
The networking component supplied in this package consists of the followings:  
* VPC
* 2 Public Subnets (Over 2 AZs)  - For External ELBs
* 2 Private Subnets (Over 2 AZs) - For Node Groups and Internal ELBs
* Internet Gateway (IGW)
* Single NAT Gateway (NAT-GW)
* Default Routing Table (Main) - Outbound access via NAT-GW for Private Subnets
* Public Routing Table - Outbound access via IGW for Public Subnets

### EKS Cluster Component
This component is responsible for creating the EKS cluster and its node groups with an IAM OIDC Provider which will be used to issue Service Account tokens to be exchanged with AWS STS.

### EKS Service Accounts Component
This component is resposnsible for creating Service Accounts and their corresponding IAM Roles.  
Once deploying the components it will update EKS and AWS IAM Roles automatically and any Service Account will be ready to use by whoever requires it.

## Usage
**Note:** In order to use this package you must either deploy the Networking component or supply both private and public subnet ids in env.hcl

### Initial Setup
Make sure that you have all the prerquesites installed by running the followings (Showing on windows):
```console
> terraform --version
Terraform v1.4.4
on windows_amd64

> terragrunt --version
terragrunt version v0.45.0

> aws --version
aws-cli/2.11.7 Python/3.11.2 Windows/10 exe/AMD64 prompt/off
```

If everything works properly we can start deploying the package.

#### Step 1 - Networking Component
In case you decide to deploy the EKS on an existing VPC you can skip the following step.  
  
Open the env.hcl file and configure the vpc_cidr and number_of_azs to set the required network settings:
```HCL
vpc_cidr      = "192.168.0.0/16"
number_of_azs = 2
``` 

Once you are done, go to the Networking component folder and run the followings:
```console
> terragrunt init
> terragrunt apply -y
```
You will start seeing terraform planning and deploying your resources, wait until its done.

#### Step 2 - EKS Cluster Component
Open the env.hcl file and configure your eks cluster prefrences:
```HCL
cluster_name = "simple-eks"
k8s_version  = "1.25"
node_groups = {
    "simple-ng" : {
        ami_type       = "AL2_x86_64"
        capacity_type  = "ON_DEMAND"
        disk_size      = 20
        instance_types = ["t3.medium"]
        scaling_config = {
        desired_size = 1
        max_size     = 1
        min_size     = 1
        }
    }
}
```

The package is enabling public access to the EKS cluster by default for anyone running this package by extracting the public IP of the machine in which the package is running.  
However, if you want to statically add certain CIDRs to be allowed public access and avoid overriding public access for team members, consider using the following configuration:
```HCL
cluster_public_access_cidrs = []
```

If you are not using the Networking component you must set the public and private subnet ids with at least 2 subent ids in each.  
Make sure you provide subnets with at least 6 free ips but of course it is recommended to provide much larger subnets.  
Also make sure that the private subnets have access to a NAT if you intend to allow outbound connections from the node groups' machines.
```HCL
public_subnet_ids = []
private_subnet_ids = []
```

Once you are done, go to the EKS Cluster component folder and run the followings:
```console
> terragrunt init
> terragrunt apply -y
```

You will start seeing terraform planning and deploying your resources, wait until its done and verify that your cluster is up and running:
```console
> aws eks describe-cluster EKS_CLUSTER_NAME
```
* Replace EKS_CLUSTER_NAME with the full cluster name as per the project and cluster_name variables

If the `status` field in the response is set to `'Active'` then it means that our cluster is up and running (You can also check that in the AWS console).  

Before we continue forward it is recommended to use the aws cli to generate a kubeconfig which will be used with kubectl to connect to the cluster:
```console
> aws eks update-kubeconfig --name EKS_CLUSTER_NAME --kubeconfig SOME_LOCATION
``` 
* If you didn't configure the region when running `aws config` or you want another region then you have to specify `--region DEFAULT_REGION_CODE (e.g: eu-central-1)`

### Adding Service Accounts
By now you should have an EKS cluster running and ready for deployments, but in order to access AWS Resources from your Pods you need to specify a Service Account and that has the required IAM Role's permissions.

Open the env.hcl file and configure a new Service Account as fo:
```HCL
eks_service_accounts = {
"service-x-sa" : {
        k8s_namespace = "default"
        iam_policies = [
            # Example 1
            {
                policy_name = "JustS3Permissions"
                policy_type = "CUSTOM_INLINE"
                custom_permissions = {
                    effect    = "Allow"
                    actions   = ["s3:PutObject"]
                    resources = ["arn:aws:s3:::SOME_BUCKET"]
                }
            },

            # Example 2
            {
                policy_name = "MySNSPermissions"
                policy_type = "CUSTOM"
                custom_permissions = {
                    effect    = "Allow"
                    actions   = ["sns:Publish"]
                    resources = ["arn:aws:sns:eu-central-1:AWS_ACCOUNT_ID:MyTopic"]
                }
            },

            # Example 3
            {
                policy_name = "AmazonSQSReadOnlyAccess"
                policy_type = "MANAGED"
            }
        ]
    }
}
```

You can add as many Service Accounts as you like, just make sure to give them a unique name if they reside in the same namespace.

Once you are done, go to the EKS Cluster component folder and run the followings:
```console
> terragrunt init
> terragrunt apply -y
```
You will start seeing terraform planning and deploying your resources, wait until its done and verify that your Service Accounts has been created:
```console
> kubectl get sa
NAME           SECRETS   AGE
default        0         3h49m
service-x-sa   0         3h20m
```

### Deploying a K8S Deployment Demo
In order to test our package let's create a deployment that will use a Service Account that has permission to write a file to S3.

#### Step 1 - Service Account Setup (Terraform)
1. Let's configure a Service Account in the env.hcl file as follows:
    ```HCL
    eks_service_accounts = {
        "service-x-sa" : {
            k8s_namespace = "default"
            iam_policies = [
                {
                    policy_name = "S3Permissions"
                    policy_type = "CUSTOM_INLINE"
                    custom_permissions = {
                        effect    = "Allow"
                        actions   = ["s3:PutObject"]
                        resources = ["arn:aws:s3:::SOME_AWS_BUCKET"]
                    }
                }
            ]
        }
    }
    ```
    * Replace SOME_AWS_BUCKET with a bucket you would like to write to

2. Go to the the EKS Service Account folder and run the followings:
    ```console
    > terragrunt init
    > terragrunt apply -y
    ```

#### Step 2 - Custom Code Image
In this step we will create a custom code image and push it to AWS ECR to be used in the deployment.
In order to accomplish what we need let's do the followings:
1. Using python let's create a small script that will run in the deployment:
    ```Python
    import boto3
    from time import sleep

    s3_client = boto3.client("s3")


    def save_file_content(bucket, key, file_content, encoding="utf-8", **extra_agrs):
        body = file_content

        if isinstance(body, str):
            body = body.encode(encoding=encoding)

        return s3_client.put_object(Bucket=bucket, Key=key, Body=body, **extra_agrs)


    save_file_content(SOME_AWS_BUCKET, "eks_test_file.txt", "This is a test")

    while True:
        sleep(100)

    ```
    * Replace SOME_AWS_BUCKET with a bucket you would like write into

2. Create a requirmenets.txt file:
    ```HCL
    boto3==1.26.74
    ```

3. Create a Docker file which will be used to build our image:
    ```Docker
    FROM python:3.9-slim-buster
    RUN apt-get -y update && apt-get -y upgrade
    COPY ./run.py run.py
    COPY ./requirements.txt requirements.txt
    RUN pip3 install -r requirements.txt

    CMD python3 run.py
    ```
4. Create an ECR image repo via AWS Console:
    1. Open [ECR](https://console.aws.amazon.com/ecr/repositories) in the console
    2. Navigate to the Repositories page
        ![](/_README_FILES/ecr-root-page.jpg)
    3. Press "Create repository" button
        ![](/_README_FILES/ecr-repo-page.jpg)
    4. Fill-in the name of the repository and create the repository
        ![](/_README_FILES/ecr-create-repo-page.jpg)
    
5. Build and push the Docker image using the following commands:
    ```
    > docker build . -t test-pod:latest
    > aws ecr get-login-password --region AWS_IMAGE_REPO_REGION | docker login --username AWS --password-stdin AWS_ACCOUNT_ID.dkr.ecr.AWS_IMAGE_REPO_REGION.amazonaws.com
    > docker tag test-pod:latest AWS_ACCOUNT_ID.dkr.AWS_IMAGE_REPO_REGION.amazonaws.com/test-pod:latest
    > docker push AWS_ACCOUNT_ID.dkr.ecr.AWS_IMAGE_REPO_REGION.amazonaws.com/test-pod:latest
    ```
    * Replace AWS_ACCOUNT_ID with your account id number
    * Replace AWS_IMAGE_REPO_REGION with the region in which you created the ECR image repository

#### Step 3 - Create a demo deplyoment using the Service Account and our ECR image
1. Create a deployment.yml file as follows:
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: testapp
    namespace: default
    spec:
    selector:
        matchLabels:
        app: testapp
    replicas: 1
    template:
        metadata:
        labels:
            app: testapp
        spec:
        serviceAccountName: service-x-sa
        containers:
            - name: testapp
            image: AWS_IMAGE_ARN
    ```
    * Replace AWS_IMAGE_ARN with the ARN of the ECR repository you created in Step 2
2. Apply the deployment via kubectl:
    ```console
    > kubectl apply -f deployment.yml
    ```
3. Check that your Pod is running:
    ```console
    > kubectl get deploy
    NAME      READY   UP-TO-DATE   AVAILABLE   AGE
    testapp   1/1     1            1           1m

    > kubectl get pods
    NAME                      READY   STATUS    RESTARTS   AGE
    testapp-7b67fb9bd-2l82r   1/1     Running   0          1m
    ```
4. Check your bucket to see that you have the eks_test_file.txt


