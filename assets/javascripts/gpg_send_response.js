var checkedGPGKeys = new Object();

function showGPGHints() {
  var enabled = isGPGEncryptionEnabled();
  $([$('#helpdesk_to'), $('#helpdesk_cc'), $('#helpdesk_bcc')]).each(function(index, cc_list) {
    showTagsGPGHint(cc_list, enabled);
  });
}

function showTagsGPGHint(cc_list, enabled) {
  // check existing 'tagged' adresses
  $(cc_list).next().find("li").each(function(index, li_item) {
    if (enabled && $(li_item).hasClass('select2-selection__choice')) {
      var mailadr = $(li_item).attr('title').match(/([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/g);
      checkGPGKeyFor(mailadr, $(li_item));
    } else {
      $(li_item).removeClass('recipient-check-key recipient-has-key recipient-has-no-key');
    }
  });
}

function checkGPGKeyFor(adr, element) {
  element.addClass('recipient-check-key');
  function setHint(data) {
    // Sets css style of an element according to result of (previous) check.
    element.removeClass('recipient-check-key');
    element.addClass(('true' == data) ? 'recipient-has-key' : 'recipient-has-no-key');
  };
  var previousResult = checkedGPGKeys[adr];
  if (previousResult === undefined) {
    // ajax call for checking availability of a key.
    $.get( '../gpgkeys/query?id=' + adr,
        function(data) {
          checkedGPGKeys[adr] = data;
          setHint(data);
        });
  } else {
    setHint(previousResult);
  }
}

function isGPGEncryptionEnabled() {
  var _checkbox = $('#helpdesk_gpg_do_encrypt').get(0);
  return _checkbox != null && _checkbox.checked;
}

function setupCheckForTags() {
  // hook onto the select2 items and add handler for adding/removing items
  $([$('#helpdesk_to'), $('#helpdesk_cc'), $('#helpdesk_bcc')]).each(function() {
    $(this).on('select2:select', function () {
      showTagsGPGHint($(this), isGPGEncryptionEnabled());
    });
    $(this).on('select2:unselect', function () {
      var _cc_list = $(this);
      setTimeout(function () {
        showTagsGPGHint(_cc_list, isGPGEncryptionEnabled());
      }, 500);
    });
  });
}

$(function() {
  // stuff from the helpdesk plugin we rely on
  sendMailCheckbox = $('#helpdesk_is_send_mail');
  ccFields = $('#cc_fields');
  recipientEmail = $('#customer_to_email');

  // add click handler for checking keys when encryption is enabled
  $('#helpdesk_gpg_do_encrypt').on('change', showGPGHints);

  // add handler(s) for new mail adresses which are edited inline
  setupCheckForTags();

  gpgOptions = $('#helpdesk_send_response_gpg');

  function showGpgOptions() {
    gpgOptions.show();
    // Also show all mail recipients to avoid surprises with hidden CC adresses that could be security incidents.
    ccFields.show();
    recipientEmail.hide();
    recipientEmail.next().hide();
  }

  function hideGpgOptions() {
    gpgOptions.hide();
  }

  function toggleGpgOptions() {
    if (this.checked) {
      showGpgOptions();
    } else {
      hideGpgOptions();
    }
  }
  sendMailCheckbox.on('change', toggleGpgOptions);

  gpgOptions.hide();

  // Clicking on the reply button activates the mail checkbox, but does not trigger a change event.
  // We have to bind to the click event ourselves and show the GPG options.
  $('.icon-helpdesk-reply').on('click', function() { 
    showGpgOptions();
  });
});
