FROM debian:stretch-slim
MAINTAINER Herwig Bogaert

ARG LdapPort=8389
ENV LdapPort $LdapPort
# use unpriviliged port!
EXPOSE $LdapPort


# Install software and remove the auto configured ldap backend
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y slapd \
 db-util ldap-utils procps pwgen \
 && rm -rf /var/lib/apt/lists/* \
 && find /etc/ldap/slapd.d/ -type f -exec grep -qi \
 '^olcDbDirectory:.*/var/lib/ldap' {} \; -exec rm {} \; \
 && rm -f /var/lib/ldap/*

COPY docker-entrypoint.sh /usr/local/bin/
COPY configure_ldap_access.sh /usr/local/bin/
COPY backend.ldif /

# Arange access so that the containr can run non-privileged
# with an arbirary user id
# Enable passwordless IPC access to configuration for local users
# IPC access is not exposed and
# slapd only listens to IPC during the configuration phase at startup.
RUN /usr/local/bin/configure_ldap_access.sh \
 && for dir in /etc/ldap/slapd.d /var/run/slapd /var/lib/ldap; \
   do chgrp -R 0 $dir && chmod -R g+rw $dir; done

# Set default non-priviliged user
# Can be overidden during docker run
USER openldap

VOLUME /var/lib/ldap

ENTRYPOINT ["docker-entrypoint.sh"]
