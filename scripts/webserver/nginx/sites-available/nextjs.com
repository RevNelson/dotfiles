server {
    server_name nextjs.com;

    access_log /sites/frontend/nextjs.com/logs/access.log;
    error_log /sites/frontend/nextjs.com/logs/error.log;

    index index.html index.htm;
    root /sites/frontend/nextjs.com/files/public/;

    # Serve any static assets with NGINX
    location /_next/static {
        alias /sites/frontend/nextjs.com/files/.next/static;
        add_header Cache-Control "public, max-age=3600, immutable";
    }

    location / {
        try_files $uri.html $uri/index.html # only serve html files from this dir
        @public
        @nextjs;
        add_header Cache-Control "public, max-age=3600";
    }

    location @public {
        add_header Cache-Control "public, max-age=3600";
    }

    location @nextjs {
        # reverse proxy for next server
        proxy_pass http://localhost:3000; #Don't forget to update your port number
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    listen 80; # run Certbot for SSL and redirect
    listen [::]:80;

}
