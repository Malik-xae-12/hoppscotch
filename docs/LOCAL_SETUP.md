# Local Setup & Development Guide for Hoppscotch

This document details the complete end-to-end setup process for running **Hoppscotch** locally, all configuration adjustments made from the upstream repository, and commands for starting each component.

---

## 1. Architecture & Services

Hoppscotch is organized as a pnpm monorepo consisting of:
- **`hoppscotch-selfhost-web`**: The main frontend web application (Vue 3, Vite, TailwindCSS) running on `http://localhost:3000`.
- **`hoppscotch-backend`**: NestJS application providing REST and GraphQL APIs running on `http://localhost:3170`.
- **`hoppscotch-sh-admin`**: Admin dashboard for self-hosted instances running on `http://localhost:3100`.
- **`hoppscotch-common` / `hoppscotch-data` / `hoppscotch-kernel` / `hoppscotch-js-sandbox`**: Core shared libraries and execution sandboxes.
- **`hoppscotch-db`**: PostgreSQL 15 database service.

---

## 2. All Configuration Changes Made from Upstream

The following modifications were made to ensure seamless local operation and prevent conflicts with existing host services:

### 1. PostgreSQL Port Remapping (`docker-compose.yml`)
- **Default Upstream**: Mapped container port 5432 directly to host port 5432 (`5432:5432`).
- **Problem**: When a local PostgreSQL instance is already installed on the Windows host listening on `0.0.0.0:5432`, the container either fails to bind or intercepts traffic meant for other databases, resulting in authentication errors (`P1000: Authentication failed against database server`).
- **Modification**: Changed the port mapping to `${HOPP_DB_PORT:-5433}:5432` in `docker-compose.yml`. The container now binds cleanly to host port `5433` while remaining on internal port `5432`.

### 2. Root Environment Variables (`.env`)
- Created `.env` from `.env.example`.
- Updated `DATABASE_URL` from the Docker internal hostname (`hoppscotch-db:5432`) to the host-accessible address:
  ```env
  DATABASE_URL=postgresql://postgres:testpass@localhost:5433/hoppscotch
  ```

### 3. Backend Environment File (`packages/hoppscotch-backend/.env`)
- **Reason**: Prisma CLI and `prisma.config.ts` load environment variables relative to the backend workspace package directory (`packages/hoppscotch-backend`) when running CLI tasks directly (e.g., `prisma migrate deploy`).
- **Modification**: Synced `.env` into `packages/hoppscotch-backend/.env` with the matching `DATABASE_URL`.

### 4. Database Migrations
- Applied all 22 Prisma database migrations into PostgreSQL (`hoppscotch` database) via `prisma migrate deploy`.

### 5. Automated Launcher Script (`docs/start-dev.ps1`)
- Added a one-click PowerShell script to orchestrate spinning up the database container, backend server, and frontend server in dedicated terminal windows.

---

## 3. Step-by-Step Setup Instructions

### Prerequisites
- **Git**
- **Node.js** (v20+ recommended, tested on v24)
- **pnpm** (v10+): Install globally via `npm install -g pnpm`
- **Docker Desktop** (WSL2 engine enabled)

---

### Step 1: Clone the Forked Repository

```powershell
git clone https://github.com/Malik-xae-12/hoppscotch.git
cd hoppscotch
```

---

### Step 2: Configure Environment Files

1. Copy `.env.example` to `.env` in the repository root:
   ```powershell
   Copy-Item .env.example .env
   ```

2. Copy `.env` into `packages/hoppscotch-backend/.env`:
   ```powershell
   Copy-Item .env packages/hoppscotch-backend/.env
   ```

3. Ensure `DATABASE_URL` in both `.env` files is set to port `5433`:
   ```env
   DATABASE_URL=postgresql://postgres:testpass@localhost:5433/hoppscotch
   ```

---

### Step 3: Start the PostgreSQL Container

Start the database container using Docker Compose:

```powershell
docker compose up hoppscotch-db -d
```

Verify that the database container is running and healthy:

```powershell
docker ps
```

You should see `hoppscotch-hoppscotch-db-1` with status `Up (healthy)` and port mapped `0.0.0.0:5433->5432/tcp`.

---

### Step 4: Install Dependencies & Build Packages

From the repository root, install dependencies across the monorepo:

```powershell
pnpm install
```

This step automatically:
- Resolves workspace dependencies.
- Compiles `@hoppscotch/kernel`, `@hoppscotch/data`, and `@hoppscotch/js-sandbox`.
- Generates the Prisma client inside `packages/hoppscotch-backend/src/generated/prisma`.
- Bootstraps NestJS in schema generation mode to emit `gql-gen/backend-schema.gql`.
- Runs GraphQL codegen for `@hoppscotch/common`, `@hoppscotch/selfhost-web`, and `@hoppscotch/sh-admin`.

---

### Step 5: Run Database Migrations

Apply the Prisma database migrations:

```powershell
pnpm --filter hoppscotch-backend exec prisma migrate deploy
```

*Expected output: All 22 migrations applied successfully.*

---

### Step 6: Start the Backend Service

Start the NestJS backend in development/watch mode:

```powershell
pnpm --filter hoppscotch-backend start:dev
```

*(Or to run the compiled build directly: `node packages/hoppscotch-backend/dist/src/main.js`)*

> [!NOTE]
> On initial startup, the backend populates missing entries in the `infra_config` database table. If any SSO provider is unconfigured, it automatically cleans them up in the DB and performs a one-time graceful restart. Simply restart the backend command and it will stay running.

Verify the backend:
- Ping check: `Invoke-RestMethod -Uri "http://localhost:3170/ping"` (Returns `Success`)
- Health check: `Invoke-RestMethod -Uri "http://localhost:3170/health"`
- GraphQL API: `http://localhost:3170/graphql`

---

### Step 7: Start the Web App Frontend

In another terminal window:

```powershell
pnpm --filter @hoppscotch/selfhost-web dev
```

Navigate to:
👉 **[http://localhost:3000](http://localhost:3000)**

---

### Step 8: (Optional) Start the Admin Dashboard

In another terminal window:

```powershell
pnpm --filter hoppscotch-sh-admin dev -- --port 3100
```

Navigate to:
👉 **[http://localhost:3100](http://localhost:3100)**

---

## 4. Port Summary

| Service | Port | Local URL |
| :--- | :--- | :--- |
| **Web Frontend** | `3000` | [http://localhost:3000](http://localhost:3000) |
| **Admin Dashboard** | `3100` | [http://localhost:3100](http://localhost:3100) |
| **Backend REST & GraphQL** | `3170` | [http://localhost:3170](http://localhost:3170) |
| **PostgreSQL Database** | `5433` | `localhost:5433` (`hoppscotch` database) |

---

## 5. Daily Startup Command

To launch the full stack with a single script:

```powershell
pwsh ./docs/start-dev.ps1
```
