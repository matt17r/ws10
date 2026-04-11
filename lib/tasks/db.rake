namespace :db do
  desc "Download production database as SQL dump to tmp/db.sql (defaults to bert, override with HOST=ernie)"
  task dump: :environment do
    host = ENV.fetch("HOST", "bert")
    remote_db = "/home/matthew/apps/ws10/shared/storage/production.sqlite3"
    backup_file = "tmp/db.sql"

    puts "Creating SQL dump from #{host}..."
    dump_result = system("ssh matthew@#{host} 'sqlite3 #{remote_db} \".dump\"' > #{backup_file}")

    unless dump_result && File.exist?(backup_file) && File.size(backup_file) > 0
      puts "Failed to create SQL dump from #{host}"
      exit 1
    end

    puts "Downloaded production database to #{backup_file}"
  end

  desc "Restore development database from production SQL dump"
  task restore: :environment do
    backup_file = "tmp/db.sql"

    unless File.exist?(backup_file)
      puts "SQL dump not found at #{backup_file}"
      puts "Run: bin/rails db:dump"
      exit 1
    end

    development_db = Rails.root.join("storage", "development.sqlite3")
    dev_backup_file = "tmp/development_backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sqlite3"

    if File.exist?(development_db)
      puts "Backing up current development database to #{dev_backup_file}..."
      FileUtils.cp(development_db, dev_backup_file)
    end

    puts "Restoring development database from production backup..."
    FileUtils.rm_f(development_db)

    unless system("sqlite3 #{development_db} < #{backup_file}")
      puts "SQL import failed"
      exit 1
    end

    count = `sqlite3 #{development_db} "SELECT COUNT(*) FROM users;"`.strip
    puts "Database restored successfully! Found #{count} users."
  end

  desc "Restore development database from most recent development backup"
  task restore_dev_backup: :environment do
    backup_files = Dir.glob("tmp/development_backup_*.sqlite3").sort.reverse

    if backup_files.empty?
      puts "No development backup files found in tmp/"
      exit 1
    end

    latest_backup = backup_files.first
    puts "Restoring development database from #{latest_backup}..."

    development_db = Rails.root.join("storage", "development.sqlite3")
    FileUtils.rm_f(development_db)
    FileUtils.cp(latest_backup, development_db)

    count = `sqlite3 #{development_db} "SELECT COUNT(*) FROM users;"`.strip
    puts "Development database restored from backup. Found #{count} users."
  end
end
