namespace :db do
  desc "Download production database as SQL dump to tmp/db.sql"
  task dump: :environment do
    backup_file = "tmp/db.sql"

    puts "📥 Creating SQL dump on production server..."
    dump_result = system("ssh matthew@svr-02 'docker exec $(docker ps -q --filter ancestor=matt17r/ws10:latest) sqlite3 /rails/storage/production.sqlite3 \".dump\" > /tmp/db.sql'")

    unless dump_result
      puts "❌ Failed to create SQL dump on server"
      exit 1
    end

    puts "📥 Downloading SQL dump..."
    download_result = system("scp matthew@svr-02:/tmp/db.sql #{backup_file}")

    unless download_result
      puts "❌ Failed to download SQL dump"
      exit 1
    end

    puts "🧹 Cleaning up remote temp file..."
    system("ssh matthew@svr-02 'rm -f /tmp/db.sql'")

    if File.exist?(backup_file) && File.size(backup_file) > 0
      puts "✅ Downloaded production database to #{backup_file}"
    else
      puts "❌ Downloaded file is empty or missing"
      exit 1
    end
  end

  desc "Restore development database from production SQL dump"
  task restore: :environment do
    backup_file = "tmp/db.sql"

    unless File.exist?(backup_file)
      puts "❌ SQL dump not found at #{backup_file}"
      puts "💡 Run: bin/rails db:dump"
      exit 1
    end

    development_db = Rails.root.join("storage", "development.sqlite3")
    dev_backup_file = "tmp/development_backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sqlite3"

    # Backup current development database if it exists
    if File.exist?(development_db)
      puts "💾 Backing up current development database to #{dev_backup_file}..."
      FileUtils.cp(development_db, dev_backup_file)
      puts "✅ Development database backed up successfully!"
    end

    puts "🗄️  Restoring development database from production backup..."

    # Remove existing development database file completely
    puts "🧹 Removing existing development DB..."
    FileUtils.rm_f(development_db)

    # Import the SQL dump into fresh database (SQLite will create it)
    puts "🧱 Restoring database from SQL..."
    import_result = system("sqlite3 #{development_db} < #{backup_file}")

    unless import_result
      puts "❌ SQL import failed"
      exit 1
    end

    # Verify the restore worked
    begin
      count = `sqlite3 #{development_db} "SELECT COUNT(*) FROM users;"`.strip
      puts "✅ Database restored successfully! Found #{count} users."
    rescue => e
      puts "❌ Database restore failed: #{e.message}"
      exit 1
    end
  end

  desc "Restore development database from most recent development backup"
  task restore_dev_backup: :environment do
    backup_files = Dir.glob("tmp/development_backup_*.sqlite3").sort.reverse

    if backup_files.empty?
      puts "❌ No development backup files found in tmp/"
      exit 1
    end

    latest_backup = backup_files.first
    puts "🔄 Restoring development database from #{latest_backup}..."

    development_db = Rails.root.join("storage", "development.sqlite3")

    # Remove existing development database file completely
    puts "🧹 Removing existing development DB..."
    FileUtils.rm_f(development_db)

    # Copy the backup file to development database
    FileUtils.cp(latest_backup, development_db)

    # Verify the restore worked
    begin
      count = `sqlite3 #{development_db} "SELECT COUNT(*) FROM users;"`.strip
      puts "✅ Development database restored from backup successfully! Found #{count} users."
    rescue => e
      puts "❌ Database restore failed: #{e.message}"
      exit 1
    end
  end
end
