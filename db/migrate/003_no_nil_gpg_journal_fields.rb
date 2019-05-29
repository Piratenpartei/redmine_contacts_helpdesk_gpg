class NoNilGpgJournalFields < Rails.version < '5.2' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def up
    change_column_default(:gpg_journals, :signed, false)
    change_column_default(:gpg_journals, :encrypted, false)
  end

  def down
    change_column_default(:gpg_journals, :signed, nil)
    change_column_default(:gpg_journals, :encrypted, nil)
  end
end
