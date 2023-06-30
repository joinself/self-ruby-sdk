# Copyright 2020 Self Group Ltd. All Rights Reserved.
require 'sqlite3'

module SelfSDK
  class Storage
    attr_accessor :app_id

    def initialize(app_id, app_device, storage_folder, _key_id)
      @app_id = sid(app_id, app_device)

      # Create the storage folder if it does not exist
      create_directory_skel("#{storage_folder}/identities/")

      # Create the database
      @db = SQLite3::Database.new(File.join("#{storage_folder}/identities/", 'self.db'))
      set_pragmas
      create_accounts_table
      create_sessions_table
      m = StorageMigrator.new(@db, "#{storage_folder}/apps", @app_id)
      m.migrate
    end

    def tx
      @db.transaction
      yield
      @db.commit
    rescue SQLite3::Exception => e
      @db.rollback
    rescue => e
      @db.rollback
      raise e
    end

    def account_exists?
      row = @db.execute("SELECT olm_account FROM accounts WHERE as_identifier = \"#{@app_id}\"").first
      !row.nil?
    end

    def account_create(olm)
      @db.execute("INSERT INTO accounts (as_identifier, offset, olm_account) VALUES (?, ?, ?);", [ @app_id, 0, olm ])
    rescue
    end

    def account_update(olm)
      @db.execute("UPDATE accounts SET olm_account = ? WHERE as_identifier = ?", [ olm, @app_id ])
    end

    def account_olm
      row = @db.execute("SELECT olm_account FROM accounts WHERE as_identifier = \"#{app_id}\";").first
      return nil unless row

      row.first
    end

    def account_offset
      row = @db.execute("SELECT offset FROM accounts WHERE as_identifier = \"#{@app_id}\";").first
      return nil unless row

      row.first
    end

    def account_set_offset(offset)
      @db.execute("UPDATE accounts SET offset = ? WHERE as_identifier = ?;", [ offset, @app_id ])
    end

    def session_create(sid, olm)
      @db.execute("INSERT INTO sessions (as_identifier, with_identifier, olm_session) VALUES (?, ?, ?);", [ @app_id, sid, olm ])
    end

    def session_update(sid, olm)
      row = @db.execute("SELECT olm_session FROM sessions WHERE as_identifier = \"#{@app_id}\" AND with_identifier = \"#{sid}\"").first
      if row.nil?
        session_create(sid, olm)
      else
        @db.execute("UPDATE sessions SET olm_session = ? WHERE as_identifier = ? AND with_identifier = ?;", [ olm, @app_id, sid ])
      end
    end

    def session_get_olm(sid)
      row = @db.execute("SELECT olm_session FROM sessions WHERE as_identifier = \"#{@app_id}\" AND with_identifier = \"#{sid}\"").first
      return nil if row.nil?

      row.first
    end

    def sid(selfid, device)
      "#{selfid}:#{device}"
    end

    private

    # Create a folder if it does not exist
    def create_directory_skel(storage_folder)
      FileUtils.mkdir_p storage_folder unless File.exist? storage_folder
    rescue Errno::ENOENT
      raise ERR_INVALID_DIRECTORY
    rescue
    end

    def set_pragmas
      pragma_statement = <<~SQL
        PRAGMA synchronous = NORMAL;
        PRAGMA journal_mode = WAL;
        PRAGMA temp_store = MEMORY;
      SQL

      @db.execute_batch(pragma_statement)
    rescue SQLite3::Exception => e
      puts "Exception occurred: #{e}"
    end

    def create_accounts_table
      accounts_table_statement = <<~SQL
        CREATE TABLE IF NOT EXISTS accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          as_identifier INTEGER NOT NULL,
          offset INTEGER NOT NULL,
          olm_account BLOB NOT NULL
        );
        CREATE UNIQUE INDEX IF NOT EXISTS idx_accounts_as_identifier
        ON accounts (as_identifier);
      SQL

      @db.execute_batch(accounts_table_statement)
    rescue SQLite3::Exception => e
      puts "Exception occurred: #{e}"
    end

    def create_sessions_table
      # TODO we could deduplicate as_identifier and with_identifier here
      # by creating a record for each on a new identifier table,
      # but this is only temporary
      session_table_statement = <<~SQL
        CREATE TABLE IF NOT EXISTS sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          as_identifier INTEGER NOT NULL,
          with_identifier INTEGER NOT NULL,
          olm_session BLOB NOT NULL
        );
        CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_with_identifier
        ON sessions (as_identifier, with_identifier);
      SQL

      @db.execute_batch(session_table_statement)
    rescue SQLite3::Exception => e
      puts "Exception occurred: #{e}"
    end
  end

  class StorageMigrator
    def initialize(db, storage_folder, app_id)
      @db = db
      # Old versions of the sdk using that same storage folder shouldn't be affected in any way

      @base_path = "#{storage_folder}/#{app_id.split(':').first}"
      @app_id = app_id
    end

    def migrate
      return unless File.exist?(@base_path)

      # Parse the account information.
      accounts = parse_accounts

      persist_accounts(accounts)

      # Depreciate the base path.
      File.rename("#{@base_path}", "#{@base_path}-depreciated")
    end

    private

    def parse_accounts
      accounts = {}

      Dir.glob(File.join(@base_path, "**/*")).each do |path|
        if File.directory?(path)
          next
        end

        case File.extname(path)
        when ".offset"
          file_name = File.basename(path, ".offset")
          offset = File.read(path)[0, 19].to_i

          accounts[file_name] = {} unless accounts.key? file_name
          accounts[file_name][:offset] = offset
        when ".pickle"
          file_name = File.basename(path, ".pickle")
          content = File.read(path)

          accounts[@app_id] = {} unless accounts.key? @app_id
          if file_name == "account"
            accounts[@app_id][:account] = content
          else
            if accounts.key? @app_id
              accounts[@app_id][:sessions] = [] unless accounts[@app_id].key? :sessions
              accounts[@app_id][:sessions] << {
                with: file_name.sub("-session", ""),
                session: content
              }
              next
            end
            accounts[@app_id][:account] = content
          end
        end
      end

      accounts
    end

    def persist_accounts(accounts)
      @db.transaction
      accounts.each do |inbox_id, account|
        @db.execute(
          "INSERT INTO accounts (as_identifier, offset, olm_account) VALUES ($1, $2, $3)",
          [inbox_id, account[:offset], account[:account]]
        )

        account[:sessions].each do |session|
          @db.execute(
            "INSERT INTO sessions (as_identifier, with_identifier, olm_session) VALUES ($1, $2, $3)",
            [inbox_id, session[:with], session[:session]]
          )
        end
      end

      @db.commit
    rescue SQLite3::Exception => e
      puts "Exception occurred"
      puts e
      puts e.backtrace
      @db.rollback
    end
  end
end