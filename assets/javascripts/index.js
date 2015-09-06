// = require jquery/dist/jquery.min.js
// = require bootstrap-sass/assets/javascripts/bootstrap.min.js

$(function() {
  index();
});

function index() {
  $.ajax({
    url: "/game/round/list",
    success: function(data) {
      $("div.rounds").html(data);
      $(document).on('click', "a.round", function(event) {
        event.preventDefault();
        var $clicked = $(event.target);
        $clicked.parent().children("a.round").removeClass("list-group-item-info");
        $clicked.addClass("list-group-item-info");
        $form = $("form[data-existing=true]");
        $form.find("[name=round]").val($clicked.attr('data-round'));
      });
    }
  });
  $("button[type='submit']").click(function(e) {
    e.preventDefault();
    var $form = $("form[data-existing=" + $(this).attr("data-existing") + "]");

    if ($form.find("[name=username]").val() && $form.find("[name=round]").val()) {
      $form.submit();
    } else {
      if (!$form.find("[name=username]").val())
        $form.find("[name=username][type=text]").parent().addClass("has-error");
      if (!$form.find("[name=round]").val())
        $form.find("div.round-list-header").addClass("list-group-item-danger");
        $form.find("[name=round][type=text]").parent().addClass("has-error");
    }
  });

  var round_polling = setInterval(function() {
    $.ajax({
      url: "/game/round/list",
      success: function(data) {
        var selected = ''
        $("a.round").each(function(index, element) {
          if ($(element).hasClass("list-group-item-info"))
              selected = $(element).attr('data-round');
        });
        $("div.rounds").html(data);
        if (selected != '')
          $("a.round[data-round=" + selected + "]").addClass("list-group-item-info");
      }
    });
  }, 15000);
}
