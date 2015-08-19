// = require jquery/dist/jquery.min.js
// = require bootstrap-sass/assets/javascripts/bootstrap.min.js

$(function() {
  if (window.location.pathname.match(/staging_/))
    player_list();
  else if(window.location.pathname.match(/round/))
    round();
});

function round() {
  $("div.info div.panel-body")
    .scrollTop($("div.info div.panel-body > div").height());
  var uri = "ws://" + location.host + "/round/status";
  var socket = null;

  if (socket == null) {
    socket = new WebSocket(uri);
    socket.onmessage = function(event) {
      if (event && event.data) {
        var data_in = $.parseJSON(event.data);
        if (data_in.action == "pl_in_staging") {
          $(".player-list").html(data_in.player_list);
        } else if (data_in.action == "in_round") {
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
        } else if (data_in.action == 'round_result') {
          if (data_in.phase) {
            $("h1.phase").fadeOut(50, function() {
              $(this).text(data_in.phase);
              $(this).fadeIn(50);
            });
          }
          if (data_in.players) {
            $("div.player-list").fadeOut(50, function() {
              $(this).html(data_in.players);
              $(this).fadeIn(50);
            });
          }
          if (data_in.controls) {
            $("div.controls").fadeOut(50, function() {
              $(this).html(data_in.controls);
              $(this).fadeIn(50);
              add_action_event_listeners(socket);
            });
          }
        } else if (data_in.action == 'chat') {
          if (data_in.msg) {
            $("div.chat-display > div").append(data_in.msg);
            $("div.chat-display")
              .scrollTop($("div.chat-display > div").height());
          }
        } else if (data_in.action == 'quad_state_score') {
          $("a.quad-state[data-target='" + data_in.player + "']").children("span.badge").text(data_in.score);

          var s_hash = data_in.specifics
          var s_list = $("a.quad-state[data-target='" + data_in.player + "']").find("ul");
          s_list.empty();
          for (var index in s_hash) {
            if (s_hash.hasOwnProperty(index) && s_hash[index] != 0) {
              s_list.append("<li>" + index +": " + s_hash[index] + "</li>");
            }
          }
        } else if (data_in.action == 'chat') {
          alert(data_in.msg);
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
    data_out.targets = new Array;

    $("a.single-select").each(function(index, element) {
      if ($(element).attr("data-selected") == "true")
        data_out.targets.push($(element).attr("data-target"));
    });

    $("a.quad-state").each(function(index, element) {
      target = $(element).attr('data-target');
      score = parseInt($(element).attr('data-score'));
      for (i = 0; i < score; i++)
        data_out.targets.push(target);
    });

    var is_data_correct = true;
    if (data_out.targets.length == 0) {
      data_out.targets.push('');
      is_data_correct = false;
    }

    socket.send("" + JSON.stringify(data_out));
    if (is_data_correct) {
      $("a.single-select").off('click');
      $("a.quad-state").off('click');
    }
  });

  $("button.extend").click(function() {
    var data_out = {
      command: "extend"
    };
    socket.send("" + JSON.stringify(data_out));
  });

  $("button.skip").click(function() {
    var data_out = {
      command: "skip"
    };
    socket.send("" + JSON.stringify(data_out));
  });
  $("button.chat[type=submit]").click(function(e) {
    e.preventDefault();
    var data_out = {
      command: "chat"
    }
    $form = $("div.chat").find("form");
    data_out['msg'] = $form.find("[name=chat_msg]").val();
    data_out['room_name'] = $form.find("[name=chat_room]").val();
    socket.send("" + JSON.stringify(data_out));
    data_out['msg'] = $form.find("[name=chat_msg]").val('');
  });
}

function add_player_event_listeners(socket) {
  $("a.single-select").click(function(e) {
    e.preventDefault();
    $(this).parent().children("a").removeClass("list-group-item-info");
    $(this).parent().children("a").attr("data-selected", "false")
    $(this).addClass("list-group-item-info");
    $(this).attr("data-selected", "true")
  });

  $("a.quad-state").click(function(e) {
    e.preventDefault();
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

  $("a.quad-state > span.badge").click(function(e) {
    e.stopPropagation();
    $(this).parent().children(".specifics").collapse('toggle');
  });
}
