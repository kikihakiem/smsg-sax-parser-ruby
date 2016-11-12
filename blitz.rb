#!/usr/bin/env ruby

require './lib/extensions'
require './lib/management_node_parser'
require './lib/node_parser'
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

accumulator = SqlHelper::Accumulator.new(config)

ManagementNodeParser.each_node(File.join('..', 'samsung-sax-parser', 'xml', 'ManagementNode.xml')) do |result|
  accumulator.add_record 'ManagementNode', result
end
accumulator.flush

# Dir[File.join('xml', 'eNB_256.xml')].each do |xml_file|
Parallel.each(Dir[File.join('..', 'samsung-sax-parser', 'xml', 'eNB_*.xml')], progress: 'Parsing XML files') do |xml_file|
  accumulator = SqlHelper::Accumulator.new(config)
  NodeParser.each_node(xml_file) do |table_name, result|
    accumulator.add_record table_name, result
  end
  accumulator.flush
end

puts "Finished in #{(Time.now - start)} seconds"