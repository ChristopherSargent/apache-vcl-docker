FROM mysql:5.6
LABEL maintainer="Christopher Sargent christopher.sargent@sargentwalker.com>"
# Copy VCL Initialization Data
COPY /home/cas/vcl/vcl.sql /docker-entrypoint-initdb.d/
