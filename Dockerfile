FROM nginx:alpine
COPY index.html main.js style.css /usr/share/nginx/html/
COPY AppData /usr/share/nginx/html/AppData
EXPOSE 80
