#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'json'

ROOT = File.expand_path(__dir__)
DATA_DIR = File.join(ROOT, 'data')
TAXONOMY_FILE = File.join(DATA_DIR, 'tag-taxonomy.csv')
TAG_COLUMN = 'category_tags'
TIER_COLUMN = 'quality_tier'

SEARCH_FILES = %w[
  colors.csv
  typography.csv
  ui-reasoning.csv
  styles.csv
  landing.csv
  ux-guidelines.csv
  charts.csv
].freeze

def parse_tags(raw)
  raw.to_s.split('|').map(&:strip).reject(&:empty?)
end

def taxonomy_alias_map
  alias_map = {}

  CSV.foreach(TAXONOMY_FILE, headers: true) do |row|
    canonical = row['canonical_tag']&.strip
    next if canonical.nil? || canonical.empty?

    alias_map[canonical] = canonical
    parse_tags(row['aliases']).each do |aliaz|
      next if aliaz == '*'

      alias_map[aliaz] = canonical
    end
  end

  alias_map
end

def normalize_requested_tags(raw_tags, alias_map)
  parse_tags(raw_tags).map { |tag| alias_map.fetch(tag, tag) }.uniq
end

def tier_weight(tier)
  case tier
  when 'core' then 3
  when 'extended' then 2
  when 'experimental' then 1
  else 0
  end
end

def score_row(requested_tags, row_tags, tier)
  overlap = (requested_tags & row_tags).length
  requested_count = [requested_tags.length, 1].max
  coverage = overlap.to_f / requested_count

  tag_score = (coverage * 70).round
  all_bonus = row_tags.include?('all') ? 5 : 0
  tier_score = tier_weight(tier) * 10

  tag_score + all_bonus + tier_score
end

def top_rows_for_file(file_name, requested_tags, alias_map, limit)
  path = File.join(DATA_DIR, file_name)
  rows = []

  CSV.foreach(path, headers: true).with_index(2) do |row, line_no|
    row_hash = row.to_h
    row_tags = normalize_requested_tags(row_hash[TAG_COLUMN], alias_map)
    tier = row_hash[TIER_COLUMN].to_s.strip

    score = score_row(requested_tags, row_tags, tier)
    next if score <= 0

    rows << {
      file: file_name,
      line: line_no,
      score: score,
      quality_tier: tier,
      category_tags: row_tags,
      row: row_hash
    }
  end

  sorted = rows.sort_by { |r| [-r[:score], r[:line]] }
  tiers = %w[core extended experimental]

  tiers.each do |tier|
    tier_rows = sorted.select { |r| r[:quality_tier] == tier }
    next if tier_rows.empty?

    return tier_rows.first(limit)
  end

  []
end

def parse_args(argv)
  args = {
    tags: nil,
    limit_per_file: 3,
    format: 'text'
  }

  i = 0
  while i < argv.length
    case argv[i]
    when '--tags'
      i += 1
      args[:tags] = argv[i]
    when '--limit'
      i += 1
      args[:limit_per_file] = argv[i].to_i
    when '--format'
      i += 1
      args[:format] = argv[i]
    end
    i += 1
  end

  args
end

def print_text(results)
  results.each do |file_name, rows|
    puts "\n#{file_name}"
    if rows.empty?
      puts '  (no matches)'
      next
    end

    rows.each do |entry|
      puts "  line=#{entry[:line]} score=#{entry[:score]} tier=#{entry[:quality_tier]} tags=#{entry[:category_tags].join('|')}"
    end
  end
end

def main
  unless File.exist?(TAXONOMY_FILE)
    warn "Missing taxonomy file: #{TAXONOMY_FILE}"
    exit(1)
  end

  args = parse_args(ARGV)
  if args[:tags].nil? || args[:tags].strip.empty?
    warn 'Usage: ruby rank-design-data.rb --tags "saas|b2b|analytics" [--limit 3] [--format text|json]'
    exit(1)
  end

  alias_map = taxonomy_alias_map
  requested_tags = normalize_requested_tags(args[:tags], alias_map)

  results = {}
  SEARCH_FILES.each do |file_name|
    results[file_name] = top_rows_for_file(file_name, requested_tags, alias_map, args[:limit_per_file])
  end

  if args[:format] == 'json'
    puts JSON.pretty_generate(results)
  else
    puts "Requested tags: #{requested_tags.join('|')}"
    print_text(results)
  end
end

main
