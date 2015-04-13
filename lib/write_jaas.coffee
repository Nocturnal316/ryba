
###
Options include
*   ssh
*   mode
*   content
*   kerberos [boolean]

A server configuration is expected to define a keytab. Add the principal
name if the keytab store multiple tickets. A client configuration for an
application will be similar and also defines a keytab. A client configuration
for a login user will usually get the ticket from the user ticket cache created
with a `kinit` command.

Example:

```
write_jaas
  server:
    keyTab: '/path/to/keytab'
    principal: 'service/host@REALM'
  client:
    useTicketCache: 'true'
, (err, modified) ->
  console.log err
```

###

module.exports = (ctx) ->
  ctx.write_jaas = (options, callback) ->
    # Quick fix
    # waiting for context registration of mecano actions as well as
    # waiting for uid_gid moved from wrap to their expected location
    options.ssh ?= ctx.ssh
    options.mode ?= 0o600
    options.backup ?= true
    wrap null, arguments, (options, callback) ->
      content_jaas = ""
      return callback Error "Required option 'content'" unless options.content
      for type, properties of options.content
        type = "#{type.charAt(0).toUpperCase()}#{type.slice 1}"
        throw Error 'Invalid property type' unless type in ['Client', 'Server']
        content_jaas += "#{type} {\n"
        # Validation and Normalization
        throw Error 'Invalid keytab option' if properties.keyTab and typeof properties.keyTab isnt 'string'
        properties.useTicketCache = 'true' if properties.useTicketCache
        if properties.keyTab
          properties.useKeyTab ?= 'true'
          properties.storeKey ?= 'true'
          properties.useTicketCache ?= 'false'
        else
          properties.useKeyTab ?= 'false'
          properties.useTicketCache ?= 'true'
        if typeof value isnt 'string'
          if typeof value is 'number'
            value = "#{value}"
          else
            value = if value then 'true' else 'false'
        # Detect JAAS/Kerberos
        if properties.keyTab or properties.useTicketCache is 'true'
          content_jaas += '  com.sun.security.auth.module.Krb5LoginModule required\n'
          for property, value of properties
            value = "\"#{value}\"" unless value in ['true', 'false']
            content_jaas += "  #{property}=#{value}\n"
          content_jaas = content_jaas.slice(0, -1) + ';\n'
        content_jaas += '};\n'
      options.content = content_jaas
      ctx.write options, callback

wrap = require 'mecano/lib/misc/wrap'
