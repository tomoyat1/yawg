// = require jquery/dist/jquery.min.js

$(function() {
  if (window.location.pathname.match(/staging_/)) {
    player_list();
  }
});

function player_list() {
  var uri = "ws://" + location.host + "/players/list";
  var socket = null;
  if (socket == null) {
    socket = new WebSocket(uri);
    socket.onmessage = function() {
      if (event && event.data) {
        $(".player-list").html(event.data);
      }
    }
  }
}
