module RailsBackup
  class Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../../templates', __FILE__)
      def copy_migrations
        migration_template 'migrations/create_rails_backups_table.rb', 'db/migrate/create_rails_backups_table.rb'
      end

      def create_config_file
        template 'backup.yml', 'config/backup.yml'
      end

      def self.next_migration_number(dir)
        Time.now.utc.strftime('%Y%m%d%H%M%S')
      end
    end
  end
end