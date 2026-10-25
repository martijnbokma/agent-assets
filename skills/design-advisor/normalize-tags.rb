#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'

ROOT = File.expand_path(__dir__)
DATA_DIR = File.join(ROOT, 'data')
TAXONOMY_FILE = File.join(DATA_DIR, 'tag-taxonomy.csv')
TAG_COLUMN = 'category_tags'

DATA_FILES = %w[
  colors.csv
  typography.csv
  ui-reasoning.csv
  styles.csv
  landing.csv
  ux-guidelines.csv
  charts.csv
].freeze

def parse_aliases(raw)
  raw.to_s.split('|').map(&:strip).reject(&:empty?)
end

def taxonomy_maps
  canonical = {}
  alias_map = {}

  CSV.foreach(TAXONOMY_FILE, headers: true) do |row|
    tag = row['canonical_tag']&.strip
    next if tag.nil? || tag.empty?

    canonical[tag] = true
    alias_map[tag] = tag

    parse_aliases(row['aliases']).each do |aliaz|
      next if aliaz == '*'

      alias_map[aliaz] = tag
    end
  end

  [canonical, alias_map]
end

def normalize_tag_list(raw_tags, alias_map)
  tags = raw_tags.to_s.split('|').map(&:strip).reject(&:empty?)
  mapped = tags.map { |tag| alias_map.fetch(tag, tag) }
  mapped.uniq.sort
end

def process_file(path, alias_map, dry_run)
  table = CSV.read(path, headers: true)
  headers = table.headers
  unless headers.include?(TAG_COLUMN)
    puts "#{File.basename(path)}: skipped (missing #{TAG_COLUMN})"
    return 0
  end

  changed = 0

  table.each do |row|
    original = row[TAG_COLUMN].to_s
    normalized = normalize_tag_list(original, alias_map).join('|')
    next if original == normalized

    row[TAG_COLUMN] = normalized
    changed += 1
  end

  File.write(path, table.to_csv) unless dry_run
  changed
end

def main
  dry_run = ARGV.include?('--dry-run')

  unless File.exist?(TAXONOMY_FILE)
    warn "Missing taxonomy: #{TAXONOMY_FILE}"
    exit(1)
  end

  _canonical, alias_map = taxonomy_maps

  total_changed = 0

  DATA_FILES.each do |file_name|
    path = File.join(DATA_DIR, file_name)
    unless File.exist?(path)
      puts "#{file_name}: skipped (missing file)"
      next
    end

    changed = process_file(path, alias_map, dry_run)
    total_changed += changed
    puts "#{file_name}: changed_rows=#{changed}"
  end

  mode = dry_run ? 'dry-run' : 'apply'
  puts "Normalization complete (#{mode}). total_changed_rows=#{total_changed}"
end

main
