###
 * Federated Wiki : Security Plugin : Mozilla Persona
 *
 * Copyright Ward Cunningham and other contributors
 * Licensed under the MIT license.
 * https://github.com/fedwiki/wiki-node-server/blob/master/LICENSE.txt
###
# **Persona : security.coffee**
# Module for Persona (BrowserID) based security.
#
# This module is based on the previously built-in security.

#### Requires ####
fs = require 'fs'

https = require 'https'
qs = require 'qs'


# Export a function that generates security handler
# when called with options object.
module.exports = exports = (log, loga, argv) ->
  security={}

  #### Private utility methods. ####

  owner = ''

  # save the location of the status directory
  statusDir = argv.status

  # name of, now depreciated, persona identity file
  # - this file contains a single email address
  idFile = argv.id

  #### Public stuff ####

  # Attempt to figure out if the wiki is claimed or not,
  # if it is return the owner.

  # Retrieve owner infomation from identity file in status directory
  security.retrieveOwner = (cb) ->
    fs.exists idFile, (exists) ->
      if exists
        fs.readFile(idFile, (err, data) ->
          if err then return cb err
          owner += data
          cb())
      else
        owner = ''
        cb()

  security.getOwner = getOwner = ->
    if ~owner.indexOf '@'
      ownerName = owner.substr(0, owner.indexOf('@'))
    else
      ownerName = owner
    ownerName = ownerName.split('.').join(" ")
    ownerName

  security.setOwner = setOwner = (id, cb) ->
    owner = id
    fs.exists idFile, (exists) ->
      if !exists
        fs.writeFile(idFile, id, (err) ->
          if err then return cb err
          console.log "Claiming site for #{id}"
          owner = id
          cb())
      else
        cb()

  security.getUser = (req) ->
    if req.session.email
      return req.session.email
    else
      return ''

  security.isAuthorized = (req) ->
    if owner == req.session.email
      return true
    else
      return false


  security.login = (updateOwner) ->
    (req, res) ->
      sent = false
      fail = ->
        res.send "FAIL", 401 unless sent
        sent = true

      # this only caters for sites using http:
      if argv.url == ''
        incHost = 'http://' + req.headers.host
      else
        incHost = argv.url

      postBody = qs.stringify(
        assertion: req.body.assertion
        audience: incHost
      )

      opts =
        host: "verifier.login.persona.org"
        port: 443
        path: "/verify"
        method: "POST"
        rejectUnauthorized: true
        headers:
          "Content-Length": postBody.length
          "Content-Type": "application/x-www-form-urlencoded"

      d = ''
      originalRes = res

      verifier = https.request opts, (res) ->
        if 200 is res.statusCode
          res.setEncoding "utf8"
          res.on "data", (data) ->
            d += data

          res.on "end", (a, b, c) ->
            verified = JSON.parse(d)
            if "okay" is verified.status and !!verified.email
              req.session.email = verified.email
              console.log "Verified Email: ", verified.email
              if owner is ''
                setOwner verified.email, ->
                  updateOwner getOwner()
                  originalRes.send JSON.stringify {
                    status: 'okay',
                    email: verified.email,
                    owner: getOwner()
                  }
              else
                originalRes.send JSON.stringify {
                  status: 'okay',
                  email: verified.email,
                  owner: getOwner()
                }
            else
              # verify has failed, return statusCode for client to handle...
              console.log "ERROR: Verify Failed :: ", JSON.stringify(verified)
              originalRes.send JSON.stringify {
                status: 'failure',
                reason: verifier.reason
              }

        else
          console.log "STATUS: ", res.statusCode
          console.log "HEADERS: ", JSON.stringify(res.headers)
          fail()

      verifier.write postBody
      verifier.on "error", (e) ->
        console.log e
        fail()

      verifier.end()



  security.logout = () ->
    (req, res) ->
      console.log "Logout..."




  security
