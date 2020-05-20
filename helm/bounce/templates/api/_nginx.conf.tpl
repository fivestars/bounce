{{/* Config file for nginx */}}

# Note: This define name is global, if loading multiple templates with the same name, the last
# one loaded will be used.
{{ define "nginx-config" -}}

# Specify some event configs
events {
    worker_connections 4096;
}

http {
    server {
        # Create a server that listens on the nginx port
        listen {{ .Values.api.nginx.port }};

        location = /.ambassador-internal/openapi-docs {
            access_log off;
            log_not_found off;
            return 404;
        }

        # Otherwise, nginx tries to serve static content. The only file that should exist is
        # index.html, which is written by the initContainer. Get requests with "/" or
        # "/index.html" will return a short message, everything else will return 404.
        location = / {
            root /usr/share/nginx/html;
            index index.html;
        }

        # Match incoming request uri with these prefixes and route them to the api uvicorn app
        location / {
            proxy_set_header Host $http_host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_redirect off;
            proxy_buffering off;
            proxy_pass http://api;
        }

    }

    # The univorn upstream definition
    upstream api {
        server 127.0.0.1:{{ .Values.api.uvicorn.port }};
    }
}

{{ end }}
