require "fileutils"
require "openssl"

module RankedModel
  class AdvisoryLock
    Adapter = Struct.new(:initialise, :aquire, :release, keyword_init: true)

    attr_reader :base_class

    def initialize(base_class, column)
      @base_class = base_class
      @column = column.to_s

      @adapters = {
        "Mysql2" => Adapter.new(
          initialise: -> {},
          aquire: -> { connection.execute "SELECT GET_LOCK(#{connection.quote(lock_name)}, -1)" },
          release: -> { connection.execute "SELECT RELEASE_LOCK(#{connection.quote(lock_name)})" }
        ),
        "PostgreSQL" => Adapter.new(
          initialise: -> {},
          aquire: -> { connection.execute "SELECT pg_advisory_lock(#{lock_name.hex & 0x7FFFFFFFFFFFFFFF})" },
          release: -> { connection.execute "SELECT pg_advisory_unlock(#{lock_name.hex & 0x7FFFFFFFFFFFFFFF})" }
        ),
        "SQLite" => Adapter.new(
          initialise: -> {
            FileUtils.mkdir_p "#{Dir.pwd}/tmp"
            filename = "#{Dir.pwd}/tmp/#{lock_name}.lock"
            @file ||= File.open filename, File::RDWR | File::CREAT, 0o644
          },
          aquire: -> {
            @file.flock File::LOCK_EX
          },
          release: -> {
            @file.flock File::LOCK_UN
          }
        )
      }

      @adapters.default = Adapter.new(initialise: -> {}, aquire: -> {}, release: -> {})

      adapter.initialise.call
    end

    def aquire(record)
      adapter.aquire.call
    end

    def release(record)
      adapter.release.call
    end

    alias_method :before_create, :aquire
    alias_method :before_update, :aquire
    alias_method :before_destroy, :aquire
    alias_method :after_commit, :release
    alias_method :after_rollback, :release

    private

    def connection
      base_class.connection
    end

    def adapter_name
      connection.adapter_name
    end

    def adapter
      @adapters[adapter_name]
    end

    def lock_name
      lock_name = ["ranked-model"]
      lock_name << connection.current_database if connection.respond_to?(:current_database)
      lock_name << base_class.table_name
      lock_name << @column

      OpenSSL::Digest::MD5.hexdigest(lock_name.join("."))[0...32]
    end
  end
end
