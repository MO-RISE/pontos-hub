FROM ubuntu

EXPOSE 8080

ENV JWT_ISSUER=
ENV JWT_EXPIRY=
ENV JWT_SECRET=
ENV JWT_ALLOWED_CLAIMS=
ENV JWT_REQUIRED_CLAIMS=

# Install neccessary tools
RUN apt-get update && apt-get install -y \
    wget \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install shell2http
RUN wget -q -O - https://github.com/msoap/shell2http/releases/download/v1.16.0/shell2http_1.16.0_linux_amd64.tar.gz | tar xvz -C /usr/local/bin shell2http

# Install jwt-cli
RUN wget -q -O - https://github.com/mike-engel/jwt-cli/releases/download/5.0.3/jwt-linux.tar.gz | tar xvz -C /usr/local/bin jwt

ADD --chmod=a+x issue_jwt.sh issue_jwt.sh
CMD ["shell2http", "--cgi", "--show-errors", "--form", "--export-all-vars", "POST:/", "./issue_jwt.sh"]