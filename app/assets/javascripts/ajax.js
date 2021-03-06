// Copyright © Mapotempo, 2013-2014
//
// This file is part of Mapotempo.
//
// Mapotempo is free software. You can redistribute it and/or
// modify since you respect the terms of the GNU Affero General
// Public License as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// Mapotempo is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Mapotempo. If not, see:
// <http://www.gnu.org/licenses/agpl.html>
//
var ajaxWaitingGlobal = 0;

function beforeSendWaiting() {
  if (ajaxWaitingGlobal == 0) {
    $('body').addClass('ajax_waiting');
  }
  ajaxWaitingGlobal++;
}

function completeWaiting() {
  ajaxWaitingGlobal--;
  if (ajaxWaitingGlobal == 0) {
    $('body').removeClass('ajax_waiting');
  }
}

function ajaxError(request, status, error) {
  var otext = request.responseText;
  var text;
  try {
    text = "";
    $.each($.parseJSON(otext), function(i, e) {
      text += e;
    });
  } catch (e) {
    text = otext;
  }
  if (!text) {
    text = status;
  }
  $(".main .flash").prepend(
    '<div class="alert fade in alert-danger">' +
    '<button class="close" data-dismiss="alert">×</button>' +
    $('<div/>').text(text).html() +
    '</div>');
}

function mustache_i18n() {
  return function(text) {
    return I18n.t(text);
  };
}

function progress_dialog(data, dialog, callback, load_url) {
  if (data !== undefined) {
    var timeout;
    dialog.dialog("open");
    var progress = data.progress && data.progress.split(';');
    $(".progress-bar", dialog).each(function(i, e) {
      if (progress == undefined || progress == '' || progress[i] == undefined || progress[i] == '') {
        $(e).parent().parent().hide();
      } else {
        $(e).parent().parent().show();
      }

      if (!progress || !progress[i]) {
        $(e).parent().removeClass("active");
        $(e).css("transition", "linear 0s");
        $(e).css("width", "0%");
      } else if (progress[i] == 100) {
        $(e).parent().removeClass("active");
        $(e).css("transition", "linear 0s");
        $(e).css("width", "100%");
      } else if (progress[i] == -1) {
        $(e).parent().addClass("active");
        $(e).css("transition", "linear 0s");
        $(e).css("width", "100%");
      } else if (progress[i].indexOf('ms') > -1) {
        var v = progress[i].split('ms');
        var iteration = $(e).data('iteration');
        if (iteration != v[1]) {
          $(e).data('iteration', iteration);
          $(e).css("transition", "linear 0s");
          $(e).css("width", "0%");
        }
        if (parseInt($(e).css("width")) == 0) {
          timeout = parseInt(v[0]);
          $(e).parent().removeClass("active");
          $(e).css("transition", "linear " + (timeout / 1000) + "s");
          $(e).css("width", "100%");
        }
      } else if (progress[i].indexOf('/') > -1) {
        var v = progress[i].split('/');
        $(e).parent().removeClass("active");
        $(e).css("transition", "linear 0.5s");
        $(e).css("width", "" + (100 * v[0] / v[1]) + "%");
        $(e).html(progress[i]);
      } else {
        $(e).parent().removeClass("active");
        $(e).css("transition", "linear 2s");
        $(e).css("width", "" + progress[i] + "%");
      }
    });
    if (data.attempts) {
      $(".dialog-attempts-number", dialog).html(data.attempts);
      $(".dialog-attempts", dialog).show();
    } else {
      $(".dialog-attempts", dialog).hide();
    }
    if (data.error) {
      $(".dialog-progress", dialog).hide();
      $(".dialog-error", dialog).show();
      var buttons = {};
      buttons[I18n.t('web.dialog.close')] = function() {
        $.ajax({
          type: "delete",
          url: "/api/0.1/customers/" + data.customer_id + "/job/" + data.id + ".json",
          beforeSend: beforeSendWaiting,
          complete: function() {
            dialog.dialog("close");
            completeWaiting();
            $.ajax({
              url: load_url,
              success: callback,
              error: ajaxError
            });
            // Reset dialog content
            $(".dialog-progress", dialog).show();
            $(".dialog-attempts", dialog).hide();
            $(".dialog-error", dialog).hide();
            $(".progress-bar", dialog).css("width", "0%");
            dialog.dialog({
              buttons: {}
            });
          },
          error: function(request, status, error) {
            ajaxError(request, status, error);
          }
        });
      };
      dialog.dialog({
        buttons: buttons
      });
    } else {
      setTimeout(function() {
        $.ajax({
          url: load_url,
          success: callback,
          error: ajaxError
        });
      }, 2000 + (timeout || 0));
    }
    return false;
  } else {
    dialog.dialog("close");
    $($(".progress-bar", dialog)).css("width", "0%");
    return true;
  }
}


function fake_select2(selector, callback) {
  function fake_select2_replace(fake_select) {
    var select = fake_select.prev();
    fake_select.hide();
    select.show();
    callback(select);
    fake_select.off();
  }

  function fake_select2_click(e) {
    // On the first click on select2-look like div, initialize select2, remove the placeholder and resend the click
    var fake_select = $(this);
    e.stopPropagation();
    fake_select2_replace(fake_select);
    if (e.clientX && e.clientY) {
      $(document.elementFromPoint(e.clientX, e.clientY)).click();
    }
  }

  function fake_select2_key_event(e) {
    var fake_select = $(this).closest('.fake');
    e.stopPropagation();
    var parent = $(this).parent();
    fake_select2_replace(fake_select);
    var input = $('input', parent);
    input.focus();
    // var ee = jQuery.Event('keydown');
    // ee.which = e.which;
    // $('input', $(this)).trigger(ee);
  }

  selector.next()
    .on('click', fake_select2_click)
    .on('keydown', fake_select2_key_event);
}
