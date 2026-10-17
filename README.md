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


## AWS Deployment (EC2 + ECR + GitHub Actions)

Infrastructure (EC2, ECR repos, GitHub OIDC role) is created with Terraform from the separate `aws-infrastructure/` folder.

Live: http://13.50.28.13:8080

- **CI** ([.github/workflows/ci.yml](.github/workflows/ci.yml)): runs on every pull request to `main` and before every deploy. Prettier lint, `npm audit` (report only), and an integration test that starts the full stack with Docker Compose and checks the frontend, public API, admin login, and that server/MongoDB ports stay private.
- **CD** ([.github/workflows/deploy.yml](.github/workflows/deploy.yml)): every push to `main` runs CI first, then builds both images, pushes them to ECR (tagged with the commit SHA and `latest`), SSHes to the EC2, writes `.env`, runs `docker compose -f docker-compose.prod.yml pull && up -d`, then smoke-tests `/api/category/list`.

The EC2 runs client (nginx, port 8080), server and MongoDB from [docker-compose.prod.yml](docker-compose.prod.yml); it never builds images.

Required repository settings (Settings → Secrets and variables → Actions):

| Type | Name | Value |
| --- | --- | --- |
| Variable | `AWS_REGION` | `eu-north-1` |
| Variable | `AWS_ROLE_ARN` | `terraform output github_actions_role_arn` |
| Variable | `ECR_REGISTRY` | `terraform output ecr_registry` |
| Variable | `EC2_HOST` | `terraform output elastic_ip` |
| Secret | `EC2_SSH_KEY` | Private key of the EC2 key pair |
| Secret | `JWT_SECRET` | `openssl rand -hex 32` |
| Secret | `ADMIN_EMAIL` | Admin account created by the seed |
| Secret | `ADMIN_PASSWORD` | Admin account password |

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

