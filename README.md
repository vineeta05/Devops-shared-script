# AWS CI/CD Pipeline for Java Applications with Blue/Green Deployment

I built this to understand how real CI/CD pipelines work in DevOps. The goal was straightforward: push code to a repository and have it automatically build, containerize, and deploy to production with zero downtime.

What you get is an end-to-end pipeline that handles the entire workflow—from code commit all the way to a running application on ECS Fargate with safe, zero-downtime deployments using Blue/Green strategy.

## The problem this solves

Manual deployments are slow and risky. You push code, someone runs deployment scripts, and if something goes wrong during the swap, you have downtime. This pipeline automates all that and uses Blue/Green deployment to ensure the old version stays running until the new one is validated and working.

## Getting started

### What you need
- AWS account with CLI configured
- Git
- Docker
- Maven 3+
- Java 11

### Deploy it

```bash
# Create the CodeCommit repo
aws codecommit create-repository --repository-name java-cicd-repo --region us-east-1

# Push your code
cd java-cicd
git remote set-url origin https://git-codecommit.us-east-1.amazonaws.com/v1/repos/java-cicd-repo
git push -u origin main

# Deploy the pipeline
cd ../cloudformation
aws cloudformation create-stack \
  --stack-name test-pipeline-stack \
  --template-body file://pipeline.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Check the status
aws cloudformation describe-stacks \
  --stack-name test-pipeline-stack \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus'
```

## How it's organized

```
aws-cicd-ecs-bluegreen/
├── cloudformation/
│   └── pipeline.yml              # All AWS resources defined here
├── java-cicd/
│   ├── src/main/java/com/demo/
│   │   └── App.java              # The Java app
│   ├── pom.xml                   # Maven config
│   ├── Dockerfile                # Multi-stage Docker build
│   ├── buildspec.yml             # What CodeBuild does
│   └── appspec.yml               # What CodeDeploy does
└── README.md
```

## How it flows: From code to running application

1. **You push code** to CodeCommit (AWS's version of GitHub)
2. **CodeBuild picks it up**, compiles the Java code, and creates a Docker image
3. **Image gets pushed** to ECR (AWS's container registry)
4. **Manual approval stage** - Someone reviews before proceeding to production
5. **CodeDeploy handles the deployment** with Blue/Green strategy (explained below)
6. **CloudWatch captures logs** so you can see what's happening

The entire thing is triggered automatically—no manual steps, no "wait, did we forget to restart the service?"

## How the IAM roles work

Each AWS service gets its own role with only what it needs:

- **CodeBuildServiceRole** - Can compile code and push to ECR
- **CodePipelineRole** - Can orchestrate the stages
- **CodeDeployRole** - Can deploy to target servers

This follows the principle of least privilege. If something gets compromised, the damage is limited to what that role can do.

## Why we use ECR Public for base images

Initially tried pulling Docker base images from Docker Hub, but ran into rate limiting on repeated builds. Switched to AWS ECR Public instead, which mirrors common images (maven, java, etc) and has no rate limits.

**Before:**
```dockerfile
FROM maven:3-eclipse-temurin-11
```

**After:**
```dockerfile
FROM public.ecr.aws/docker/library/maven:3-eclipse-temurin-11
```

Same image, but pulled from ECR Public. Builds are reliable now.

## Multi-stage Docker builds

The Dockerfile uses two stages:
- **Build stage** (400MB) - Has Maven and build tools, compiles the code
- **Runtime stage** (70MB) - Only has Java runtime, runs the compiled JAR

Final image is about 7x smaller than if we shipped everything. Faster deploys, less storage.

## Infrastructure as Code

The entire pipeline is defined in `pipeline.yml` using CloudFormation. No manual clicking around in the AWS console. You can version control it, review changes, and deploy consistently.

## Blue/Green Deployment: Why this matters

Instead of stopping the old version and starting the new one (which causes downtime), we run both at the same time:

- **Blue** = your currently running version handling all the traffic
- **Green** = the new version you're about to release, running in parallel but not yet receiving traffic

Once Green is validated and working correctly, we shift traffic to it. If something goes wrong, we switch back to Blue instantly. The user never sees any downtime.

This was one of the key things I wanted to understand—how real companies deploy without their services going offline, even for 30 seconds.

## What I built and what I learned

- **How CI/CD actually works** - It's not magic, it's just automation of steps you'd normally do manually
- **Docker in practice** - Multi-stage builds, why base image choice matters (rate limiting is real), how containerization works
- **IAM and security** - Why each service needs only specific permissions (principle of least privilege)
- **Infrastructure as Code** - Everything is in CloudFormation, so deployments are reproducible and version-controlled
- **ECS Fargate** - Container orchestration without managing servers

The trickiest part was understanding how all the pieces fit together. Path issues, branch naming, registry selection—it all matters.

## Troubleshooting

### Stack creation fails with "role already exists"
Check CloudWatch logs for the exact error. Usually means a role from a previous deployment is interfering. Delete the old stack and manually remove conflicting IAM roles, then try again.

### Build fails with permission errors
Check the IAM role permissions in CloudFormation. The error message usually tells you which permission is missing. Add it to the policy and redeploy.

### Can't push to CodeCommit
Make sure you're using AWS credentials (not GitHub credentials). If you're using SSH, set up the SSH keys properly in your AWS account.

## Cleanup

If you're done and want to delete everything to save costs:

```bash
# Empty the S3 bucket first
aws s3 rm s3://aws-cicd-ecs-bluegreen-bucket --recursive --region us-east-1

# Delete the stack
aws cloudformation delete-stack --stack-name test-pipeline-stack --region us-east-1

# Delete the CodeCommit repo
aws codecommit delete-repository --repository-name java-cicd-repo --region us-east-1
```

## Cost

Most of this fits in AWS free tier:
- CodeCommit, CodeBuild (100 min/month), CodePipeline, S3 (5GB), ECR Public - all free
- Actual monthly cost for development work: $0-5

## References

- [AWS CloudFormation docs](https://docs.aws.amazon.com/cloudformation/)
- [CodePipeline how-to](https://docs.aws.amazon.com/codepipeline/)
- [Docker multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [ECR Public Gallery](https://gallery.ecr.aws/)

---

**Built by:** Vineeta Singh as a learning project in DevOps
