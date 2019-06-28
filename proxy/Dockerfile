FROM nginx:alpine

RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.disabled

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]