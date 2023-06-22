# Copyright 2020 Self Group Ltd. All Rights Reserved.
require 'sqlite3'

module SelfSDK
  class Storage
    def initialize(app_id, app_device, storage_folder, _key_id)
      @app_id = sid(app_id, app_device)

      # Create the storage folder if it does not exist
      create_directory(storage_folder)

      # Create the database
      @db = SQLite3::Database.new(File.join(storage_folder, 'self.db'))
      set_pragmas
      create_accounts_table
      create_sessions_table
    end

    def tx
      @db.transaction
      yield
      @db.commit
    rescue SQLite3::Exception => e
      puts "Exception occurred"
      puts e
      puts e.backtrace
      @db.rollback
    end

    def account_exists?
      row = @db.execute("SELECT olm_account FROM accounts WHERE as_identifier = ?;", [ @app_id ]).first
      return true if row

      false
    end

    def account_create(olm)
      @db.execute("INSERT INTO accounts (as_identifier, offset, olm_account) VALUES (?, ?, ?);", [ @app_id, 0, olm ])
    rescue
    end

    def account_update(olm, offset = nil)
      @db.execute("UPDATE accounts SET olm_account = ? WHERE as_identifier = ?", [ olm, @app_id ])
    end

    def account_olm
      row = @db.execute("SELECT olm_account FROM accounts WHERE as_identifier = ?;", [ @app_id ]).first
      return nil unless row && row['olm_account']

      row['olm_account']
    end

    def account_offset
      row = @db.execute("SELECT offset FROM accounts WHERE as_identifier = ?;", [ @app_id ]).first
      return nil unless row && row['offset']

      row['offset']
    end

    def account_set_offset(offset)
      @db.execute("UPDATE accounts SET offset = ? WHERE as_identifier = ?;", [ offset, @app_id ])
    end

    def session_create(sid, olm)
      @db.execute("INSERT INTO sessions (as_identifier, with_identifier, olm_session) VALUES (?, ?, ?);", [ @app_id, sid, olm ])
    end

    def session_update(sid, olm)
      row = @db.execute("SELECT olm_session FROM sessions WHERE as_identifier = ? AND with_identifier = ?", [ @app_id, sid ]).first
      if row.nil?
        session_create(sid, olm)
      else
        @db.execute("UPDATE sessions SET olm_session = ? WHERE as_identifier = ? AND with_identifier = ?;", [ olm, @app_id, sid ])
      end
    end

    def session_get_olm(sid)
      row = @db.execute("SELECT olm_session FROM sessions WHERE as_identifier = ? AND with_identifier = ?", [ @app_id, sid ]).first
      return nil if row.nil?

      row.first
    end

    def sid(selfid, device)
      "#{selfid}:#{device}"
    end

    private

    # Create a folder if it does not exist
    def create_directory(dir)
      Dir.mkdir(dir, 0744)
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
end
