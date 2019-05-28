module GpgIssuesHelper
  def gpg_icon_css_classes(obj)
    css_addon = 'icon-email'
    css_addon << '-signed' if obj.gpg_signed?
    css_addon << '-encrypted' if obj.gpg_encrypted?

    css_addon
  end

  def gpg_issue_ticket_data_info(issue)
    text = issue.helpdesk_ticket.is_incoming? ? l(:label_helpdesk_from) : l(:label_sent_to)
    gpgj = issue.gpg_journal

    classes = ['icon']
    classes << if gpgj
                 gpg_icon_css_classes(gpgj)
               else
                 helpdesk_ticket_source_icon(issue.helpdesk_ticket)
               end

    options = { class: classes.join(' ') }
    options[:title] = if issue.gpg_signed? && issue.gpg_encrypted?
                        l(:label_gpg_signed_encrypted)
                      elsif issue.gpg_signed?
                        l(:label_gpg_signed)
                      elsif issue.gpg_encrypted?
                        l(:label_gpg_encrypted)
                      else
                        "#{l(:label_helpdesk_from_address)}: #{issue.helpdesk_ticket.from_address}"
                      end

    content_tag(:span, text, options)
  end

  def gpg_journal_contact_info(journal, journal_message)
    text = journal_message.is_incoming? ? l(:label_received_from) : l(:label_sent_to)

    classes = ['icon']
    classes << if journal.gpg_journal
                 gpg_icon_css_classes(journal)
               elsif journal_message.is_incoming?
                 'icon-email'
               else
                 'icon-email-to'
               end

    options = { class: classes.join(' ') }

    if journal.gpg_journal
      options[:title] = if journal.gpg_signed? && journal.gpg_encrypted?
                          l(:label_gpg_signed_encrypted)
                        elsif journal.gpg_signed?
                          l(:label_gpg_signed)
                        elsif journal.gpg_encrypted?
                          l(:label_gpg_encrypted)
                        end
    end

    content_tag(:span, text, options)
  end
end
