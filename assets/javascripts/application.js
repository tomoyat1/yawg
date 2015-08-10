// = require jquery/dist/jquery.min.js
// = require bootstrap-sass/assets/javascripts/bootstrap.min.js

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
              add_action_event_listeners(socket);
            });
          }
          if (data_in.players) {
            $("div.player-list").fadeOut(50, function() {
              $(this).html(data_in.players);
              $(this).fadeIn(50);

              add_player_event_listeners(socket);
            });
          }
        } else if (data_in.action == 'spirit') {
          if (data_in.phase) {
            $("h1.phase").fadeOut(50, function() {
              $(this).text(data_in.phase);
              $(this).fadeIn(50);
            });
          }
        } else if (data_in.action == 'quad_state_score') {
          $("li.quad-state[data-target='" + data_in.player + "']").children("span.badge").text(data_in.score);

          var s_hash = data_in.specifics
          var s_list = $("li.quad-state[data-target='" + data_in.player + "']").find("ul");
          s_list.empty();
          for (var index in s_hash) {
            if (s_hash.hasOwnProperty(index) && s_hash[index] != 0) {
              s_list.append("<li>" + index +": " + s_hash[index] + "</li>");
            }
          }
        }
      }
    }
    socket.onerror = function() {
      alert("error");
    }
  }

  add_staging_event_listeners(socket);
}

function add_staging_event_listeners(socket) {
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

function add_action_event_listeners(socket) {
  $("button.action-name").click(function() {
    var data_out = {
      command: 'confirm_action',
    }

    $("li.single-select").each(function(index, element) {
      if ($(element).attr("data-selected") == "true") {

        data_out.target = $(element).attr("data-target");
      }
    });
    socket.send("" + JSON.stringify(data_out));
  });
}

function add_player_event_listeners(socket) {
  $("li.single-select").click(function() {
    $(this).parent().children("li").removeClass("list-group-item-info");
    $(this).parent().children("li").attr("data-selected", "false")
    $(this).addClass("list-group-item-info");
    $(this).attr("data-selected", "true")
  });

  $("li.quad-state").click(function() {
    var clicked = $(this);
    target = clicked.attr('data-target');
    score = parseInt(clicked.attr('data-score'));
    if (score < 3) {
      clicked.attr('data-score', ++score);
    } else {
      score = 0
      clicked.attr('data-score', score);
    }

    switch (score) {
      case 0: 
        clicked.removeClass("list-group-item-danger");
        break;
      case 1:
        clicked.addClass("list-group-item-success");
        break;
      case 2:
        clicked.removeClass("list-group-item-success");
        clicked.addClass("list-group-item-warning");
        break;
      case 3: 
        clicked.removeClass("list-group-item-warning");
        clicked.addClass("list-group-item-danger");
        break;
    }

    var data_out = {
      command: 'quad_state_score',
      target: target,
      score: score
    };
    socket.send("" + JSON.stringify(data_out));
  });

  $("li.quad-state > span.badge").click(function(e) {
    e.stopPropagation();
    $(this).parent().children(".specifics").collapse('toggle');
  });
}
