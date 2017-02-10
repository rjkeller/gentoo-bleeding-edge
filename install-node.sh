emerge net-libs/nodejs
emerge www-servers/nginx

systemctl enable nginx

npm install -g pm2