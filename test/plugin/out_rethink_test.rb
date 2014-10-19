# -*- coding: utf-8 -*-
require_relative '../test_helper'

class RethinkOutputTest < Test::Unit::TestCase
  include RethinkTestHelper

  def setup
    Fluent::Test.setup
    require 'fluent/plugin/out_rethink'

    setup_rethinkdb
  end

  def teardown
    r.table_drop(collection_name).run(@@conn) rescue nil
    teardown_rethinkdb
  end

  def collection_name
    'test'
  end

  def default_config
    %[
      type rethink
      database #{RETHINK_DB}
      collection #{collection_name}
      include_time_key true # TestDriver ignore config_set_default?
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
    ])

    assert_equal('fluent_test', d.instance.database)
    assert_equal('log', d.instance.table)
    assert_equal('localhost', d.instance.host)
    assert_equal(@@rethinkdb_port.to_s, d.instance.port)
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
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.emit({'a' => 1}, time)
    d.emit({'a' => 2}, time)
    #d.expect_format([time, {'a' => 1, d.instance.time_key => time}].to_msgpack)
    #d.expect_format([time, {'a' => 2, d.instance.time_key => time}].to_msgpack)
    d.run

    assert_equal(2, r.table(collection_name).count().run(@@conn))
  end

  #def emit_documents(d)
    #time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    #d.emit({'a' => 1}, time)
    #d.emit({'a' => 2}, time)
    #time
  #end

  #def get_documents
    #@db.collection(collection_name).find().to_a.map { |e| e.delete('_id'); e }
  #end

  #def test_write
    #d = create_driver
    #t = emit_documents(d)

    #d.run
    #documents = get_documents.map { |e| e['a'] }.sort
    #assert_equal([1, 2], documents)
    #assert_equal(2, documents.size)
  #end

  #def test_write_at_enable_tag
    #d = create_driver(default_config + %[
      #include_tag_key true
      #include_time_key false
    #])
    #t = emit_documents(d)

    #d.run
    #documents = get_documents.sort_by { |e| e['a'] }
    #assert_equal([{'a' => 1, d.instance.tag_key => 'test'},
                  #{'a' => 2, d.instance.tag_key => 'test'}], documents)
    #assert_equal(2, documents.size)
  #end

  #def emit_invalid_documents(d)
    #time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    #d.emit({'a' => 3, 'b' => "c", '$last' => '石動'}, time)
    #d.emit({'a' => 4, 'b' => "d", 'first' => '菖蒲'.encode('EUC-JP').force_encoding('UTF-8')}, time)
    #time
  #end

  #def test_write_with_invalid_recoreds_with_keys_containing_dot_and_dollar
    #d = create_driver(default_config + %[
      #replace_dot_in_key_with _dot_
      #replace_dollar_in_key_with _dollar_
    #])

    #time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    #d.emit({
      #"foo.bar1" => {
        #"$foo$bar" => "baz"
      #},
      #"foo.bar2" => [
        #{
          #"$foo$bar" => "baz"
        #}
      #],
    #}, time)
    #d.run

    #documents = get_documents
    #assert_equal(1, documents.size)
    #assert_equal("baz", documents[0]["foo_dot_bar1"]["_dollar_foo$bar"])
    #assert_equal("baz", documents[0]["foo_dot_bar2"][0]["_dollar_foo$bar"])
    #assert_equal(0, documents.select { |e| e.has_key?(Fluent::RethinkOutput::BROKEN_DATA_KEY)}.size)
  #end

  #def test_write_with_invalid_recoreds
    #d = create_driver
    #t = emit_documents(d)
    #t = emit_invalid_documents(d)

    #d.run
    #documents = get_documents
    #assert_equal(4, documents.size)
    #assert_equal([1, 2], documents.select { |e| e.has_key?('a') }.map { |e| e['a'] }.sort)
    #assert_equal(2, documents.select { |e| e.has_key?(Fluent::RethinkOutput::BROKEN_DATA_KEY)}.size)
    #assert_equal([3, 4], @db.collection(collection_name).find({Fluent::RethinkOutput::BROKEN_DATA_KEY => {'$exists' => true}}).map { |doc|
      #Marshal.load(doc[Fluent::RethinkOutput::BROKEN_DATA_KEY].to_s)['a']
    #}.sort)
  #end

  #def test_write_with_invalid_recoreds_with_exclude_one_broken_fields
    #d = create_driver(default_config + %[
      #exclude_broken_fields a
    #])
    #t = emit_documents(d)
    #t = emit_invalid_documents(d)

    #d.run
    #documents = get_documents
    #assert_equal(4, documents.size)
    #assert_equal(2, documents.select { |e| e.has_key?(Fluent::RethinkOutput::BROKEN_DATA_KEY) }.size)
    #assert_equal([1, 2, 3, 4], documents.select { |e| e.has_key?('a') }.map { |e| e['a'] }.sort)
    #assert_equal(0, documents.select { |e| e.has_key?('b') }.size)
  #end

  #def test_write_with_invalid_recoreds_with_exclude_two_broken_fields
    #d = create_driver(default_config + %[
      #exclude_broken_fields a,b
    #])
    #t = emit_documents(d)
    #t = emit_invalid_documents(d)

    #d.run
    #documents = get_documents
    #assert_equal(4, documents.size)
    #assert_equal(2, documents.select { |e| e.has_key?(Fluent::RethinkOutput::BROKEN_DATA_KEY) }.size)
    #assert_equal([1, 2, 3, 4], documents.select { |e| e.has_key?('a') }.map { |e| e['a'] }.sort)
    #assert_equal(["c", "d"], documents.select { |e| e.has_key?('b') }.map { |e| e['b'] }.sort)
  #end

  #def test_write_with_invalid_recoreds_at_ignore
    #d = create_driver(default_config + %[
      #ignore_invalid_record true
    #])
    #t = emit_documents(d)
    #t = emit_invalid_documents(d)

    #d.run
    #documents = get_documents
    #assert_equal(2, documents.size)
    #assert_equal([1, 2], documents.select { |e| e.has_key?('a') }.map { |e| e['a'] }.sort)
    #assert_equal(true, @db.collection(collection_name).find({Fluent::RethinkOutput::BROKEN_DATA_KEY => {'$exists' => true}}).count.zero?)
  #end
#end

#class RethinkReplOutputTest < RethinkOutputTest
  #def setup
    #Fluent::Test.setup
    #require 'fluent/plugin/out_rethink_replset'

    #ensure_rs
  #end

  #def teardown
    #@rs.restart_killed_nodes
    #if defined?(@db) && @db
      #@db.collection(collection_name).drop
      #@db.connection.close
    #end
  #end

  #def default_config
    #%[
      #type rethink_replset
      #database #{RETHINK_DB_DB}
      #collection #{collection_name}
      #nodes #{build_seeds(3).join(',')}
      #num_retries 30
      #include_time_key true # TestDriver ignore config_set_default?
    #]
  #end

  #def create_driver(conf = default_config)
    #@db = Rethink::RethinkReplicaSetClient.new(build_seeds(3), :name => @rs.name).db(RETHINK_DB_DB)
    #Fluent::Test::BufferedOutputTestDriver.new(Fluent::RethinkOutputReplset).configure(conf)
  #end

  #def test_configure
    #d = create_driver(%[
      #type rethink_replset

      #database fluent_test
      #collection test_collection
      #nodes #{build_seeds(3).join(',')}
      #num_retries 45

      #capped
      #capped_size 100
    #])

    #assert_equal('fluent_test', d.instance.database)
    #assert_equal('test_collection', d.instance.collection)
    #assert_equal(build_seeds(3), d.instance.nodes)
    #assert_equal(45, d.instance.num_retries)
    #assert_equal({:capped => true, :size => 100}, d.instance.collection_options)
    #assert_equal({:ssl => false}, d.instance.connection_options)
  #end
end


