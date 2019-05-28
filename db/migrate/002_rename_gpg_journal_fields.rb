class RenameGpgJournalFields < Rails.version < '5.2' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    rename_column :gpg_journals, :was_signed, :signed
    rename_column :gpg_journals, :was_encrypted, :encrypted

    change_column_null(:gpg_journals, :signed, false, false)
    change_column_null(:gpg_journals, :encrypted, false, false)
  end
end
