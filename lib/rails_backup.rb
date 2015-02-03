require 'rails_backup/version'
require 'zip'
require 'find'
require 'fileutils'

module RailsBackup
  class RailsBackup < ActiveRecord::Base

    def self.generate_backup(verbose = false)
      if verbose
        start_time = Time.current
        puts "*** Backup started at #{start_time.to_s}"
      end
      backup = RailsBackup.create(timestamp: Time.current)
      zip_file_path = backup.generate_backup_zip
      backup.zip_file_path = zip_file_path
      backup.save
      if verbose
        puts "*** Backup file path: #{zip_file_path}"
        puts "*** Backup time: #{(Time.current - start_time).to_s}"
        puts "*** Backup ended at #{Time.current.to_s}"
        puts '------------------------------------------------------------------'
      end
    end

    # Genera el dump de la base de datos, el zip de uploads y de images y luego los zipea todos en uno solo retornando el path absoluto del zip final
    def generate_backup_zip
      zip_files = []
      backup_yml = YAML.load(File.read('config/backup.yml'))
      zip_files << self.generate_dump if backup_yml['database']
      folders = backup_yml['folders']
      folders.each do |folder|
        zip_files << self.generate_zip(Rails.root.join(folder['path']).to_s, folder['zip_name'])
      end
      files = backup_yml['files']
      files.each do |file|
        zip_files << self.generate_zip(Rails.root.join(file['path']).to_s, file['zip_name'])
      end
      backup_zip_path = "#{self.generate_directory}/#{self.backup_description}_COMPLETE_BACKUP.zip"
      FileUtils.rm backup_zip_path, force: true

      Zip::File.open(backup_zip_path, Zip::File::CREATE) do |zipfile|
        zip_files.each do |file|
          zipfile.add(file[:name], file[:path])
        end
      end
      File.chmod(0644,backup_zip_path)
      # Delete subzips
      zip_files.each do |file|
        FileUtils.rm(Rails.root.join(file[:path]).to_s, force: true)
      end
      backup_zip_path
    end

    # Descriptor del backup utilizado para nombrar tanto el archivo con el backup completo como el dump de la base de datos
    def backup_description
      "#{self.id.to_s}_#{self.timestamp.strftime('%Y%m%dT%H%M%S%z')}"
    end

    # Genera el directorio asociado a este backup y retorna su path absoluto en un string,
    def generate_directory
      backup_dir = Rails.root.join('backups',
                                   self.timestamp.year.to_s,
                                   "#{self.timestamp.strftime('%m')}_#{self.timestamp.strftime('%B')}".downcase,
                                   self.id.to_s).to_s
      FileUtils.mkdir_p( backup_dir )
      backup_dir
    end

    # Genera un dump de la base de datos y retorna un Hash con el nombre del archivo y su path absoluto
    def generate_dump
      backup_file  = "#{generate_directory}/#{backup_description}.sql"
      env_info     = YAML.load(File.read('config/database.yml'))[Rails.env]
      dbadapter    = env_info['adapter']
      dbuser       = env_info['username']
      dbpass       = env_info['password']
      env_database = env_info['database']
      dbhost       = env_info['host']
      if dbadapter == 'mysql2'
        system "mysqldump -u #{dbuser} -h #{dbhost} -p#{dbpass} #{env_database} > #{backup_file}"
        { name: "#{backup_description}.sql", path: "#{backup_file}.bz2" }
      else # TODO: add other database engines
        raise "The #{dbadapter} adapter is not supported by rails_backup gem yet!"
      end
    end

    # Genera un zip del directorio "dir" y retorna un Hash con el nombre del zip y su path absoluto
    def generate_zip(dir, zip_name, remove_after = false)
      zip_path = "#{self.generate_directory}/#{zip_name}.zip"
      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        Find.find(dir) do |path|
          Find.prune if File.basename(path)[0] == ?.
          dest = /#{dir}\/(\w.*)/.match(path)
          # Skip files if they exists
          zipfile.add(dest[1],path) if dest
        end
      end
      FileUtils.rm_rf(dir) if remove_after
      { name: "#{zip_name}.zip", path: zip_path }
    end
  end
end
