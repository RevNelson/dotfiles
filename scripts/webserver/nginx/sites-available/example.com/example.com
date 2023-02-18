fastcgi_cache_path /cache/example.com levels=1:2 keys_zone=example.com:100m inactive=1d;
include sites-available/example.com/before/*;

server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	server_name example.com;

	ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

	root /sites/example.com/files/public/;

	index index.html index.php;

	access_log /sites/example.com/logs/access.log;
	error_log /sites/example.com/logs/error.log;

	# Don't allow pages to be rendered in an iframe on external domains.
	add_header X-Frame-Options "SAMEORIGIN";

	# MIME sniffing prevention
	add_header X-Content-Type-Options "nosniff";

	# Enable cross-site scripting filter in supported browsers.
	add_header X-Xss-Protection "1; mode=block";

	include sites-available/example.com/server/*;

	# Prevent access to hidden files
	location ~* /\.(?!well-known\/) {
		deny all;
	}

	# Prevent access to certain file extensions
	location ~\.(ini|log|conf|blade.php)$ {
		deny all;
	}

	location / {
		try_files $uri $uri/ /index.php?$args;
	}

	location ~ \.php$ {
		try_files $uri =404;

		include fastcgi.conf;
		fastcgi_pass unix:/run/php/php8.1-ronatec-apidev.sock;

		include sites-available/example.com/location/*;
	}
}

include sites-available/example.com/after/*;
