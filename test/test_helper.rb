# -*- coding: utf-8 -*-

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'fluent/test'
require 'minitest/unit'
require 'minitest/autorun'
require 'minitest/pride'

require 'rethinkdb'

RETHINK_DB = 'fluent_test'
RETHINK_PATH = File.join(File.dirname(__FILE__), 'plugin', 'data')

module RethinkTestHelper
  @@setup_count = 0
  include RethinkDB::Shortcuts

  def cleanup_rethinkdbd_env
    system("killall rethinkdb")
    system("rm -rf #{RETHINK_PATH}/rethinkdb_data")
    system("mkdir -p #{RETHINK_PATH}")
  end

  def unused_port
    47891
  end

  def setup_rethinkdb
    unless defined?(@@current_rethinkdb_test_class) and @@current_rethinkdb_test_class == self.class
      cleanup_rethinkdbd_env           
      @@current_rethinkdb_test_class = self.class
      @@rethinkdb_port = unused_port
      dirname = RETHINK_PATH# File.basename(Dir.getwd)
      @@pid = spawn("cd #{dirname} && rethinkdb --bind all --driver-port #{@@rethinkdb_port}")
      sleep 3
      
      @@conn = r.connect(:host => '127.0.0.1',
                          :port => @@rethinkdb_port,
                          :db => RETHINK_DB
                          )
      r.db_create(RETHINK_DB).run(@@conn) rescue nil
      
    end

    @@setup_count += 1;
  end

  def teardown_rethinkdb
    return
    if defined?(@@current_rethinkdb_test_class)
      begin 
        r.db_drop(RETHINK_DB).run(@@conn)
        @@conn.close
      rescue
        puts "Cannot close rethinkdb"
      end 
    end
    if @@setup_count == self.class.methods.size
      cleanup_rethinkdbd_env
    end
  end
end

