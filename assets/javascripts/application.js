// = require jquery/dist/jquery.min.js

$(function() {
  if (window.location.pathname.match(/staging_/))
    player_list();
  else if(window.location.pathname.match(/game/))
    player_list();
  //Match root if nothing else matches
  else 
    participation();
});

function participation() {
  $("button.staging-new").click(function(e) {
      e.preventDefault();
      if ($("form.staging-new [name=username]").val() && $("form.staging-new [name=game]").val()) {
        $("form.staging-new").submit();
      } else {
        if (!$("form.staging-new [name=username]").val())
          $("form.staging-new [name=username]").parent().addClass("has-error");
        if (!$("form.staging-new [name=game]").val())
          $("form.staging-new [name=game]").parent().addClass("has-error");
      }
    });
  $("button.staging-existing").click(function(e) {
      e.preventDefault();
      if ($("form.staging-existing [name=username]").val() && $("form.staging-existing [name=game]").val()) {
        $("form.staging-existing").submit();
      } else {
        if (!$("form.staging-existing [name=username]").val())
          $("form.staging-existing [name=username]").parent().addClass("has-error");
        if (!$("form.staging-existing [name=game]").val())
          $("form.staging-existing [name=game]").parent().addClass("has-error");
      }
    });
}

function player_list() {
  var uri = "ws://" + location.host + "/players/list";
  var pl_socket = null;

  if (pl_socket == null) {
    pl_socket = new WebSocket(uri);
    pl_socket.onmessage = function() {
      if (event && event.data) {
        $(".player-list").html(event.data);
      }
    }
  }
}
