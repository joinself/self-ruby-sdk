# Copyright 2020 Self Group Ltd. All Rights Reserved.

module SelfSDK
  class Entry
    def initialize(sid)
      raise 'session file does not exist' unless File.exist?(sid)

      # FileUtils.mkdir_p(File.dirname(sid))
      @fs = File.open(sid, "r+")
    end

    def write(pickle)
      @fs.rewind
      @fs.write(pickle)
      @fs.truncate(@fs.pos)
    end

    def read
      @fs.read
    end

    def lock
      @fs.flock(File::LOCK_EX)
    end

    def unlock
      @fs.flock(File::LOCK_UN)
    end
  end

  class Tx
    def initialize(app_id, app_device, storage)
      @app_id = app_id
      @app_device = app_device
      @storage = storage
      @entries = {}
    end

    def lock(recipients)
      recipients.each do |r|
        # Skip message if is sent to the current user / device
        next if r[:id] == @app_id && r[:device_id] == @app_device

        sid = @storage.sid(r[:id], r[:device_id])
        lock_by_id(sid)
      end
    end

    def session_update(sid, pickle)
      if @entries.key? sid
        # @entries[sid] = Entry.new(sid)
        @entries[sid].write(pickle)
      else
        @storage.write(sid, pickle)
      end
    end

    def session_offset(sid)
      return nil unless @entries.key? sid

      @entries[sid].read
    end

    def unlock
      # Unlock all files
      @entries.each do |_path, entry|
        entry&.unlock
      end
    end

    private

    def lock_by_id(sid)
      entry = nil
      if @storage.exist?(sid)
        @entries[sid] = Entry.new(sid)
        @entries[sid].lock
        entry = @entries[sid]
      end
      entry
    end

  end

  class Storage
    def initialize(app_id, app_device, storage_folder, key_id)
      @app_id = app_id
      @app_device = app_device

      @storage_folder = "#{storage_folder}/keys"
      FileUtils.mkdir_p @storage_folder unless File.exist? @storage_folder

      @key_prefix = "#{@storage_folder}/#{key_id}"
      FileUtils.mkdir_p(@key_prefix)

      @offset_file = "#{@storage_folder}/#{@app_id}:#{@app_device}.offset"
    end

    def tx(recipients = [])
      tx = Tx.new(@app_id, @app_device, self)
      tx.lock(recipients)
      yield(tx)
    ensure
      tx&.unlock
    end

    def write(sid, pickle)
      File.write(sid, pickle)
    end

    def exist?(sid)
      File.exist?(sid)
    end

    def read(sid)
      File.read(sid)
    end

    def sid(selfid, device)
      "#{@key_prefix}/#{selfid}:#{device}-session.pickle"
    end

    def account_exists?
      exist? account_path
    end

    def account_create(olm, offset = nil)
      write(account_path, olm) unless olm.nil?
    end

    def account_update(olm, offset = nil)
      write(account_path, olm) unless olm.nil?
    end

    def account_olm
      read account_path
    end

    def account_get_offset
      return 0 unless File.exist? @offset_file

      File.open(@offset_file, 'rb') do |f|
        return f.read.to_i
      end
    end

    def account_set_offset(offset)
      File.open(@offset_file, 'wb') do |f|
        f.flock(File::LOCK_EX)
        f.write(offset.to_s.rjust(19, "0"))
      end
      SelfSDK.logger.debug "offset written #{offset}"
      @offset = offset
    end

    def session_create(sid, olm)
      write(sid, olm)
    end

    def session_update(sid, olm)
      write(sid, olm)
    end

    private

    def account_path
      "#{@storage_folder}/account.pickle"
    end

    def offset_path(sid)
      "#{@storage_dir}/#{@jwt.id}:#{@device_id}.offset"
    end
  end
end
