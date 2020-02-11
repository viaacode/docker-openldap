# docker-openldap

A generic [openldap](https://openldap.org) container.


## Build Arguments

- `SlapdUserId`: (optional, default 1001) Uid of the user that runs the slapd proces. If an existing
    database is mounted in the container, the files must be accessible by this uid.
- `LdapPort`: (optional, default 8389) Port on which the slapd daemon listens. Must be unprivilged.
    

## How to use

```console
$ docker run -e LDAP_SUFFIX='dc=example,dc=org' -e LDAP_ROOT_ASSWORD=secret -d %%IMAGE%%
```

This creates an empty backend for the given suffix with the root DN set to
`cn=root,<suffix>`.  The container runs unpriviliged and exposes unpriviliged
port 8389.  A custom port can be specified during build using the build
argument `LdapPort`.

When `LDAP_SUFFIX` is not set or empty, no backend will be created.  This
allows to create a custom backend by dropping an ldif file in
/docker-entrypoint-init/ (see below).

## Customize or extend

For additional initialization, add one or more `.ldif`files under
/docker-entrypoint-init/.  They will be executed before starting the service.
([example](https://github.com/viaacode/docker-openldap-deewee.git))

If the ldif file contains a `changetype` attribute, it will be executed by
`ldapmodify`, otherwise it will be executed by `ldapadd`.

When the initialization is complete,  the container starts listening on the exposed port.


