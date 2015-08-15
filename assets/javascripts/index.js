// = require jquery/dist/jquery.min.js
// = require bootstrap-sass/assets/javascripts/bootstrap.min.js

$(function() {
  participation();
});

function participation() {
  $.ajax({
    url: "/round/list",
    success: function(data) {
      $("div.rounds").html(data);
      $("div.round").click(function() {
        var $clicked = $(this)
        $clicked.parent().children("div.round").removeClass("list-group-item-info");
        $clicked.addClass("list-group-item-info");
        $form = $("form[data-existing=true]");
        $form.find("[name=round]").val($clicked.text());
      });
    }
  });
  $("div.round").click(function() {
    $(this).parent().children("div.round").removeClass("list-group-item-info");
    $(this).addClass("list-group-item-info");
    $form = $("form[data-existing=true]");
    $form.find("[name=round]").val($(this).text());
  });
  $("button[type='submit']").click(function(e) {
    e.preventDefault();
    var $form = $("form[data-existing=" + $(this).attr("data-existing") + "]");

    if ($form.find("[name=username]").val() && $form.find("[name=round]").val()) {
      $form.submit();
    } else {
      if (!$form.find("[name=username]").val())
        $form.find("[name=username]").parent().addClass("has-error");
      if (!$form.find("[name=round]").val())
        $form.find("div.round-list-header").addClass("list-group-item-danger");
        $form.find("[name=round]").parent().addClass("has-error");
    }
  });

  var round_polling = setInterval(function() {
    $.ajax({
      url: "/round/list",
      success: function(data) {
        var selected = ''
        $("div.round").each(function(index, element) {
          if ($(element).hasClass("list-group-item-info"))
              selected = $(element).attr('data-round');
        });
        $("div.rounds").html(data);
        if (selected != '')
          $("div.round[data-round=" + selected + "]").addClass("list-group-item-info");
        $("div.round").click(function() {
          var $clicked = $(this)
          $clicked.parent().children("div.round").removeClass("list-group-item-info");
          $clicked.addClass("list-group-item-info");
          $form = $("form[data-existing=true]");
          console.log($clicked.attr('data-round'));
          $form.find("[name=round]").val($clicked.attr('data-round'));
        });
      }
    });
  }, 5000);
}
