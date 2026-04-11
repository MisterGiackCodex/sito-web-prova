# mistergiack-dev

Landing site for `mistergiack.dev`. Built image: `mistergiack-dev`, container: `mistergiack-dev`, internal port: 3010.

## Deploy
```bash
ssh root@144.91.90.41 "cd /var/www/mistergiack-dev && git pull && docker build -t mistergiack-dev . && docker stop mistergiack-dev 2>/dev/null; docker rm mistergiack-dev 2>/dev/null; docker run -d --name mistergiack-dev --restart unless-stopped -p 127.0.0.1:3010:80 mistergiack-dev"
```
