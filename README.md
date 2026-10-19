# MERN Ecommerce

## Description

An ecommerce     store built with MERN stack, and utilizes third party API's. This ecommerce store enable three main different flows or implementations:

1. Buyers browse the store categories, products and brands
2. Sellers or Merchants manage their own brand component
3. Admins manage and control the entire store components 

### Features:

  * Node provides the backend environment for this application
  * Express middleware is used to handle requests, routes
  * Mongoose schemas to model the application data
  * React for displaying UI components
  * Redux to manage application's state
  * Redux Thunk middleware to handle asynchronous redux actions

## Demo

This application is deployed on Vercel Please check it out :smile: [here](https://mern-store-gold.vercel.app).

See admin dashboard [demo](https://mernstore-bucket.s3.us-east-2.amazonaws.com/admin.mp4)

## Docker Guide

To run this project locally you can use docker compose provided in the repository. Here is a guide on how to run this project locally using docker compose.

Clone the repository
```
git clone https://github.com/mohamedsamara/mern-ecommerce.git
```

Edit the dockercompose.yml file and update the the values for MONGO_URI and JWT_SECRET

Then simply start the docker compose:

```
docker-compose build
docker-compose up
```

## Database Seed

* The seed command will create an admin user in the database
* The email and password are passed with the command as arguments
* Like below command, replace brackets with email and password. 
* For more information, see code [here](server/utils/seed.js)

```
npm run seed:db [email-***@****.com] [password-******] // This is just an example.
```

## Install

`npm install` in the project root will install dependencies in both `client` and `server`. [See package.json](package.json)

Some basic Git commands are:

```
git clone https://github.com/mohamedsamara/mern-ecommerce.git
cd project
npm install
```

## ENV

Create `.env` file for both client and server. See examples:

[Frontend ENV](client/.env.example)

[Backend ENV](server/.env.example)


## AWS Deployment (Terraform + EC2 + ECR + GitHub Actions)

Live: http://13.48.221.4:8080 (health: `/api/health`)

```
Push / open PR ─► CI: app lint, audit, integration test  +  Terraform fmt, validate, plan (posted on the PR)
               ─► Review the code and the infrastructure plan
               ─► Merge to protected main (PR + green checks required)
               ─► CD: Terraform plan ─► approve `production` ─► Terraform apply   (only if infra changed)
                      build images ─► push to ECR ─► deploy to EC2 over SSH
               ─► Smoke tests & /api/health (must report this commit, DB connected)
```

- **CI** ([.github/workflows/ci.yml](.github/workflows/ci.yml)): every pull request to `main`, and again inside CD. Prettier lint, `npm audit` (report only), a Docker Compose integration test (frontend, health, public API, admin login, private ports), and Terraform `fmt`/`validate`. On PRs it also runs `terraform plan` with a read-only role and posts the plan as a PR comment.
- **CD** ([.github/workflows/deploy.yml](.github/workflows/deploy.yml)): every push to `main`. Runs CI, then `terraform plan`. If the plan has changes, the **Terraform apply** job waits for approval in the `production` environment and applies exactly that plan file. The EC2 IP and ECR registry are read from `terraform output`, then images are built, pushed to ECR (commit SHA + `latest`), deployed with `docker compose -f docker-compose.prod.yml`, and smoke-tested. A rejected or failed apply stops the deploy.

### Infrastructure ([aws-infrastructure/](aws-infrastructure))

| Folder | Manages | Applied by |
| --- | --- | --- |
| `aws-infrastructure/` | EC2 + security group + Elastic IP, EC2 IAM role, ECR repos, `github-actions-ecr-push` role | CD, after approval |
| `aws-infrastructure/bootstrap/` | S3 state bucket, GitHub OIDC provider, `ecom-cicd-terraform-plan` (read-only) and `ecom-cicd-terraform-apply` roles | By hand, once (`terraform apply` locally) |

State is in S3 (`ecom-cicd-tfstate-<account>`, versioned, encrypted, S3-native locking). Bootstrap is kept out of CD so the pipeline cannot change its own permissions. The plan role can only be assumed by PRs and `main`; the apply role only by jobs in the `production` environment.

The EC2 never builds images; it pulls them from ECR.

Required repository settings (Settings → Secrets and variables → Actions, and Settings → Environments):

| Type | Name | Value |
| --- | --- | --- |
| Variable | `AWS_REGION` | `eu-north-1` |
| Variable | `AWS_ROLE_ARN` | `terraform output github_actions_role_arn` |
| Variable | `TF_PLAN_ROLE_ARN` | `terraform -chdir=bootstrap output terraform_plan_role_arn` |
| Variable | `TF_APPLY_ROLE_ARN` | `terraform -chdir=bootstrap output terraform_apply_role_arn` |
| Secret | `EC2_SSH_KEY` | Private key of the EC2 key pair |
| Secret | `JWT_SECRET` | `openssl rand -hex 32` |
| Secret | `ADMIN_EMAIL` | Admin account created by the seed |
| Secret | `ADMIN_PASSWORD` | Admin account password |
| Environment | `production` | Required reviewer; deployments from protected branches only |
| Branch protection | `main` | PR required, CI checks must pass, applies to admins |

## Vercel Deployment

Both frontend and backend are deployed on Vercel from the same repository. When deploying on Vercel, make sure to specifiy the root directory as `client` and `server` when importing the repository. See [client vercel.json](client/vercel.json) and [server vercel.json](server/vercel.json).

## Start development

```
npm run dev
```

## Languages & tools

- [Node](https://nodejs.org/en/)

- [Express](https://expressjs.com/)

- [Mongoose](https://mongoosejs.com/)

- [React](https://reactjs.org/)

- [Webpack](https://webpack.js.org/)


### Code Formatter

- Add a `.vscode` directory
- Create a file `settings.json` inside `.vscode`
- Install Prettier - Code formatter in VSCode
- Add the following snippet:  

```json

    {
      "editor.formatOnSave": true,
      "prettier.singleQuote": true,
      "prettier.arrowParens": "avoid",
      "prettier.jsxSingleQuote": true,
      "prettier.trailingComma": "none",
      "javascript.preferences.quoteStyle": "single",
    }

```

