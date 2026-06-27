# Secure, High-Availability AWS Three-Tier Architecture via Terraform

## 📌 Project Overview
This repository contains a modular, production-ready, and fully parameterized Terraform configuration that provisions a secure, highly available **Three-Tier Infrastructure** on AWS. 

The entire project is structured using a **Parent-Child Module Model** where no values are hardcoded in the infrastructure resource blocks. To ensure compliance with enterprise engineering standards, all environment-specific values flow directly from the parent configuration down to isolated infrastructure components.
---
### 🏗️ Architecture Design
The infrastructure is engineered across **two Availability Zones (AZs)** to ensure fault tolerance and high availability while remaining fully compliant within the **AWS Free Tier**:

1. **Public Tier (Web Layer):** Houses an external Application Load Balancer (ALB) distributed across two public subnets to accept incoming internet traffic (`HTTP/80`).
2. **Application Tier (Private Compute Layer):** Houses an Auto Scaling Group (ASG) running Amazon Linux 2 instances across two private subnets. Traffic is securely restricted to inbound requests originating *only* from the ALB's security group.
3. **Database Tier (Private Data Layer):** Houses an isolated Amazon RDS PostgreSQL instance mapped across a Multi-AZ DB Subnet Group. It completely blocks all direct internet egress/ingress, allowing stateful connections *only* from the application tier on port `5432`.

<img width="16950" height="10538" alt="Diag" src="https://github.com/user-attachments/assets/4935f073-57a7-411c-beb9-b1cb58fc072f" />

---
🛠️ Prerequisites & Workspace Setup:

To run this project seamlessly within Visual Studio Code, ensure your local development environment is configured with the following tools:

🧰 Required Software:

🗃️ Visual Studio Code: The primary IDE used for writing and executing the code.

🏗️ Terraform CLI: Core binary (>= 1.0) installed on your local machine and added to your system's PATH.

💻 AWS CLI: Installed locally to manage authentication.

🔌 Recommended VS Code Extensions:

To make editing a breeze, install these extensions from the VS Code Marketplace:

🧩 HashiCorp Terraform: Enables syntax highlighting, autocompletion, and real-time formatting (terraform fmt) as you type.

⚡ AWS Toolkit: Provides integrated AWS resource management right from your sidebar.

---
## 📂  Terraform Structure:

```text
terraform-three-tier-vpc/
├── main.tf                 # Parent module declarations
├── variables.tf            # Parent input variable definitions
├── outputs.tf              # Root output mappings (ALB DNS endpoint)
├── terraform.tfvars        # The single source of input configuration
├── providers.tf            # AWS Provider constraints
└── modules/
    ├── vpc/                # Subnets, Internet Gateways, and Route Tables
    ├── security_groups/    # Tier-to-tier stateful firewall definitions
    ├── compute/            # Application Load Balancer, Launch Templates, and ASG
    └── database/           # RDS Subnet Groups and DB Instance provisioning
```
---
### 🛠️ Step 1: Detailed Explanation of Root (Parent) Files
At the root level, these files act as the project manager. They don't create specific resources like EC2 instances directly—instead, they take your settings, configure the connection to AWS, and pass values down to the child modules.
---
### 1️⃣ `providers.tf` (The Cloud Connector):

This file establishes the connection between Terraform and Amazon Web Services (AWS).

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```
### Notes:
- _What it is: The Cloud Plugin Provider block._
- _Why we use it: Terraform is cloud-agnostic; it doesn't know how to talk to AWS by default. This file tells Terraform to download the official AWS API plugin._
- _Key Detail: We use version = "~> 5.0" to pin the provider version. This is a crucial production habit—it ensures that if HashiCorp or AWS updates their plugin tomorrow, your code won't randomly break. Notice region = var.aws_region contains no hardcoding; it dynamically reads whatever region you choose later._

### 2️⃣ `Variables.tf` (The Input Framework):

```hcl
#--------------Region----------------
variable "aws_region" {
    description = "AWS region to deploy resources"
    type        = string
    }
#----------environment----------------
variable "environment" {
    description = "Environment name (e.g., dev, staging, prod)"
    type        = string
    }
#-----------Project Name----------------
variable "project_name" {
    description = "Project name for resource naming"
    type        = string
    }
#-----------VPC CIDR Block----------------
variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type        = string
    }
#-----------Public Subnet CIDR Blocks----------------
variable "public_subnet_cidrs" {
    description = "List of CIDR blocks for public subnets"
    type        = list(string)
    }
#-----------Private Subnet CIDR Blocks----------------
variable "private_subnet_cidrs" {
    description = "List of CIDR blocks for private subnets"
    type        = list(string)
    }
#----------App subnet CIDR Blocks----------------
variable "app_subnet_cidrs" {
    description = "List of CIDR blocks for application subnets"
    type        = list(string)
    }
#----------Database subnet CIDR Blocks----------------
variable "db_subnet_cidrs" {
    description = "List of CIDR blocks for database subnets"
    type        = list(string)
    }
#---------------Instance type-----------------
    variable "instance_type" {
  description = "The EC2 instance type for the application tier"
  type        = string
  default     = "t2.micro" 
}
```
### Notes:
- _What it is: The input blueprint data definitions._
- _Why we use it: This defines the structure of data your project accepts. It doesn't set the values; it just declares that these variables must exist._
- _Key Detail: For db_username and db_password, we mark them as sensitive = true. This tells Terraform to mask these values in your VS Code terminal output, preventing passwords from showing up in plaintext logs or screen shares._

### 3️⃣ `Terraform.tfvars` (The Parameter Values):

```hcl
aws_region          = "ap-southeast-1"
environment         = "prod"
project_name        = "three-tier-architecture"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
app_subnet_cidrs    = ["10.0.11.0/24", "10.0.12.0/24"]
db_subnet_cidrs     = ["10.0.21.0/24", "10.0.22.0/24"]
db_username = "DBadmin"
db_password = "SecureDBpassword!123"                # Must be at least 8 characters
instance_type = "t3.micro"
```
### Notes:
- _What it is: The actual values file._
- _Why we use it: This is the only file in your entire project where configuration data is written by hand._
- _Key Detail: By separating this from the actual logic files, your code becomes modular. If you want to deploy an identical environment for a production tier (prod), you don't rewrite your infrastructure—you just swap this single file out or feed a different .tfvars file to your terminal._

### 4️⃣ `Main.tf` (The Core Infrastructure Logic):
```hcl
#-----------VPC Module----------------
module "vpc" {
 source = "./modules/vpc"
 project_name = var.project_name
 environment = var.environment
 vpc_cidr = var.vpc_cidr
 public_subnet_cidrs = var.public_subnet_cidrs
 app_subnet_cidrs = var.app_subnet_cidrs
 db_subnet_cidrs = var.db_subnet_cidrs
}
#-----------Security Group Module----------------
module "security_group" {
  source       = "./modules/security_group"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}
#-------------Database Module--------------
variable "db_name" {
  type = string
  default = "myappdb"
}
variable "db_username" {
  type = string
  sensitive = true
}
variable "db_password" {
  type = string
  sensitive = true
}
module "database" {
  source          = "./modules/database" 
  project_name    = var.project_name
  environment     = var.environment
  db_subnet_ids   = module.vpc.db_subnet_ids
  vpc_id = module.vpc.vpc_id
  db_sg_id        = module.security_group.db_sg_id 
  db_name         = var.db_name
  db_username     = var.db_username
  db_password     = var.db_password
}
#--------------compute module--------------
module "compute" {
  source = "./modules/compute"
  project_name = var.project_name
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids
  app_subnet_id = module.vpc.public_subnet_ids
  alb_sg_id = module.security_group.alb_sg_id
  app_sg_id = module.security_group.app_sg_id
  instance_type = var.instance_type
}
```
### Notes:
- _What it is: The central routing hub (Module Instantiation)._
- _Why we use it: This file maps the parent inputs directly into the child modules. It acts as a bridge._
- _Key Detail: This file enables Dependency Injection. If the compute module needs to know the subnet IDs created by the VPC module, you pass them here dynamically using public_subnet_ids = module.vpc.public_subnet_ids. Terraform analyzes these relationships to map out exactly what order to build your infrastructure._

### 5️⃣ `outputs.tf` (The Post-Deployment Print):
```hcl
output "application_url" {
  value       = "http://${module.compute.alb_dns_name}"
  description = "Access your application using this URL"
}
```
### Notes:
- _What it is: The final terminal summary._
- _Why we use it: When your infrastructure spins up, AWS generates dynamic values (like random IP addresses or DNS endpoints). Instead of hunting through the AWS Console to find your Load Balancer URL, this extracts it from the compute module and displays it right in your VS Code terminal as soon as terraform apply finishes._
----
### 📦 Step 2: Detailed Explanation of the VPC Module `(modules/vpc/)`
This module is responsible for carving out your private, isolated network chunk in the AWS cloud and splitting it into distinct zones.
---
### 1️⃣ `Main.tf` (VPC Child Module):
```hcl
#-----------------Availability Zones-----------------#
# Dynamically fetch available AZs in the region

data "aws_availability_zones" "available" {
    state = "available"
}
#-----------------VPC-----------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}
#------------internet Gateway-----------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}
#-----------------Public Subnets-----------------
resource "aws_subnet" "public" {
 count = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
  } 
}
#--------------Application Subnets(private)-----------------
resource "aws_subnet" "app" {
  count = length(var.app_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
  }
}
#--------------Database Subnets(Private)-----------------
resource "aws_subnet" "db" {
  count = length(var.db_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
  }
}
#------------------Public Route Table & Routing Rules-----------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}
#-----------public Route Table Associations-----------------

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
#------------------Private Route Table (For Application and Database Tier)-----------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}
#-----------------Private Route Table Associations(Application and Database Subnets)-----------------
resource "aws_route_table_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "db" {
  count          = length(aws_subnet.db)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.private.id
}
```
### Notes:
This is where the physical network architecture is declared. Let's break down its critical blocks:

- _The Data Source (data "aws_availability_zones" "available")_
    - _What: Queries the live AWS API for available availability zones in your selected region._
    - _Why: This removes the need to hardcode zone names like us-east-1a. If you change your region to Singapore (ap-southeast-1), this block automatically adapts, making your code highly reusable._

- _The Subnets (aws_subnet for Public, App, and DB)_
  - _What: Loops through your CIDR lists using count = length(...) to provision subnets symmetrically across Availability Zones (count.index)._
  - _Why: It enforces a clean 3-tier structure. The Public Subnets get map_public_ip_on_launch = true so resources like the load balancer can talk to the internet. The App and DB Subnets omit this,             ensuring any instance deployed there remains completely hidden from the open internet._

- _Internet Gateway & Route Tables (aws_internet_gateway, aws_route_table)_
  - _What: Configures the edge routing rules._
  - _Why: The public route table contains a route mapping 0.0.0.0/0 directly to the Internet Gateway, allowing external traffic. The private route table does not route directly to the Internet                  Gateway, ensuring that the backend application and database tiers stay completely private._

### 2️⃣ `Variables.tf` (VPC Child Module):
```hcl
variable "environment" {}
variable "project_name" {}
variable "vpc_cidr" {}
variable "public_subnet_cidrs" {type = list(string)}
variable "app_subnet_cidrs" {type = list(string)}
variable "db_subnet_cidrs" {type = list(string)}
```
### Notes:
- _What it is: The configuration receptors for the network layer._
- _Why we use it: Since child modules are strictly isolated, they cannot "see" your root terraform.tfvars. This file declares the exact inputs this network component requires to function. Notice we don't need to redeclare defaults or descriptions here—the parent module manages those; these are just open slots waiting to receive values._

### 3️⃣ `outputs.tf` (VPC Child Module):

```hcl
#-----------VPC IDs output-----------
output "vpc_id" {
    value       = aws_vpc.main.id
    description = "The ID of the VPC"
}
#----------Public Subnet IDs-----------
output "public_subnet_ids" {
  value       = aws_subnet.public.*.id
  description = "The IDs of the public subnets"
}
#----------App Subnet IDs-----------
output "app_subnet_ids" {
  value       = aws_subnet.app.*.id
  description = "The IDs of the app subnets"
}
#----------DB Subnet IDs-----------
output "db_subnet_ids" {
  value       = aws_subnet.db.*.id
  description = "The IDs of the db subnets"
}
```
### Notes:
- _What it is: The exported network resource attributes._
- _Why we use it: When Terraform creates subnets and VPCs, AWS assigns random resource IDs (like vpc-0a1b2c3d4e). Other modules (like Security Groups or EC2 instances) cannot function without knowing exactly what VPC or subnets they belong to. By declaring these outputs, the VPC module broadcasts these generated IDs back up to the parent main.tf, which can then instantly inject them into the next modules._

### 📦 Step 3: Detailed Explanation of the Security Groups Module `(modules/security_groups/)`:

Instead of using IP address ranges (CIDR blocks) to restrict access, this module uses Security Group Chaining (referencing one security group ID inside another). This is an industry-standard security practice.
---
### 1️⃣ `Main.tf`(Security Groups Child Module):
```hcl
#------------1.ALB Security Group (Public)----------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the ALB"
  vpc_id      = var.vpc_id

#Allow inbound HTTP traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

#Allow inbound HTTPS traffic from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }  

#Allow outbound traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name        = "${var.project_name}-${var.environment}-alb-sg"
        Environment = var.environment
    }
}

#------------2.App Security Group (Private)----------------
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for the App"
  vpc_id      = var.vpc_id

#Allow inbound traffic from ALB security group on port 80
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
 #Outbound: Allow all (for updates, patches, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name        = "${var.project_name}-${var.environment}-app-sg"
        Environment = var.environment
    }
}

#------------3.DB Security Group (Private)----------------
resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for the DB"
  vpc_id      = var.vpc_id

#Only allow PostgreSQL/MySQL port (e.g., 5432) from the App Security Group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
#Outbound: Allow all (for updates, patches, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name        = "${var.project_name}-${var.environment}-db-sg"
        Environment = var.environment
    }
}
```
### Notes:
This is where the stateful firewall rules are established. Let's break down the logic of our three main security groups:

- _ALB Security Group (aws_security_group.alb):_
  - _Ingress (Inbound): Opens up ports 80 (HTTP) and 443 (HTTPS) to 0.0.0.0/0 (the entire internet)._
  - _Why: The Load Balancer is our front door. It must be accessible to public users visiting your application._

- _App Tier Security Group (aws_security_group.app):_
  - _Ingress (Inbound): Opens up port 80, but instead of a CIDR block, it uses security_groups = [aws_security_group.alb.id]._
  - _Why: This is Security Group Chaining. It means that even if someone discovers the private IP address of your application EC2 instances, they cannot access them unless their traffic passes through the ALB first. Direct internet access is completely blocked._

- _Database Tier Security Group (aws_security_group.db)_

  - _Ingress (Inbound): Opens up port 5432 (PostgreSQL) and explicitly sets security_groups = [aws_security_group.app.id]._
  - _Why: Absolute data isolation. The database will completely ignore requests from the public internet, and it will even ignore requests from the public ALB. It only listens to commands coming directly from the application servers._

### 2️⃣ `Variables.tf`(Security Groups Child Module):
```hcl
variable "vpc_id" {
  description = "The VPC ID to associate with the security group"
  type        = string
}
variable"environment" {
  description = "The environment for the security group (e.g., dev, staging, prod)"
  type        = string
}
variable "project_name" {
  description = "The project name for the security group"
  type        = string
}
```
### Notes:
- _What it is: The configuration receptors for your security boundaries._
- _Why we use it: Security groups cannot exist in a vacuum; they must be attached to a specific VPC network footprint. This file declares that the module expects the parent layer to feed it a valid vpc_id (which was generated by the VPC child module)._

### 3️⃣ `outputs.tf`(Security Groups Child Module):
```hcl
#------------application load balancer security group output----------------
output "alb_sg_id" {
  value = aws_security_group.alb.id
}
#------------Application Security Group output----------------
output "app_sg_id" {
  value = aws_security_group.app.id
}
#------------Database Security Group output----------------
output "db_sg_id" {
  value = aws_security_group.db.id
}
```
### Notes:
- _What it is: The exported firewall resource identifiers._
- _Why we use it: When we build our EC2 instances and our RDS database later, AWS needs us to attach these specific firewalls to them. By exporting these IDs, the parent module can catch them and hand them off directly to the Compute and Database modules._

### 📦 Step 4: Detailed Explanation of the Database Module `(modules/database/)`:

This module groups your isolated private database subnets together and provisions an RDS database instance directly inside them.
---
### 1️⃣ `Main.tf`(Database Child Module):
```hcl
#----------DB Subnet Group (Tells RDS which subnets/AZs it can live in)
resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
  description = "subnet group for 3-tier DB layer"
}
#--------------RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"
  allocated_storage = 20                                # Free tier allows up to 20 GB
  max_allocated_storage = 100                           # Auto-scaling storage limit
  engine = "postgres"
  engine_version = "15.18"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  instance_class = "db.t3.micro"
  multi_az             = true
  db_name = var.db_name
  username = var.db_username
  password = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]

  skip_final_snapshot = true                       # Prevents errors/costs when running 'terraform destroy'                 

tags = {
    Name        = "${var.project_name}-${var.environment}-rds"
    Environment = var.environment
  }
}
```
### Notes:
This file sets up your data storage footprint. Let's examine the design choices:

- _DB Subnet Group (aws_db_subnet_group.main):_
  - _What: Collects the private database subnet IDs across your two Availability Zones and registers them with the RDS engine._
  - _Why: AWS Relational Database Service requires a subnet group to know which physical data centers it is allowed to use. Even though we are launching a single database instance to save costs, grouping subnets across multiple AZs ensures that your infrastructure is structurally prepared for high-availability failover modes._

- _The RDS Instance (aws_db_instance.main):_ 
  - _What: Provisions a PostgreSQL database engine using the Free Tier eligible db.t3.micro instance type and allocates 20 GB of storage._
  - _Why: To ensure the project runs completely cost-free._

- _Key Controls: * publicly_accessible = false ensures that the database receives absolutely no public IP address, isolating it from external internet threats._
  - _multi_az = false forces the database to run in a single zone to fit within the Free Tier limits._
  - _skip_final_snapshot = true bypasses the automated final backup phase when running a tear-down operation. This is critical for testing environments so that running terraform destroy successfully cleans up your account without stalling or leaving orphaned, billable backup volumes behind._

 ```text
📊 Database Tier (Single-AZ vs. Multi-AZ):
In the production-ready Terraform configuration (`modules/database/main.tf`), the codebase is pre-configured to support a synchronous, high-availability **Multi-AZ deployment** via the `multi_az = true` attribute. 

However, during the initial deployment phase, the architecture utilizes a single database instance inside a single Availability Zone due to AWS resource constraints:
* **Current Implementation:** Single-AZ deployment using `db.t3.micro`.
* **The Constraint:** AWS RDS restricts Multi-AZ replication on lower-tier burstable instance classes (such as `micro` and `small`). Passing `multi_az = true` on a `db.t3.micro` instance is not supported by the AWS engine ecosystem.
* **Production Scaling:** To upgrade this infrastructure for a resilient production environment, you only need to change the instance class attribute.
Changing the instance type to a production-supported class (e.g., `db.t3.medium` or higher) will immediately unlock the multi-zone standby replica.
```

### 2️⃣ `Variables.tf`(Database Child Module):
```hcl
#-------------environment variable for the DB----------------
variable "environment" {
  description = "The environment for the database (e.g., dev, staging, prod)"
  type        = string
}
#-------------project_name variable for the DB----------------
variable "project_name" {
  description = "The project name for the database"
  type        = string
}
#-------------Subnet IDs for the DB----------------
variable "db_subnet_ids" {
  description = "subnet IDs for the Database"
  type = list(string)
}
#-------------Security group variable for the DB----------------
variable "db_sg_id" {
  description = "The security group ID for the database"
  type        = string
}
#-------------Database name-------------------
variable "db_name" {
  description = "the name of the database to create"
  type = string
}
#------------Databse Username-----------------
variable "db_username" {
  description = "Username for the DB user"
  type = string
}
#-------------Database username password----------
variable "db_password" {
  description = "Password for the master DB user"
  type = string
  sensitive = true
}
#---------------VPC ID---------------------------
variable "vpc_id" {
  description = "The ID of the VPC where the database subnet group will be created"
  type        = string
}
```
### Notes:
- _What it is: The configuration receptors for the data layer._
- _Why we use it: To keep credentials secure and components decoupled. Instead of baking credentials or network IDs into the module logic, this file declares what data inputs the database requires. Notice that db_username and db_password are marked as sensitive = true here as well, ensuring that child module execution logs protect your master credentials._

### 3️⃣ `outputs.tf`(Database Child Module):
```hcl
output "db_endpoint" {
  value = aws_db_instance.main.endpoint
  description = "the connection endpoint for the RDS instance"
}
```
### Notes:
- _What it is: The exported connection string._
- _Why we use it: When AWS provisions an RDS instance, it generates a unique backend endpoint string (e.g., three-tier-db.c123456789.us-east-1.rds.amazonaws.com:5432). Your application servers in the compute layer require this exact address to send data queries. Exporting this string allows the parent layer to capture it and pass it along to your application logic._

### 📦 Step 5: Detailed Explanation of the Compute Module `(modules/compute/)`:

This module uses dynamic data to grab the latest OS image, sets up a public-facing entry point, and connects an automated installation script to your application layer.
---
### 1️⃣ `Main.tf`(Compute Child Module):
```hcl
#---------------1.Fetch latest Amazon linux 2 AMI dynamically
data "aws_ami" "amzon_linux_2" {
  most_recent = true
  owners = [ "amazon" ]

  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-x86_64-gp2" ]
  }
}
#------------------2.Applicaion Load Balancer (Public Tier)
resource "aws_lb" "external" {
  name = "${var.project_name}-${var.environment}-alb"
  internal = false 
  load_balancer_type = "application"
  security_groups = [var.alb_sg_id]
  subnets = var.public_subnet_id

tags = {
  name  = "${var.project_name}-${var.environment}-alb"
  environment = var.environment
 }
}
#-----------------3.ALB Target Group (Points to our App Tier)
resource "aws_alb_target_group" "app" {
  name = "${var.project_name}-${var.environment}-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "instance"

  health_check {
    path = "/"
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 5
    interval = 30
    matcher = "200"
  }
}
#-----------------------4.ALP HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }
}
#-----------------------5.Launch Template for ASG
resource "aws_launch_template" "app" {
  name_prefix = "${var.project_name}-${var.environment}-template-"
  image_id = data.aws_ami.amzon_linux_2.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true  
    security_groups = [var.app_sg_id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Forces IMDSv2
    http_put_response_hop_limit = 2          # Allows tokens to hop down to applications/scripts cleanly
  }
  # Simple User Data script to start a mock webserver showing high availability
 user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              
              LOCAL_IP=$(hostname -I | awk '{print $1}')
              echo "<h1>Hello World from IP: $LOCAL_IP inside our Secure 3-Tier VPC!</h1>" > /var/www/html/index.html
              EOF
  )
tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-app-server"
      Environment = var.environment
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}
#-----------------------6. Auto Scaling Group spanning across Private App Subnets
resource "aws_autoscaling_group" "app" {
  name_prefix = "${var.project_name}-${var.environment}-asg-"
  vpc_zone_identifier = var.app_subnet_id
  target_group_arns = [aws_alb_target_group.app.arn]

  min_size = 1
  max_size = 2
  desired_capacity = 2 # Forces deployment to both Availability Zones for HA

  launch_template {
    id  = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  
  }

  tag {
    key = "Name"
    value = "${var.project_name}-${var.environment}-app-server"
    propagate_at_launch = true
  }
}
```
### Notes:
This file provisions your public load balancer, a scalable tier configuration, and handles automation tasks. Let's break down its key elements:

- _The AMI Data Source (data "aws_ami" "amazon_linux_2"):_
  - _What: Dynamically queries the AWS catalog for the newest, officially patched Amazon Linux 2 image._
  - _Why: Hardcoding AMI IDs (like ami-0c55b159cbfafe1f0) breaks code quickly because AWS deprecates old images regularly, and AMI IDs change across regions. This lookup keeps your deployments reliable and current._

- _Application Load Balancer & Listeners (aws_lb, aws_lb_listener):_
  - _What: Sets up an internet-facing routing hub inside the public subnets._
  - _Why: This acts as your application's front door. The listener intercepts incoming public traffic on port 80 and pushes it back into your private subnets where your compute resources live._

- _Launch Template & User Data (aws_launch_template):_ 
  - _What: A standard blueprint detailing how to configure newly spawned compute nodes._
  - _Why: It injects a script (user_data) using base64 encoding to automatically update packages, install Apache web servers, and publish a default landing page showing the server's unique hostname._

- _Auto Scaling Group (aws_autoscaling_group):_

  - _What: Spans your private application subnets and manages computing capacities (min, max, desired)._
  - _Why: To automate high-availability operations. If an EC2 instance crashes or a data center experiences an unexpected outage, this group instantly reads the target rules and recreates a missing server in the alternative availability zone automatically._

### 2️⃣ `Variables.tf`(Compute Child Module):
```hcl
variable "environment" {type = string}
variable "project_name" {type = string}
variable "vpc_id" {type = string}
variable "public_subnet_id" {type = list(string) }
variable "app_subnet_id" {type = list(string)}
variable "alb_sg_id" {type = string}
variable "app_sg_id" {type = string}

variable "instance_type" {
  type = string
  default = "t2.micro"
}
```
### Notes:
- _What it is: The configuration receptors for your active application infrastructure._
- _Why we use it: To dynamically link computing components across networks. This file requests network subnet strings, target VPC identifiers, and security firewall group associations. It defaults your hardware footprint to t2.micro to maintain total compliance with the AWS Free Tier._

### 3️⃣ `outputs.tf`(Compute Child Module):
```hcl
output "alb_dns_name" {
  value       = aws_lb.external.dns_name
  description = "The public DNS name of the application load balancer"
}
```
### Notes:
- _What it is: The exported application web endpoint._
- _Why we use it: Because your backend compute nodes are locked safely inside completely private networks, they do not possess public IP addresses. This output extracts the public URL generated by your Application Load Balancer so your root configuration layer can present it to users for browser testing._

------

## 🚀 The Terraform Deployment Lifecycle:

Execute these commands step-by-step within your VS Code integrated terminal (`Ctrl + \``) to deploy your infrastructure.
---
### 1️⃣ `terraform init`  (Initialization):
```hcl
terraform init
```
### Notes:
- _What it does: This command scans your configuration files (specifically providers.tf) and downloads the correct AWS plugin binaries into a hidden .terraform directory in your workspace._
- _Why we use it: Terraform is cloud-agnostic. It doesn't come pre-packaged with AWS logic. Running init prepares your local VS Code environment with the exact tools needed to speak to AWS APIs._

### 2️⃣ `terraform apply` (Live Provisioning):
```hcl
terraform apply -auto-approve
```
### Notes:

- _What it does: This command executes the actions outlined in your plan. It connects to AWS, provisions your S3 bucket, opens public access, attaches the policy, and uploads your inline index.html and error.html pages._
- _Why we use it: This is the trigger that transitions your code into live, running cloud resources. The -auto-approve flag tells Terraform to skip the interactive "yes/no" confirmation prompt, speeding up execution directly within your terminal._

### 🌍 Accessing Your Live Site:

 "http://three-tier-architecture-prod-alb-867500980.ap-southeast-1.elb.amazonaws.com"
 
## OR
### 3️⃣`terraform output` (Inspecting State Results):
```hcl
terraform output
```
### Notes:
-  _What it does: This command extracts and displays the values declared in your outputs.tf file directly from your current local state file._
- _Why we use it: If you clear your VS Code terminal screen or need to find your website link again later, you don't need to re-run your entire infrastructure deployment. Running terraform output instantly retrieves your live S3 website endpoint URL from your state file in milliseconds without touching AWS._
---
### 🔍 Verifying the Output:

### _When your deployment finishes successfully,login the AWS console and verify the output._
<img width="661" height="143" alt="Instances overview" src="https://github.com/user-attachments/assets/bb8eed13-b05c-4811-8ecd-dd7e96c9f277" />
<img width="646" height="139" alt="Instances 1-IP" src="https://github.com/user-attachments/assets/79988616-3f87-44d7-aad1-7679786edac8" />
<img width="646" height="139" alt="Instances 2-IP" src="https://github.com/user-attachments/assets/bbec37a9-c1e5-4b88-ad46-5844b3dbefcf" />
<img width="667" height="139" alt="Security Group" src="https://github.com/user-attachments/assets/4777eec7-c446-417c-b8ed-63e0eb3c68f1" />
<img width="788" height="198" alt="Data base " src="https://github.com/user-attachments/assets/04765fcb-d091-4eeb-aa7e-8c07e9deed6e" />
<img width="784" height="324" alt="Auto Scaling group " src="https://github.com/user-attachments/assets/1c1b6d82-d373-4834-85f3-a07429261e47" />

### 🌍 Accessing Your web side Live Site:

<img width="793" height="400" alt="web site-1" src="https://github.com/user-attachments/assets/2d5ff098-9f53-44b1-87e9-3eee7f8442f7" />
<img width="796" height="399" alt="web site-2" src="https://github.com/user-attachments/assets/cd4f2446-6329-4ca7-b4bd-58b35504bcbb" />

---
## 🎉 Project Complete!

You have successfully completed a fully parameterized, high-availability, 3-tier AWS architecture using a parent-child module framework.
