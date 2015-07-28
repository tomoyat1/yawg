// = require jquery/dist/jquery.min.js

$(function() {
  if (window.location.pathname.match(/staging_/))
    player_list();
  else if(window.location.pathname.match(/game/))
    game();
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

function game() {
  var uri = "ws://" + location.host + "/game/status";
  var socket = null;

  if (socket == null) {
    socket = new WebSocket(uri);
    socket.onmessage = function(event) {
      if (event && event.data) {
        var data_in = $.parseJSON(event.data);
        if (data_in.player_list) {
          $(".player-list").html(data_in.player_list);
        } else if (data_in.phase) {
          alert(data_in.phase);
          $("h1.phase").text(data_in.phase);
        }
      }
    }
    socket.onerror = function() {
      alert("error");
    }
  }

  $("button.start").click(function() {
    var data_out = {command: "start"};
    socket.send("" + JSON.stringify(data_out));
  });
}
