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

    def write(sid, pickle)
      if @entries.key? sid
        # @entries[sid] = Entry.new(sid)
        @entries[sid].write(pickle)
      else
        @storage.write(sid, pickle)
      end
    end

    def read(sid)
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
    def initialize(app_id, app_device, key_prefix)
      @app_id = app_id
      @app_device = app_device
      @key_prefix = key_prefix
      FileUtils.mkdir_p(@key_prefix)
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
  end
end
