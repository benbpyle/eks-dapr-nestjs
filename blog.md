Adaptability is a characteristic of software systems that developers and architects are always trying to obtain.  However, it's a balance between productivity, performance, maintainability, and mamany other "ilities" that sometimes force trade-offs.  One way to ehance a system's adaptability is to start with the right level of operational abstraction.  For the balance of this article, I'm mamaking the choice to start with Kubernetes, more speficially AWS Elastic Kubernetes Service (EKS). This is a great start towards adaptability as I can leverage so many open source and commerical grade packages, but what if I wanted to take things a step further?  There's an architectual pattern called ports and adapters or also described as hexagonal.  No doubt that sounds more adaptable, but what does it mean and how would one achieve it? Enter Dapr.  A way to build extensible and adaptable microservice systems ready for the modern cloud to tackle the next evolution of compute.  Let's get going!

## Solution Architecture

Before digging into the solution architecture diagram, here's the link to the [GitHub repository](https://github.com/benbpyle/eks-dapr-nestjs) so that you can clone and follow along if you like.  Now into the solution!

Kubernetes surely is a vast topic with many topics to learn, explore, and ultimately master.  But it doesn't have to be complex when starting out.  Essentially what you need is a VPC, a network with some subnets, and a nodepool (which defines the EC2 image to run).  With those things in place, I can deploy my 2 microservice solution with Dapr and Datadog that looks like this.

![Dapr on EKS](./system-architecture-svg.svg)

I'm going to be deploying 2 services that have their own Pod definition. Those services will be annotated in a way that the Dapr sidecar is launched next to my service container and will intercept all traffic inbound and outbound.  What Dapr also provides me is a host of other ports to communication with things like queues, databases, and more.  Topics I'll explore in the future.  

The other piece I'll be exploring in this article is how Dapr can generate OpenTelemetry traces for me, connect them together, and ship them to the exporter of my choice.  And in this case, it'll be the Datadog Agent handling that job and forwarding them along.  

## Walkthrough 

Here we go! Hang in there, as there will be a few moving parts and I'll be highlighting everything from Kubernetes build out to application code as well as showcasing some screenshots of Dapr and Datadog.

### Building the Cluster

