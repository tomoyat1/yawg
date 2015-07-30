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
  $("div.info div.panel-body")
    .scrollTop($("div.info div.panel-body > div").height());
  var uri = "ws://" + location.host + "/game/status";
  var socket = null;

  if (socket == null) {
    socket = new WebSocket(uri);
    socket.onmessage = function(event) {
      if (event && event.data) {
        var data_in = $.parseJSON(event.data);
        if (data_in.action == "pl_in_staging") {
          $(".player-list").html(data_in.player_list);
        } else if (data_in.action == "in_game") {
          if (data_in.phase) {
            $("h1.phase").fadeOut(50, function() {
              $(this).text(data_in.phase);
              $(this).fadeIn(50);
            });
          }
          if (data_in.info) {
            $("div.info div.panel-body > div").append(data_in.info);
            $("div.info div.panel-body")
              .scrollTop($("div.info div.panel-body > div").height());
          }
          if (data_in.controls) {
            $("div.controls").fadeOut(50, function() {
              $(this).html(data_in.controls);
              $(this).fadeIn(50);
            });
          }
          if (data_in.players) {
            $("div.player-list").fadeOut(50, function() {
              $(this).html(data_in.players);
              $(this).fadeIn(50);
            });
          }
        }
      }
    }
    socket.onerror = function() {
      alert("error");
    }
  }

  $("button.start").click(function() {
    var data_out = {
      command: "start"
    };
    data_out.role_count = new Object;
    $("input.role-count").each(function () {
      data_out.role_count[$(this).attr("name")] = parseInt($(this).val(), 10);
    });
    socket.send("" + JSON.stringify(data_out));
  });
}
