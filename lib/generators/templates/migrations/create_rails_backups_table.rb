class CreateRailsBackupsTable < ActiveRecord::Migration
  def change
    create_table :rails_backups do |t|
      t.datetime :timestamp
      t.string :zip_file_path
    end
  end
end