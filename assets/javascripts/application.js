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
  $("button[type='submit']").click(function(e) {
    e.preventDefault();
    var $form = $("form[data-existing=" + $(this).attr("data-existing") + "]");
    if ($form.find("[name=username]").val() && $form.find("[name=game]").val()) {
      $form.submit();
    } else {
      if (!$form.find("[name=username]").val())
        $form.find("[name=username]").parent().addClass("has-error");
      if (!$form.find("[name=game]").val())
        $form.find("[name=game]").parent().addClass("has-error");
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
