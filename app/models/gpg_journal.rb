class GpgJournal < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :issue
  belongs_to :journal

  def helpdesk_ticket
    journal.issue.helpdesk_ticket
  end

  def gpg_signed?
    signed?
  end

  def gpg_encrypted?
    encrypted?
  end
end
