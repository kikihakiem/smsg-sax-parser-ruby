#!/usr/bin/env ruby

require './lib/extensions'

if RUBY_PLATFORM.eql?('java')
  require './lib/jruby_compatible/management_node_parser'
  require './lib/jruby_compatible/node_parser'
else
  require './lib/management_node_parser'
  require './lib/node_parser'
end

require './lib/sql_helper'
require 'ruby-progressbar'
require 'parallel'
require 'yaml'

start = Time.now
config = YAML.load_file('config.yml')

mysql_client = Mysql2::Client.new(config[:db_connection])
mysql_client.query 'drop database if exists sax'
mysql_client.query 'create database sax'
mysql_client.query 'use sax'

SqlHelper.accumulate(config) do |accumulator|
  ManagementNodeParser.each_node(File.join('..', 'samsung-sax-parser', 'xml', 'ManagementNode.xml')) do |result|
    accumulator.add_record 'ManagementNode', result
  end
end

# Dir[File.join('..', 'samsung-sax-parser', 'xml', 'eNB_256.xml')].each do |xml_file|
Parallel.each(Dir[File.join('..', 'samsung-sax-parser', 'xml', 'eNB_*.xml')], progress: 'Parsing XML files') do |xml_file|
  SqlHelper.accumulate(config) do |accumulator|
    NodeParser.each_node(xml_file) do |table_name, result|
      accumulator.add_record table_name, result
    end
  end
end

puts "Finished in #{(Time.now - start)} seconds"