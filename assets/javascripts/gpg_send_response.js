function showAllGpgKeyIndicators() {
  let enabled = isGpgEncryptionEnabled();
  $([$('#helpdesk_to'), $('#helpdesk_cc'), $('#helpdesk_bcc')]).each(function(index, select2) {
    showGpgKeyIndicatorsForSelectField(select2, enabled);
  });
}

function showGpgKeyIndicatorsForSelectField(select2, enabled) {
  if (enabled) {
    $(select2).find(":selected").each(function(index, option) {
      checkGpgKeyForOption(select2, $(option));
    });
  } else {
    $(select2).next().find('.gpg').removeClass('recipient-check-key recipient-has-key recipient-has-no-key');
  }
}

function checkGpgKeyForOption(select2, option) {
  let email = option.data('data').id;

  // The select2 choice element can change in the meantime.
  // Saving the reference for later may not work, we must find the current one when we want to manipulate it.
  function findChoice() {
    return select2.next().find('.select2-selection__choice:contains("' + email + '")');
  }

  findChoice().addClass('recipient-check-key').addClass('gpg');

  function setHint(data) {
    // Sets css style of an element according to result of (previous) check.
    let cls = ('true' == data) ? 'recipient-has-key' : 'recipient-has-no-key';
    findChoice().addClass(cls).addClass('gpg').removeClass('recipient-check-key');
  };

  // ajax call for checking availability of a key.
  $.get( '../gpgkeys/query?id=' + email, function(data) {
    console.log("key status received for: ", email, data);
    setHint(data);
  });
}

function isGpgEncryptionEnabled() {
  let checkbox = $('#helpdesk_gpg_do_encrypt').get(0);
  return checkbox != null && checkbox.checked;
}

function setupCheckForTags() {
  // hook onto the select2 items and add handler for adding/removing items
  $([$('#helpdesk_to'), $('#helpdesk_cc'), $('#helpdesk_bcc')]).each(function() {

    $(this).on('select2:select', function () {
      showGpgKeyIndicatorsForSelectField($(this), isGpgEncryptionEnabled());
    });
    $(this).on('select2:unselect', function () {
      let select2 = $(this);
      setTimeout(function () {
        showGpgKeyIndicatorsForSelectField(select2, isGpgEncryptionEnabled());
      }, 500);
    });
  });
}

$(function() {
  // stuff from the helpdesk plugin we rely on
  let sendMailCheckbox = $('#helpdesk_is_send_mail');
  let ccFields = $('#cc_fields');
  let recipientEmail = $('#customer_to_email');

  // add click handler for checking keys when encryption is enabled
  $('#helpdesk_gpg_do_encrypt').on('change', showAllGpgKeyIndicators);

  // add handler(s) for new mail adresses which are edited inline
  setupCheckForTags();

  let gpgOptions = $('#helpdesk_send_response_gpg');

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
      showAllGpgKeyIndicators();
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
    showAllGpgKeyIndicators();
  });
});
