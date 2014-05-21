#!/usr/bin/env ruby

require 'json'
require 'terminal-table'
require 'colored'
require 'set'

class Catalog

  attr_reader :name, :environment, :version

  def initialize(hash)
    @data = hash['data']
    @metadata = hash['metadata']

    @name = @data['name']
    @version = @data['version']
    @environment = @data['environment']
  end

  def resources
    @data['resources']
  end

  def edges
    @data['edges']
  end

  def classes
    @data['classes']
  end

  def resource_type_count
    type_map = Hash.new { |h, k| h[k] = 0 }

    @data['resources'].each do |resource|
      resource_type = resource['type']
      type_map[resource_type] += 1
    end

    type_map
  end

  def source_edge_count
    source_map = Hash.new { |h, k| h[k] = 0 }

    @data['edges'].each do |edge|
      source_map[edge['source']] += 1
    end

    source_map
  end

  def target_edge_count
    target_map = Hash.new { |h, k| h[k] = 0 }

    @data['edges'].each do |edge|
      target_map[edge['target']] += 1
    end

    target_map
  end
end

def tableflip(headings, hash, take = nil)
  rows = hash.to_a.sort { |a, b| b[1] <=> a[1] }

  if take
    rows = rows.take(take)
  end

  table = Terminal::Table.new(:headings => headings, :rows => rows)
  puts table
end

hash = JSON.parse(File.read(ARGV[0]))
catalog = Catalog.new(hash)

puts "--- Catalog ---"

name = catalog.name
environment = catalog.environment
version = catalog.version

puts "Name: #{name.inspect}"
puts "Environment: #{environment.inspect}"
puts "Catalog version: #{version.inspect}"

puts "--- Statistics ---"

puts "Edges: #{catalog.edges.count}"
puts "Resources: #{catalog.resources.count}"
puts "Classes: #{catalog.classes.count}"

puts "--- Resource types: ---"

tableflip(['Resource Type', 'Count'], catalog.resource_type_count)

puts "--- Edges ---"

source_map = catalog.source_edge_count
target_map = catalog.target_edge_count

deleter = lambda { |k, v| v <= 1 }
source_map.delete_if(&deleter)
target_map.delete_if(&deleter)

tableflip(['Heavily depended resources', 'Count'], source_map, 20)
tableflip(['Heavily dependent resources', 'Count'], target_map, 20)

file_map = Hash.new { |h, k| h[k] = [] }

catalog.resources.each do |resource|
  file_map[resource['file']] << "#{resource['type']}[#{resource['title']}]" if resource['file']
end

puts "--- Files with the most defined resources ---"

file_rows = file_map.to_a.sort { |a, b| b[1].count <=> a[1].count }

tableflip(['File', 'Resource count'], file_rows.map { |(file, resources)| [file, resources.count] }, 20)

puts "--- Resources per file ---"

file_rows.take(20).map do |(file, resources)|
  puts "#{file} " + "(#{resources.count} resources)".yellow
  resources.sort.each do |resource|
    puts "    -- #{resource}"
  end
  puts "-" * 20
end
