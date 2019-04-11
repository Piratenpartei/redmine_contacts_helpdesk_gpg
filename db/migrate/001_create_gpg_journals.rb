class CreateGpgJournals < Rails.version < '5.2' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :gpg_journals do |t|
      t.references :issue
      t.references :journal
      t.boolean :was_signed
      t.boolean :was_encrypted
    end
    add_index :gpg_journals, %i[issue_id journal_id]
  end
end
