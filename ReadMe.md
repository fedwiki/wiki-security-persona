# Federated Wiki - Security Plug-in: Persona

This security plug-in provides support for authentication using
[Mozilla Persona](https://developer.mozilla.org/en-US/Persona).

## Configuration

This plug-in is initial configured as the default security plug-in. But,
can be explicitly configured by adding `--security '{"type": "persona"}'`.

If you are not running wiki in farm mode behind a proxy you will also need
to specify the server host name, using the `host` parameter, so that the
correct audience is used.
