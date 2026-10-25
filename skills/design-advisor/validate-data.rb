#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'set'

ROOT = File.expand_path(__dir__)
DATA_DIR = File.join(ROOT, 'data')

FILES = {
  'colors.csv' => {
    required: %w[product_type primary secondary cta background text border color_direction category_tags quality_tier],
    tag_column: 'category_tags'
  },
  'typography.csv' => {
    required: %w[name category heading_font body_font mood best_for google_fonts_url category_tags quality_tier],
    tag_column: 'category_tags'
  },
  'ui-reasoning.csv' => {
    required: %w[product_type recommended_style color_mood typography_mood key_effects anti_patterns severity category_tags quality_tier],
    tag_column: 'category_tags'
  },
  'styles.csv' => {
    required: %w[name description implementation use_cases do_examples dont_examples category_tags quality_tier],
    tag_column: 'category_tags'
  },
  'landing.csv' => {
    required: %w[pattern_name section_order cta_placement color_strategy effects conversion_tips category_tags quality_tier],
    tag_column: 'category_tags'
  },
  'ux-guidelines.csv' => {
    required: %w[category rule do_pattern do_code dont_pattern dont_code severity category_tags quality_tier],
    tag_column: 'category_tags'
  },
  'charts.csv' => {
    required: %w[data_type best_chart colors accessibility library when_to_use avoid_when category_tags quality_tier],
    tag_column: 'category_tags'
  }
}.freeze

VALID_TIERS = Set.new(%w[core extended experimental]).freeze

def read_canonical_tags
  path = File.join(DATA_DIR, 'tag-taxonomy.csv')
  raise "Missing taxonomy file: #{path}" unless File.exist?(path)

  tags = Set.new
  CSV.foreach(path, headers: true) do |row|
    tag = row['canonical_tag']&.strip
    next if tag.nil? || tag.empty?

    tags << tag
  end
  tags
end

def parse_tags(value)
  value.to_s.split('|').map(&:strip).reject(&:empty?)
end

def validate_headers(file, expected)
  table = CSV.read(file, headers: true)
  headers = table.headers
  missing = expected - headers
  extra = headers - expected
  [table, missing, extra]
end

def validate_file(file_name, cfg, canonical_tags)
  path = File.join(DATA_DIR, file_name)
  raise "Missing file: #{path}" unless File.exist?(path)

  table, missing_headers, extra_headers = validate_headers(path, cfg[:required])
  issues = []

  unless missing_headers.empty?
    issues << "Missing headers: #{missing_headers.join(', ')}"
  end

  unless extra_headers.empty?
    issues << "Unexpected headers: #{extra_headers.join(', ')}"
  end

  row_count = 0
  table.each_with_index do |row, index|
    row_count += 1
    line = index + 2

    cfg[:required].each do |col|
      value = row[col]
      if value.nil? || value.strip.empty?
        issues << "Row #{line}: empty value in column '#{col}'"
      end
    end

    tags = parse_tags(row[cfg[:tag_column]])
    if tags.empty?
      issues << "Row #{line}: no tags found in #{cfg[:tag_column]}"
      next
    end

    tier = row['quality_tier']&.strip
    unless VALID_TIERS.include?(tier)
      issues << "Row #{line}: invalid quality_tier '#{tier}'"
    end

    invalid = tags.reject { |tag| canonical_tags.include?(tag) }
    unless invalid.empty?
      issues << "Row #{line}: unknown tags #{invalid.join(', ')}"
    end

    if tags.uniq.length != tags.length
      issues << "Row #{line}: duplicate tags in #{cfg[:tag_column]}"
    end
  end

  [row_count, issues]
end

def main
  canonical_tags = read_canonical_tags
  total_issues = 0

  FILES.each do |file_name, cfg|
    row_count, issues = validate_file(file_name, cfg, canonical_tags)
    puts "#{file_name}: rows=#{row_count}"

    if issues.empty?
      puts '  OK'
      next
    end

    total_issues += issues.length
    issues.each { |issue| puts "  - #{issue}" }
  end

  if total_issues.positive?
    puts "Validation failed with #{total_issues} issue(s)."
    exit(1)
  end

  puts 'Validation passed.'
end

main
