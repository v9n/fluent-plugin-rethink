require 'rethinkdb'

module Fluent
  class RethinkOutput < BufferedOutput
    include RethinkDB::Shortcuts
    Plugin.register_output('rethink', self)

    config_param :database, :string
    config_param :host, :string, :default => 'localhost'
    config_param :table, :string, :default => :log
    config_param :port, :integer, :default => 28015
    config_param :auto_tag_table, :default => false

    include SetTagKeyMixin
    config_set_default :include_tag_key, true

    include SetTimeKeyMixin
    config_set_default :include_time_key, true

    # This method is called before starting.
    # 'conf' is a Hash that includes configuration parameters.
    # If the configuration is invalid, raise Fluent::ConfigError.
    def configure(conf)
      super

      @db    = conf['database']
      @host  = conf['host']
      @port  = conf['port']
      @table = conf['table']
    end

    def start
      super
      @conn = r.connect(:host => @host,
                        :port => @port,
                        :db => @db)
    end

    def shutdown
      super
      @conn.close
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    # This method is called every flush interval. Write the buffer chunk
    # to files or databases here.
    # 'chunk' is a buffer chunk that includes multiple formatted
    # events. You can use 'data = chunk.read' to get all events and
    # 'chunk.open {|io| ... }' to get IO objects.
    #
    # NOTE! This method is called by internal thread, not Fluentd's main thread. So IO wait doesn't affect other plugins.
    def write(chunk)
      records = {}
      chunk.msgpack_each {|(tag,time,record)|
        record[@time_key] = Time.at(time || record[@time_key]) if @include_time_key
        record[@tag_key] = tag if @include_tag_key
        records[tag] ||= []
        records[tag] << record
      }

      begin
        records.map do |tag, elements|
          if !elements.empty?
            get_table(@auto_tag_table ? tag : @table).insert(elements).run(@conn)
          end
        end
      rescue
      end
    end  

    def get_table(table)
      return r.table(table) unless @auto_tag_table

      begin 
        r.table_create(table).run @conn
        r.table(table)
      rescue RethinkDB::RqlRuntimeError =>e
      end
    end

  end
end

