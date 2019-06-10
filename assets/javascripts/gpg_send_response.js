function showGPGHints() {
  var enabled = isGPGEncryptionEnabled();
  $([$('#helpdesk_to'), $('#helpdesk_cc'), $('#helpdesk_bcc')]).each(function(index, select2) {
    showTagsGPGHint(select2, enabled);
  });
}

function showTagsGPGHint(select2, enabled) {
  // check existing 'tagged' adresses
  if (enabled) {
    $(select2).find(":selected").each(function(index, option) {
      checkGPGKeyFor(select2, $(option));
    });
  } else {
    $(select2).next().find('.gpg').removeClass('recipient-check-key recipient-has-key recipient-has-no-key');
  }
}

function checkGPGKeyFor(select2, option) {
  var email = option.data('data').id;

  function findChoice() {
    return select2.next().find('.select2-selection__choice:contains("' + email + '")');
  }

  function setHint(data) {
    // Sets css style of an element according to result of (previous) check.
    var cls = ('true' == data) ? 'recipient-has-key' : 'recipient-has-no-key';
    findChoice().addClass(cls).addClass('gpg').removeClass('recipient-check-key');
  };

  findChoice().addClass('recipient-check-key').addClass('gpg');

  // ajax call for checking availability of a key.
  $.get( '../gpgkeys/query?id=' + email, function(data) {
    console.log("key status received for: ", email, data);
    setHint(data);
  });
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
      showGPGHints();
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
    showGPGHints();
  });
});
