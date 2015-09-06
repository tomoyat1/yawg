// = require jquery/dist/jquery.min.js
// = require bootstrap-sass/assets/javascripts/bootstrap.min.js

var action_done = false;
var error = false;
var reconnect_fails = 0;

$(function() {
  if (window.location.pathname.match(/staging_/))
    player_list();
  else if(window.location.pathname.match(/game\/round/))
    round();
});

function round() {
  reconnect_fails = 0;

  $("div.info div.panel-body")
    .scrollTop($("div.info div.panel-body > div").height());
  var uri = "ws://" + location.host + "/game/round/status";
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
            action_done = false;
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
      if (!error) {
        error = true;
        alert("エラーが発生しました。ゲーム画面を再読み込みします。");
      }
      error = false;
      window.location = "/game/round";
    }
    socket.onclose = function() {
      reconnect_fails++;
      setTimeout(function() {
        round();
      }, (2 ^ reconnect_fails) * 1000);
    }
  }
  add_staging_event_listeners(socket);
  add_action_event_listeners(socket);
  add_player_event_listeners(socket);
}

function add_staging_event_listeners(socket) {
  $(document).on('click', 'button.start', function() {
    var data_out = {
      command: "start"
    };
    data_out['first_kill'] = $("a.first-kill").data("bool");
    data_out['one_night'] = $("a.one-night").data("bool");
    data_out.role_rand = new Object;
    data_out.role_min = new Object;
    var fail = false;
    $("input.role-max").each(function () {
      $role_input = $(this).parents().eq(2);
      $cor_min = $role_input.find("input.role-min");
      if (parseInt($(this).val(), 10) < parseInt($cor_min.val(), 10)) {
        $role_input.children().addClass("has-error");
        fail = true;
        return true;
      } else {
        data_out.role_rand[$(this).attr("name")]
           = parseInt($(this).val(), 10) - parseInt($cor_min.val(), 10);
      }
    });
    $("input.role-min").each(function() {
      data_out.role_min[$(this).attr("name")] = parseInt($(this).val(), 10);
    });
    if (!fail) {
      socket.send("" + JSON.stringify(data_out));
    } else {
      $("div.info div.panel-body > div").append("<div>最大が最小の数以上にになるように役職の数を指定してください。</div>");
      $("div.info div.panel-body")
        .scrollTop($("div.info div.panel-body > div").height());
    }
  });
  $(document).on('click', "a.toggle", function(event) {
    event.preventDefault();
    if($(event.target).data("bool")) {
      $(event.target).data("bool", false);
      $(event.target).removeClass("list-group-item-info");
      $(event.target).children("span").text("Off");
    } else {
      $(event.target).data("bool", true);
      $(event.target).addClass("list-group-item-info");
      $(event.target).children("span").text("On");
    }
  });
}

function add_action_event_listeners(socket) {
  $(document).on('click', "button.action-name", function() {
    if (!action_done) {
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
        action_done = true;
      }
    }
  });

  $(document).on('click', "button.extend", function() {
    var data_out = {
      command: "extend"
    };
    socket.send("" + JSON.stringify(data_out));
  });

  $(document).on('click', "button.skip", function() {
    var data_out = {
      command: "skip"
    };
    socket.send("" + JSON.stringify(data_out));
  });
  $(document).on('click', "button.chat[type=submit]", function(e) {
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
  $(document).on('click', "a.single-select", function(event) {
    event.preventDefault();
    if (!action_done) {
      $(event.target).parent().children("a").removeClass("list-group-item-info");
      $(event.target).parent().children("a").attr("data-selected", "false")
      $(event.target).addClass("list-group-item-info");
      $(event.target).attr("data-selected", "true")
    }
  });

  $(document).on('click', "a.quad-state", function(event) {
    event.preventDefault();
    if (!action_done) {
      var clicked = $(event.target).closest("a.quad-state");
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
    }
  });

  $(document).on('click', "a.details", function(event) {
    event.preventDefault();
    var $target = $(event.target);
    $target.parent().find(".specifics").collapse('toggle');
    if ($target.hasClass("list-group-item-info")) {
      $target.removeClass("list-group-item-info");
    } else {
      $target.addClass("list-group-item-info");
    }
  });
}
