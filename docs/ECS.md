# ECS
Amazon EC2 Container Service (ECS)

ECS allows you to easily schedule and run Docker containers on a dedicated cluster of EC2 instances. It integrates with Elastic Load Balancing (ELB) to seamlessly add and remove containers from your service.


## Why ECS?

1. Easily manage clusters for any scale
    - decouple application layer from underlying infrastructure => perfect for microservices
    - control and monitoring
    - easy to scale up/down

2. Increase efficiencies of cloud resources

3. Flexible execution options & placement
    - applications/services
    - batch jobs
    - support for multiple schedulers

4. Designed for use with other AWS services
    - tight integration with ELB
    - AWS IAM


## Architecture

With ECS, you create a "cluster" (launch configuration + auto scale group) that provides ECS with resources on which it can schedule containers for running.  Within each cluster, you define one or more services.  Each service can then be associated with an ELB.  You then define tasks (which map to one or more containers) for the service, and ECS schedules those tasks across the cluster and updates the associated ELB accordingly.

The hierarchy of ECS elements:
    `Cluster` -> `Service` -> `Task`

Each service has one task definition, which defines its containers. Services specify the number of instances of each task definition that should be running. Most services request multiple task instantiations, as this allows for greater availability and performance.


## Deploying

To deploy a new version of our service, we register a new task revision with ECS.  This task revision points to the new Docker image for the updated service. We then tell the ECS service to update itself using the new task definition.

ECS then looks across the cluster and finds suitable instances that contain the necessary CPU/memory resources to schedule the new container(s).  As it does this it terminates one of the existing containers and removes it from the ELB (leaving a minimal number of instances in the ELB).

As new containers come up and are deemed healthy, ECS then adds them to the ELB, and proceeds to terminate and remove any old instances from the ELB (as long as minimum healthy count is maintained).  This process continues until all instances are running the new task definition.

If there are failures bringing up new instances (i.e. a bad build), there is no downtime because the ELB will continue to contain the minimum number of healthy hosts (which continue running the old version of the software). Note, however, that we would then be running in a state of less redundancy, which would be rectified once another deployment is made with a good build of the software.
