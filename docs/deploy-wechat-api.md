# Deploy the Backend API for WeChat Mini Program

This project needs a public HTTPS API domain before the WeChat Mini Program can work in production.

## 1. Prepare a server and domain

Use a Linux cloud server with Docker installed. Point a DNS A record to the server:

```text
api.yourdomain.com -> your_server_public_ip
```

Open inbound ports:

```text
80/tcp
443/tcp
```

If the server is in mainland China, complete ICP filing before using it for a WeChat Mini Program production backend.

## 2. Upload the project to the server

Copy the repository to the server, then enter the repository root:

```bash
cd /opt/gicu-tgq
```

## 3. Configure production environment

```bash
cp deploy/.env.prod.example deploy/.env.prod
```

Edit `deploy/.env.prod`:

```text
API_DOMAIN=api.yourdomain.com
POSTGRES_PASSWORD=replace_with_a_long_random_password
CORS_ORIGINS=https://api.yourdomain.com
```

## 4. Start the API

```bash
docker compose --env-file deploy/.env.prod -f deploy/docker-compose.prod.yml up -d --build
```

Caddy will automatically request and renew the HTTPS certificate.

## 5. Verify

Open:

```text
https://api.yourdomain.com/health
https://api.yourdomain.com/papers
```

`/health` should return:

```json
{"status":"ok"}
```

## 6. Configure WeChat request domain

In WeChat Official Platform:

```text
开发 -> 开发管理 -> 开发设置 -> 服务器域名 -> request 合法域名
```

Add:

```text
https://api.yourdomain.com
```

Do not include a path such as `/papers`.

## 7. Update Mini Program API domain

Edit `miniprogram/config.js`:

```js
const PROD_API_BASE_URL = 'https://api.yourdomain.com'
```

Then upload a new version with WeChat DevTools.
