###
 * Federated Wiki : Persona Security Plugin
 *
 * Licensed under the MIT license.
 * https://github.com/fedwiki/wiki-security-persona/blob/master/LICENSE.txt
###

###
1. Display login button - if there is no authenticated user
2. Display logout button - if the user is authenticated

3. When user authenticated, claim site if unclaimed - and repaint footer.

###

update_footer = (owner, authUser) ->
  # we update the state of both the owner, and login/out in the footer

  $('#site-owner').replaceWith "<span id='site-owner' style='text-transform:capitalize;'>#{owner}</span>"

  $('#security > a').remove()

  if authUser is true
    $('#security').append "<a href='#' class='persona-button' id='persona-logout-btn'><span>Sign Out</span></a>"
    $('#persona-logout-btn').click (e) ->
      e.preventDefault()
      navigator.id.logout {}
  else
    $('#security').append "<a href='#' class='persona-button' id='persona-login-btn'><span>Sign in with your Email</span></a>"
    $('#persona-login-btn').click (e) ->
      e.preventDefault()
      navigator.id.request {}


failureDlg = (message) ->
  $("<div></div>").dialog({
    # Remove the closing 'X' from the dialog
    open: (event, ui) -> $(".ui-dialog-titlebar-close").hide()
    buttons: {
      "Ok": ->
        $(this).dialog("close")
        navigator.id.logout()
    }
    close: (event, ui) -> $(this).remove()
    resizable:  false
    title: "Login Failure"
    modal: true
  }).html(message)



setup = (user) ->

  if (!$("link[href='/security/persona-buttons.css']").length)
    $('<link rel="stylesheet" href="/security/persona-buttons.css">').appendTo("head")

  wiki.getScript "https://login.persona.org/include.js", () ->
    navigator.id.watch
      loggedInUser: user
      onlogin: (assertion) ->
        $.post "/login",
          assertion: assertion
        , (verified) ->
          verified = JSON.parse(verified)
          if "okay" is verified.status
            # logged in user is either the owner, or site has not been claimed
            authUser = true
            update_footer owner, authUser
          else if "wrong-address" is verified.status
            # logged in user is not the owner
            authUser = true
            update_footer owner, authUser
          else if "failure" is verified.status
            if /domain mismatch/.test(verified.reason)
              # The site is being accessed using a different protocol/address than that used as
              # the audience in the call to the verification service...
              failureMsg = "<p>It looks as if you are accessing the site using an alternative address.</p>" + \
              "<p>Please check that you are using the correct address to access this site.</p>"
            else
              # Verification failed for some other reason
              failureMsg = "<p>Unable to log you in.</p>"
            failureDlg failureMsg
          else
            # something else has happened - be safe and log the user out...
            navigator.id.logout()

      onlogout: ->
        $.post "/logout", () ->
          authUser = false
          user = ''
          update_footer owner, authUser

      onready: ->
        # It's safe to render, Persona and the wiki's notion of a session agree

        update_footer owner, authUser



window.plugins.security = {setup}
