# -*- coding: utf-8 -*-
require_relative '../test_helper'
require 'Time'

class RethinkOutputTest < Test::Unit::TestCase
  include RethinkTestHelper

  def setup
    Fluent::Test.setup
    require 'fluent/plugin/out_rethink'

    setup_rethinkdb
  end

  def teardown
    #r.table_drop(table_name).run(@@conn) rescue nil
    teardown_rethinkdb
  end

  def table_name
    'test'
  end

  def default_config
    %[
      type rethink
      database #{RETHINK_DB}
      table #{table_name}
      port #{unused_port}
      include_time_key yes
      ]
  end

  def create_driver(conf = default_config)
    conf = conf + %[
      port #{@@rethinkdb_port}
      ]
      Fluent::Test::BufferedOutputTestDriver.new(Fluent::RethinkOutput).configure(conf)
  end

  def test_configure
    d = create_driver(%[
      type rethink
      database fluent_test
      table log
      host localhost
      port #{unused_port}
                      ])

    assert_equal('fluent_test', d.instance.database)
    assert_equal('log', d.instance.table)
    assert_equal('localhost', d.instance.host)
    assert_equal(@@rethinkdb_port.to_s, d.instance.port)
    assert_equal('log', d.instance.table)
    # buffer_chunk_limit moved from configure to start
    # I will move this test to correct space after BufferedOutputTestDriver supports start method invoking
    # assert_equal(Fluent::RethinkOutput::LIMIT_BEFORE_v1_8, d.instance.instance_variable_get(:@buffer).buffer_chunk_limit)
  end

  def test_start

  end

  #def test_configure_with_write_concern
  #d = create_driver(default_config + %[
  #write_concern 2
  #])

  #assert_equal({:w => 2, :ssl => false}, d.instance.connection_options)
  #end

  #def test_configure_with_ssl
  #d = create_driver(default_config + %[
  #ssl true
  #])

  #assert_equal({:ssl => true}, d.instance.connection_options)
  #end

  def test_format
    d = create_driver default_config
    r.table_create(table_name).run(@@conn) rescue nil
    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.emit({'a' => 1}, time)
    d.emit({'a' => 2}, time)
    d.expect_format([ 'test', time, {'a' => 1}].to_msgpack)
    d.expect_format([ 'test', time, {'a' => 2}].to_msgpack)
    d.run

    assert_equal(2, r.table(table_name).count().run(@@conn))
  end

  def emit_documents(d)
    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.emit({'a' => 1}, time)
    d.emit({'a' => 2}, time)
    time
  end

  def get_documents
    r.table(table_name).run(@@conn)
  end

  def test_write
    d = create_driver default_config
    t = emit_documents(d)
    d.run
    documents = get_documents.map { |e| e['a'] }.sort
    assert_equal([1, 2], documents)
    assert_equal(2, documents.size)
  end

end


