class GpgJournal < ActiveRecord::Base
	include Redmine::SafeAttributes
	unloadable
	belongs_to :issue
	belongs_to :journal

	safe_attributes 'was_signed', 'was_encrypted'

	def helpdesk_ticket
		journal.issue.helpdesk_ticket    
	end   
end
