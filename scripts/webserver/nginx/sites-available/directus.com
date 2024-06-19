server {
    server_name directus.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header REMOTE-HOST $remote_addr;
        add_header X-Cache $upstream_cache_status;

        proxy_connect_timeout 30s;
        proxy_read_timeout 86400s;
        proxy_send_timeout 30s;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    access_log  /sites/directus.com/logs/access.log;
    error_log  /sites/directus.com/logs/error.log;

    listen 80;
    listen [::]:80;
}