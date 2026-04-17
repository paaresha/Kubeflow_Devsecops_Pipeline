# Chat Conversation

Note: _This is purely the output of the chat conversation and does not contain any raw data, codebase snippets, etc. used to generate the output._

### User Input

I have an interview in ZS assosiate - Its a resume deep dive

My resume is below

PAARESHA SARAF
Pune, IN | +91 6005027372 | paareshsaraf@gmail.com | linkedin.com/in/paareshasaraf
PROFESSIONAL SUMMARY
DevOps Engineer with 3 years of experience at Hewlett Packard Enterprise, focusing on AWS cloud infrastructure, Kubernetes
orchestration, and CI/CD automation. Demonstrated ability to reduce deployment lead times and optimize cloud operational
costs through strategic auto-scaling and containerization. Recognized by VP as a Top Performer globally (1 of 3 in Asia) for
excellence in project delivery.
SKILLS
• Cloud & Infrastructure: AWS (EKS, EC2, RDS, ElastiCache, SQS, ECR, VPC, IAM, Secrets Manager, SNS), Terraform (IaC),
Ansible, Azure.
• Container Orchestration: Kubernetes, Docker, Helm, Kyverno (Policy-as-Code), External Secrets Operator.
• CI/CD & DevOps: GitHub Actions (OIDC), Jenkins, ArgoCD (GitOps), Nexus, SonarQube, Trivy, LocalStack
• Observability & SRE: AWS CloudWatch, Prometheus, Alertmanager, Grafana, SLO/SLI Engineering
• Scripting & OS: Python, Shell/Bash Scripting, Linux (RHEL, Ubuntu).
PROFESSIONAL EXPERIENCE
Hewlett Packard Enterprise | Pune, IN DevOps Engineer | 09/2023 - Present
• Cloud Migration & Cost Optimization: Led migration of mission-critical legacy workloads to AWS (EKS, RDS, ElastiCache),
achieving a 40% reduction in monthly cloud spend through Spot Instance adoption and traffic-based EC2 rightsizing.
• CI/CD & Pipeline Engineering: Built parallelized CI/CD pipelines using Jenkins and GitHub Actions with integrated Trivy
container scanning, automated quality gates, and GitHub OIDC for keyless AWS authentication — eliminating static
credentials across CI. Implemented changed-service matrix builds and LocalStack-based integration testing for AWS service
mocking in dev.
• Kubernetes & GitOps Platform: Orchestrated production EKS clusters at 99.9% uptime with modular Helm charts and HPAdriven autoscaling. Implemented ArgoCD App-of-Apps GitOps across 3 microservices, reducing cluster interventions by ~90%
and rollback time to under 2 minutes.
• Infrastructure as Code: Designed modular Terraform to provision full-stack AWS environments (VPC, EKS, RDS, IAM/IRSA,
SQS, ECR) with remote state locking and automated plan reviews, cutting provisioning time by 80%.
• Security & Compliance Engineering: Enforced runtime security using Kyverno admission webhooks achieving 100% policy
compliance cluster wide. Eliminated secrets from Git via External Secrets Operator with AWS Secrets Manager, enabling
automated credential rotation across all environments.
• SRE, Observability & Incident Response: Defined SLOs (99.9% availability, P95 < 500ms) and authored comprehensive multilayer alerting rules across application, business, and infrastructure layers.
Hewlett Packard Enterprise | Pune, IN DevOps Intern | 01/2023 - 07/2023
• Configured and deployed a small-scale Software Defined Data Centre (SDDC) environment on HPE ProLiant Gen10 servers to
evaluate deployment stability.
• Gained hands-on experience in compute and storage resource management in a live production environment.
KEY PROJECTS
End-to-End GitOps Architecture on AWS EKS – Github Repo
• Built production grade microservices platform on EKS with full IaC via Terraform, GitOps delivery via ArgoCD App-of-Apps,
Kyverno + External Secrets Operator for security, and Prometheus-based SLO-aligned observability.
Serverless CI/CD & ECS Orchestration
• Designed serverless CD pipeline using AWS CodePipeline and CodeBuild; deployed multi-tier Java app to ECS Fargate with
Blue/Green releases, CodeArtifact, SSM secrets, and CloudWatch-based automated rollback.
Legacy Migration & Cloud Refactoring
• Migrated enterprise application from EC2-based IaaS to managed AWS PaaS using Terraform, achieving ~30% cost reduction
with full disaster recovery readiness.
AWARDS AND HONORS
• Vice President Recognition, Global Remote Delivery (Q3 FY25): Awarded to only 12 employees globally (1 of 3 in Asia) for
exceptional project delivery.
• GSR Top Performer: Recognized as Top Performer for three consecutive quarters (Q3 FY24, Q1 FY25, Q2 FY25) for
consistent operational excellence.
EDUCATION
BE in Computer Science Engineering 08/2019 - 06/2023
D.Y. Patil College of Engineering, Pune | CGPA: 8.92
CERTIFICATIONS
• AWS Certified Cloud Practitioner (CLF-02)
• HPE GreenLake for Private Cloud Business Edition

Also, one of the interviewer has this on his linkedin 

As a Senior Cloud Engineer at ZS, I focus on hosting large language models in EKS, enhancing ArgoCD usability, and designing monitoring solutions for application deployment and ECS/EKS clusters. With a strong foundation in computer engineering from MIT ADT University, I have contributed to streamlining cloud operations and deploying applications using AWS services.  



My core competencies include expertise in AWS, Kubernetes, Terraform, and creating a self serving platform,  which I utilize to deliver efficient and scalable cloud solutions. Motivated by innovation, I collaborate with teams to optimize CI/CD pipelines and enable seamless application lifecycles within cloud environments.

Senior Cloud Engineer

Full-time

Jul 2024 - Present · 1 yr 10 mos

Completed project to host LLM models in EKS and use them within the cluster and running jobs using AWS Batch.
Enhanced ArgoCD user experience by integrating capabilities like application set and ArgoCD notifications.
Designed a monitoring solution to gather information on the tech stack used in application deployment and ECS/EKS clusters using Splunk.

Cloud Engineer

Sep 2022 - Jul 2024 · 1 yr 11 mos

Deployed 100+ applications on ECS with end-to-end CI/CD pipeline using AWS services.
Deployed 25+ applications on EKS with end-to-end CI/CD pipeline using TeamCity, ArgoCD, Helm, etc.
Deployed COTS application on ECS/EKS, like Dependency Track, Sysdig, ArgoCD, etc.
Developed bulk-upgrade automation to patch all CI-CD pipelines at once (500+).
Designed multiple application architectures deployed on ECS/EKS.
Migration of multiple applications from EC2 to ECS/EKS and from ECS to EKS.

 Application Deployment, Multithreaded Development and +1 skill

Cloud Engineer Intern

Nov 2021 - Sep 2022 · 11 mos

Worked on AWS operations and lifecycle management.
Developed CI/CD pipeline for EC2's golden AMI creation.
Developed bootstrapping automations for Windows and Linux servers.
Created policies, procedures, and guidelines related to the deployment of applications in the cloud environment.
Monitored usage trends to optimize resources in order to reduce costs.
Provided technical support for troubleshooting issues with operating systems or applications running on cloud platforms.
Oversaw team in completing job tasks quickly and accurately with appropriate use of instruments and tools.

 Resource Management, Technical Support and +2 skills


Can you tell me what topics I shoudl focus on based on there priotity..Star them 

### Planner Response

# ZS Associates Interview — Resume Deep Dive Prep Guide ⭐

Based on your resume **AND** the interviewer's LinkedIn (EKS + ArgoCD + Monitoring focus), here's your prioritized topic map:

---

## ⭐⭐⭐⭐⭐ CRITICAL — Highest Overlap with Interviewer's Work

These are the intersections where your resume directly meets what he **does daily** — expect deep follow-ups here.

### 1. ArgoCD & GitOps (Your biggest talking point)
| Sub-Topic | Likely Questions |
|---|---|
| App-of-Apps pattern | "Walk me through your App-of-Apps design — why not just multiple Applications?" |
| Sync policies (auto/self-heal) | "How do you handle drift? What happens if someone kubectl applies directly?" |
| ArgoCD Notifications | He built this — "Have you used ArgoCD notifications? How would you alert on sync failures?" |
| ApplicationSets | He enhanced this — "Do you know ApplicationSets? How would they help with 3 microservices?" |
| Rollback under 2 min | "How does ArgoCD achieve that — what's the actual mechanism?" |

### 2. EKS — Deep Production Knowledge
| Sub-Topic | Likely Questions |
|---|---|
| Node groups vs Managed vs Fargate | "Why did you choose managed node groups over Fargate?" |
| IRSA (IAM Roles for Service Accounts) | "Walk me through IRSA vs node-level IAM — token flow?" |
| HPA mechanics | "What metrics drive your HPA? What's the scale-down stabilization window?" |
| EKS + Spot Instances | "How do you handle Spot interruptions with stateful workloads?" |
| 99.9% uptime — how? | "What SLAs did you have? How did you track them?" |

---

## ⭐⭐⭐⭐ HIGH PRIORITY — Core of Your Resume

### 3. Kubernetes Internals
| Sub-Topic | Likely Questions |
|---|---|
| Admission webhooks (Kyverno) | "How does a validating webhook work internally? What happens if the webhook is down?" |
| Helm chart modularization | "What's the difference between Helm values, templates, and library charts?" |
| External Secrets Operator | "How does ESO integrate with AWS Secrets Manager — what's the trust chain?" |
| Pod scheduling & resource requests/limits | "What's the difference between Burstable/Guaranteed/BestEffort QoS?" |

### 4. CI/CD Pipeline Design
| Sub-Topic | Likely Questions |
|---|---|
| GitHub OIDC (keyless auth) | "Walk me through OIDC token exchange with AWS — what's the trust policy?" |
| Changed-service matrix builds | "How did you detect which services changed? What git commands?" |
| LocalStack for AWS mocking | "What services did you mock? What are LocalStack's limitations?" |
| Trivy scanning | "What happens if Trivy finds a CRITICAL vuln — does the build fail?" |
| Jenkins vs GitHub Actions | "When would you choose one over the other?" |

---

## ⭐⭐⭐ MEDIUM PRIORITY — Will Come Up

### 5. Terraform & IaC
| Sub-Topic | Likely Questions |
|---|---|
| State locking (remote backend) | "Why is state locking critical? What backend did you use?" |
| Module design philosophy | "How granular are your modules? One per service, or one per layer?" |
| IRSA setup via Terraform | "How do you provision OIDC provider and role binding in Terraform?" |
| Plan review automation | "How did you automate Terraform plan reviews in CI?" |

### 6. Observability & SRE
| Sub-Topic | Likely Questions |
|---|---|
| SLO/SLI definition | "How did you pick 99.9%? How is that measured technically in Prometheus?" |
| Alertmanager routing | "Walk me through your alert routing — how do you avoid alert fatigue?" |
| Prometheus scrape config | "How does Prometheus discover your EKS pods?" |
| He uses Splunk at ZS | "Have you worked with centralized log aggregation? How does it compare to CloudWatch?" |

### 7. Security
| Sub-Topic | Likely Questions |
|---|---|
| Kyverno policies | "Give me an example of a policy you wrote — what did it block?" |
| Secrets management | "How does automated credential rotation work with ESO + Secrets Manager?" |
| Container scanning strategy | "What's your defense-in-depth approach to container security?" |

---

## ⭐⭐ LOWER PRIORITY — Know Broadly

### 8. AWS Services (Breadth)
- VPC design (subnets, NAT, security groups)
- RDS/ElastiCache — why managed over self-hosted?
- SQS — push vs pull, dead letter queues
- ECS vs EKS trade-offs (he's done both — he WILL ask this)

### 9. Your Project (End-to-End GitOps on EKS)
- Be ready for a **complete live walkthrough** — architecture, decisions, trade-offs
- Why this stack? What would you change?

---

## ⭐ AWARENESS ONLY

### 10. LLM Hosting on EKS (His Current Work)
- He'll likely ask "Do you know anything about hosting ML models on Kubernetes?"
- Know basics: **GPU node pools**, tolerations/node selectors, model serving (TorchServe/Triton)
- **AWS Batch** basics — job queues, compute environments

---

## 🎯 Your Top 5 Specific Prep Bullets

> These are the answers you must rehearse until they feel natural:

1. **"Walk me through your ArgoCD App-of-Apps architecture"** — draw it mentally: root app → child apps → Helm charts → per-env values
2. **"How does IRSA work?"** — OIDC provider → service account annotation → AssumeRoleWithWebIdentity token chain
3. **"How did you achieve 99.9% uptime on EKS?"** — HPA + Pod Disruption Budgets + readiness probes + multi-AZ nodes
4. **"What Kyverno policies did you enforce?"** — have 2-3 concrete examples (no latest tag, require resource limits, deny privileged containers)
5. **"ECS vs EKS — when would you pick each?"** — he's deployed both at ZS, this is almost guaranteed

---

**Overall strategy:** Since the interviewer's daily work is **EKS + ArgoCD + monitoring**, your resume aligns *very strongly*. Go deep on those three areas and frame everything with **"here's the problem, here's why I chose this, here's what I'd do differently."** Good luck! 🚀