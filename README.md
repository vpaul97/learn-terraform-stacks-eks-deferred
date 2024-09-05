## Manage Kubernetes workloads with Stacks

Terraform stacks allow you to automatically manage dependencies within complex
infrastructure deployments. In addition to explicit orchestration rules, a stack
will recognize when a component requires attributes that are not yet available, and
defer those changes  

In this tutorial, you will use an HCP Terraform stack to deploy a Kubernetes
cluster with an example service. first configure a trust relationship between
HCP Terraform and AWS. Next, you will create a stack to provision and manage a
Kubernetes cluster that hosts an example API.

When you deploy your stack, HCP Terraform will automatically detect that the API
you are dpeloying on your Kubernetes cluster needs attributes that aren't
available during the initial plan. It will defer those changes until the
required components are available, then load the attribute values and proceed
with the plan.

### Prerequisites

This tutorial assumes that you are familiar with the Terraform workflow. If you
are new to Terraform, complete the [Get Started
tutorials](/terraform/tutorials/aws-get-started) first.

In order to complete this tutorial, you will need the following:

- An [AWS
  account](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=default&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start).
- An [HCP Terraform
  account](https://app.terraform.io/signup/account?utm_source=learn).
- An [HCP Terraform variable set configured with your AWS
  credentials](/terraform/tutorials/cloud-get-started/cloud-create-variable-set).

### Fork identity token repository

Navigate to the [template
repository](https://github.com/hashicorp/learn-terraform-stacks-identity-token) for the
identity token. Click the **Use this template** button and select **Create a new
repository**. Choose a GitHub account to create the repository in and name the
new repository `learn-terraform-stacks-identity-token`. Leave the rest of the settings
at their default values.

### Create a project

Create an HCP Terraform project for your identity token workspace and Kubernetes
stack.

To do so, first log in to [HCP Terraform](https://app.terraform.io/app), and select
the organization you wish to use for this tutorial.

Then navigate to `Projects`, click the `+ New Project` button, name your project
`Learn Terraform stacks EKS`, and click the `Create` button to create it.

Next, ensure that stacks is enabled for your organization by navigating to
`Settings > General`. Ensure that the box next to `Stacks` is checked, and click
the `Update organization` button.

Then, ensure that your AWS credentials variable set is configured for your
project. Navigate to `Settings > Variable sets`, and select your AWS credentials
variable set. Under `Variable set scope`, select `Apply to specific projects and
workspaces`, and add your `Learn Terraform stacks` project to the list under
`Apply to projects`. Scroll to the bottom of the page and click `Save variable
set` to apply it to your new project.

### Provision identity token

Next, provision an AWS identity token. HCP Terraform will use this token to
authenticate with AWS when it deploys your stack.

Navigate to `Projects` and select your `Learn Terraform stacks EKS` project.
Select `New > Workspace`. On the next screen, select `Version control workflow`,
and then select your GitHub account. On the `Choose a repository` page, select
the `learn-terraform-stacks-identity-token` repository you created in the
previous step. On the next page, select `Advanced options` and enter `aws/` in
the `Terraform Working Directory` field. Scroll to the bottom of the page and
click the `Create` button to create the identity token workspace.

Once you create the workspace, HCP Terraform will load the configuration for
your identity token.

### Create example repository

Navigate to the [template
repository](https://github.com/hashicorp/learn-terraform-stacks-deploy) for this
tutorial. Click the **Use this template** button and select **Create a new
repository**. Choose a GitHub account to create the repository in and name the
new repository `learn-terraform-stacks-deploy`. Leave the rest of the settings
at their default values.

Clone your example repository, replacing `USER` with your own GitHub username.

```shell-session
$ git clone https://github.com/USER/learn-terraform-stacks-deploy.git
```

Change to the repository directory.

```shell-session
$ cd learn-terraform-stacks-deploy
```

### Review components and deployment

Explore the example configuration to review how this Terraform Stack's configuration is organized.

### Review components and deployment

Explore the example configuration to review how this Terraform Stack's configuration is organized.

<CodeBlockConfig hideClipboard>

```shell-session
$ tree
.
├── LICENSE
├── README.md
├── api-gateway
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── components.tfstack.hcl
├── deployments.tfdeploy.hcl
├── lambda
│   ├── hello-world
│   │   └── hello.rb
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── providers.tfstack.hcl
├── s3
│   ├── main.tf
│   └── outputs.tf
└── variables.tfstack.hcl
```

In addition to the licensing-related files and README, the example repository
contains three directories containing Terrraform modules, `api-gateway`,
`lambda`, and `s3`. The Terraform configuration in these directories define the
components that will make up your stack. The repository also includes two file
types specific to Terraform Stacks configuration, a deployments filed named
`deployments.tfdeploy.hcl`, and three stacks files with the extension
`.tfstack.hcl`.

As with Terraform configuration files, HCP Terraform will process all of the blocks in all of the `tfstack.hcl` and `tfdeploy.hcl` files in your stack's root directory in dependancy order, so you can organize your stacks configuration into multiple files just like Terraform configuration.

#### Review components

Open the `providers.tfstack.hcl` file. This file contains the provider configuration for your stack.

<CodeBlockConfig hideClipboard filename="providers.tfstack.hcl">

```hcl
required_providers {
  aws = {
	source  = "hashicorp/aws"
	version = "~> 5.59.0"
  }
  kubernetes = {
	source  = "hashicorp/kubernetes"
	version = "~> 2.32.0"
  }
  random = {
	source = "hashicorp/random"
	version = "~> 3.6.2"
  }
}

provider "aws" "main" {
  config {
	region = var.region

	assume_role_with_web_identity {
  	role_arn       	= var.role_arn
  	web_identity_token = var.identity_token
	}

	default_tags {
  	tags = var.default_tags
	}
  }
}

provider "kubernetes" "main" {
  config {
	host               	= component.cluster.cluster_url
	cluster_ca_certificate = component.cluster.cluster_ca
	token              	= component.cluster.cluster_token
  }
}

provider "random" "main" {}
```

</CodeBlockConfig>

The `required_providers` block defines the providers used in this configuration,
and uses a syntax similar to the `required_providers` block nested inside the
`terraform` block in Terraform configuration.

This configuration also includes `provider` blocks that configure each provider.
Unlike Terraform configuration, stacks provider blocks include a label, allowing
you to configure multiple providers of each type if needed. The configuration
also includes a `for_each` block so that stacks will use a seperate AWS provider
configuration for each region. Terraform stacks allow you to write stacks
configurations that deploy similar infrastructure across multiple cloud provider
regions.

Next, review the `components.tfstack.hcl` file. This file contains all of the
components for your stack. Like Terraform configuration, you can organize your
stacks configuration into multiple files without affecting the resulting
infrastructure.

<CodeBlockConfig hideClipBoard filename="components.tfstack.hcl">

```hcl
component "cluster" {
  source = "./cluster"

  providers = {
	aws = provider.aws.main
	random = provider.random.main
  }

  inputs = {
	cluster_name   	= var.cluster_name
	kubernetes_version = var.kubernetes_version
	region = var.region
  }
}

component "kube" {
  source = "./kube"

  providers = {
	kubernetes = provider.kubernetes.main
  }
}
```

</CodeBlockConfig>

This file includes configuration for two components, one for the EKS cluster
itself, and another for the example API for this tutorial.

#### Review deployments

<CodeBlockConfig hideClipboard filename="deployments.tfdeploy.hcl">

```hcl
identity_token "aws" {
  audience = ["aws.workload.identity"]
}

deployment "development" {
  inputs = {
	cluster_name    	= "stacks-demo"
	kubernetes_version  = "1.30"
	region          	= "us-east-1"
	role_arn        	= var.role_arn
	identity_token  	= identity_token.aws.jwt
	default_tags    	= { stacks-preview-example = "eks-deferred-stack" }
  }
}
```

</CodeBlockConfig>

This stack includes a single deployment of your Kubernetes cluster on AWS.

### Create stack

Return to your project by navigating to `Projects` and selecting your `Learn
Terraform stacks` project. Select `Stacks` from the left nav and click `+ New
stack`.

On the `Connect to VCS` page, select your GitHub account. Then, choose the
repository you created for this tutorial, `learn-terraform-stacks-eks-deferred`.
On the next page, leave your stack name the same as your repository name, and
click `Create stack` to create it.

HCP Terraform will load your stacks configuration from your VCS repository.
Click the `Fetch configuration from VCS` button to start that process.

### Provision Kubernetes

Once HCP Terraform loads your configuration, it will plan your changes. HCP
Terraform will plan each deployment seperately, and you can choose when to apply
each plan.

Select your `development` deployment to review the plan status. Once the plan is
complete, you can review the resources that HCP Terraform will create, and apply
the plan.

Once HCP Terraform loads your configuration, it will plan your changes. Select
your `development` deployment to review the plan status. Once the plan is
complete, you can review the resources that HCP Terraform will create, and apply
the plan.

<Note>

It may take a few minutes to provision the EKS cluster.

</Note>

As it provisions your infrastructure, HCP Terraform will automatically detect
that the API you are dpeloying on your Kubernetes cluster is waiting on the
other Kubernetes components to deploy successfully, and will defer those changes
until the components are available. Then it will load the attribute values and
proceed with the plan.

### Destroy infrastructure

Now you have used a Terraform stack to deploy a Kubernetes cluster with an API.
HCP Terraform was able to deploy the entire stack as a single unit, despite the
dependecy between the API and the Kubernetes cluster.

Before finishing this tutorial, destroy your infrastructure.

Navigate to your stack's `Deployments` page, and select the `development`
deployment. Navigate to the `Destruction and Deletion` page and click the
`Destroy infrastructure` button to create a destroy plan. Once the destroy plan
is complete, apply it to remove your resources.

Finally, remove your stack by navigating back to your stack and selecting your
stack's  `Destruction and Deletion` page, and clicking the `Force delete stack
learn-terraform-stacks-deploy` button. Confirm the action, and click the
`Delete` button.

### Next steps

In addition to allowing you to orchestrate complex deployments with hidden
dependencies, Terraform stacks include power orchestration and workflow
features.

- Read the [Terraform stacks documentation] for more details on stacks features
  and workflow.
