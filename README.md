# ECS-tutorial

## Prerequisites

### 1 - Create key pair

### 2 - Create KMS master encryption key
AWS Key Management Service (KMS) allows you to easily create and control the keys used to encrypt your data.

* When running `kms encrypt`, you must supply the master encryption key you want to use. For `decrypt`, you don’t need to explicitly specify the key.
* To create a master encryption key, go to the AWS Console->IAM, and then choose “Encryption Keys” in the far left nav section (all the way at the bottom). This will bring up the KMS management console.

### 3 - `user_data.sh` startup script

### 4 - Create encrypted secrets file
a. Create new S3 folder where secrets will be stored
b. Using a text editor, create the unecrypted secrets file
c. Write encrypted secrets file to S3 bucket:
$ ./put_creds.sh -b kelsus-ecs -k tutorial-0/ecs.config -f ecs.config

```
./get_creds.sh -b kelsus-ecs -k tutorial-0/ecs.config
```


## Create Cluster

1 - Create new ECS cluster
Via AWS console, select ECS->Create cluster
Choose instance size, keypair, and number of instances
Choose VPC and subnets
IAM = ecsInstanceRole

2 - Create new Launch Configuration with proper startup script
a. Go to EC2->Launch Configuration and select the new launch configuration that was created as part of the ECS cluster creation
b. From "Actions", choose "Copy launch configuration" to create a new launch configuration template
c. Edit the launch configuration details
    i. Change the name (use format: "EC2ContainerService-[cluster-name]-EcsInstanceLc-[date]")
    ii. Expand "Advanced details" to update the user_data.sh script

3 - Update Auto Scale Group to use new Launch Configuration
a. Go to EC2->Auto Scaling Groups and select the new auto launch group that was created as part of the ECS cluster creation
b. Click the "Edit" button
c. From the "Launch Configuration" dropdown, select the new launch configuration you created in the previous step
d. Click the "Save" button to commit the changes

4 - Delete (terminate) the initial EC2 instances created during ECS cluster creation
a. Go to EC2->Instances, select the EC2 instances that were created via the initial auto scale group for the cluster, and then choose "Actions->Instance state->Terminate"
b. Once these instances are terminated, the auto scale group will spin up new instances to take their place using the new Launch Configuration


## Create ELB

1 - Create a new security group to be used by the ELB
a. Go to EC2->Security Groups and click the "Create Security Group button"
b. Use the following settings:
- Group name: ecs-elb-tutorial-0
- Description: External-facing ELB fronting ECS services
- VPC:
c. Click the "Inbound Rules" tab, click the "Add Rule" button, and allow all inbound traffic (source "0.0.0.0/0" and "::/0") on port 80.
d. Click the "Outbound Rules" tab, click the "Add Rule" button, and setup a single outbound rule:
- Type: Custom TCP Rule
- Protocol: TCP
- Port range: 8000-8200
- Destination: [choose the security group being used by the launch configuration for this ECS cluster - if you start typing "sg-" an autocomplete list will appear]

2 - Update the security group being used by the launch configuration
a. Go to EC2->Security Groups, and select the security group used by the launch configuration
b. On the "Inbound" tab, click "Edit" and make sure it has the following two rules:
- Type, Protocol, Port Range, Source
- SSH, TCP, 22, 0.0.0.0/0
- Custom TCP Rule, TCP, 8000 - 8200, sg-xxxx (ecs-elb-tutorial-0)

3 - Create ELB
a. Go to EC2->Load Balancers and click the "Create Load Balancer" button
b. Choose "Classic load balancer" and then click "Continue" button
c. Use the following settings:
- Load Balancer name: [choose name]
- Create LB Inside: [choose VPC]
[ignore listener configuration for now]
- Choose at least two subnets for the ELB
d. Click "Next: Assign Security Groups"
e. Click the "Select an existing security group" radio button and select the security group you created in the previous step
f. Click "Next" several times to go through the remaining screens. Accept the defaults and do *not* add any EC2s to the ELB.
g. On the "Review and Create" screen, choose "Create" to create the ELB.

4 - Update ELB Listeners and Health Check
a. Go to EC2->Load Balancers and select the ELB
b. On the "Listeners" tab, click "Edit"
c. Update the configuration to have two listeners, one for HTTP (80) and one for HTTPS (443), with both forwarding to port 8080.  For the port 443 listener, make sure to choose the proper SSL wildcard certificate
d. Click "Save" to commit the changes.
e. Click the "Health check" tab, and then click the "Edit" button. Update the health check to have the following settings and then click "Save" button
- Protocol: http
- Port: 8080
- Path: /


## Create Service

1 - Create task

2 - Create service
