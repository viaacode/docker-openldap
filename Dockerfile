FROM debian:stretch-slim
MAINTAINER Herwig Bogaert 

ARG SlapdUserId=1001
ENV SlapdUserId $SlapdUserId
ARG LdapPort=8389
ENV LdapPort $LdapPort
# use unpriviliged port!
EXPOSE $LdapPort

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  db-util ldap-utils slapd procps \
  && rm -rf /var/lib/apt/lists/* 

# Remove the auto configured ldap backend
RUN find /etc/ldap/slapd.d/ -type f -exec grep -qi '^olcDbDirectory:.*/var/lib/ldap' {} \; -exec rm {} \; \
  && rm -f /var/lib/ldap/*

VOLUME /var/lib/ldap

COPY docker-entrypoint.sh /usr/local/bin/
COPY configure_ldap_access.sh /usr/local/bin/
COPY backend.ldif /

# Arange access so that the containr can run non-privileged
# Enable passwordless access via shared memory for SlapdUserId
RUN /usr/local/bin/configure_ldap_access.sh

# Run as a non-privileged container
RUN chown -R $SlapdUserId /etc/ldap
RUN chown -R $SlapdUserId /var/run/slapd
USER 1001

ENTRYPOINT ["docker-entrypoint.sh"]
