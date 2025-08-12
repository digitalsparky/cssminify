# Advanced Usage Guide

This guide covers advanced usage patterns, optimization strategies, and best practices for CSSminify2 enhanced features.

## Table of Contents

- [Configuration Strategies](#configuration-strategies)
- [Optimization Patterns](#optimization-patterns)
- [Performance Tuning](#performance-tuning)
- [Integration Patterns](#integration-patterns)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Configuration Strategies

### Environment-Based Configuration

```ruby
# config/css_compression.rb
class CSSCompressionConfig
  def self.for_environment(env = Rails.env)
    case env.to_sym
    when :development
      {
        optimize_shorthand_properties: true,
        strict_error_handling: true  # Catch issues early
      }
    when :test
      {
        optimize_shorthand_properties: true,
        merge_duplicate_selectors: true,
        strict_error_handling: true
      }
    when :production
      {
        merge_duplicate_selectors: true,
        optimize_shorthand_properties: true,
        compress_css_variables: true,
        advanced_color_optimization: true,
        strict_error_handling: false  # Graceful fallbacks in production
      }
    else
      {}  # Conservative defaults
    end
  end
end

# Usage
config = CSSCompressionConfig.for_environment
result = CSSminify2.compress_enhanced(css, config)
```

### Project-Specific Configurations

```ruby
# For CSS framework projects (Bootstrap, Tailwind, etc.)
FRAMEWORK_CONFIG = {
  merge_duplicate_selectors: true,     # Frameworks often have duplicates
  optimize_shorthand_properties: true,
  compress_css_variables: false,       # Preserve framework variables
  advanced_color_optimization: true,
  strict_error_handling: false
}.freeze

# For single-page applications with CSS-in-JS
SPA_CONFIG = {
  merge_duplicate_selectors: false,    # CSS-in-JS usually unique
  optimize_shorthand_properties: true,
  compress_css_variables: true,        # Often many utility variables
  advanced_color_optimization: true,
  strict_error_handling: true         # Controlled environment
}.freeze

# For legacy projects with lots of technical debt
LEGACY_CONFIG = {
  merge_duplicate_selectors: false,    # May break cascade
  optimize_shorthand_properties: true, # Safe optimization
  compress_css_variables: false,       # May have unusual patterns
  advanced_color_optimization: false,  # May break IE filters
  strict_error_handling: false        # Lots of malformed CSS
}.freeze
```

## Optimization Patterns

### Selective Optimization by File Type

```ruby
class SmartCSSCompressor
  def self.compress_by_type(css, filename)
    config = case File.extname(filename)
    when '.variables.css', '.custom-props.css'
      { compress_css_variables: true }
    when '.grid.css', '.layout.css'
      { optimize_shorthand_properties: true }
    when '.components.css'
      { merge_duplicate_selectors: true }
    when '.utilities.css'
      { 
        optimize_shorthand_properties: true,
        compress_css_variables: true
      }
    else
      CSSminify2Enhanced::Configuration.aggressive
    end
    
    CSSminify2.compress_enhanced(css, config)
  end
end
```

### Progressive Optimization

```ruby
class ProgressiveCSSOptimizer
  def initialize
    @stats = []
  end
  
  def optimize_progressively(css)
    # Start conservative
    result = css
    config = {}
    
    # Apply optimizations progressively, measuring impact
    optimizations = [
      { optimize_shorthand_properties: true },
      { merge_duplicate_selectors: true },
      { compress_css_variables: true },
      { advanced_color_optimization: true }
    ]
    
    optimizations.each do |optimization|
      config.merge!(optimization)
      
      stats = CSSminify2.compress_with_stats(css, config)
      @stats << {
        optimization: optimization.keys.first,
        ratio: stats[:statistics][:compression_ratio],
        size: stats[:statistics][:compressed_size]
      }
      
      result = stats[:compressed_css]
    end
    
    { result: result, progression: @stats }
  end
end
```

### Conditional Optimization

```ruby
def smart_compress(css, options = {})
  # Analyze CSS to determine best optimizations
  analysis = analyze_css(css)
  
  config = {}
  
  # Enable selector merging only if we detect duplicates
  if analysis[:duplicate_selectors] > 5
    config[:merge_duplicate_selectors] = true
  end
  
  # Enable variable compression only if we have many variables
  if analysis[:css_variables] > 10
    config[:compress_css_variables] = true
  end
  
  # Always safe to enable
  config[:optimize_shorthand_properties] = true
  config[:advanced_color_optimization] = true
  
  CSSminify2.compress_enhanced(css, config.merge(options))
end

def analyze_css(css)
  {
    duplicate_selectors: css.scan(/([^{]+)\{[^}]*\}/).flatten
                           .group_by(&:strip)
                           .count { |_, v| v.length > 1 },
    css_variables: css.scan(/--[\w-]+/).uniq.count,
    size: css.length
  }
end
```

## Performance Tuning

### Batch Processing

```ruby
class BatchCSSProcessor
  def initialize(config = {})
    @compressor = CSSminify2Enhanced::Compressor.new(
      CSSminify2Enhanced::Configuration.new.tap do |c|
        config.each { |k, v| c.send("#{k}=", v) }
      end
    )
  end
  
  def process_files(file_patterns)
    results = {}
    total_savings = 0
    
    Dir.glob(file_patterns).each do |file|
      css = File.read(file)
      result = @compressor.compress(css)
      
      output_file = file.sub(/\.css$/, '.min.css')
      File.write(output_file, result)
      
      savings = css.length - result.length
      total_savings += savings
      
      results[file] = {
        original_size: css.length,
        compressed_size: result.length,
        savings: savings,
        ratio: (savings.to_f / css.length * 100).round(2)
      }
    end
    
    results.merge(total_savings: total_savings)
  end
end

# Usage
processor = BatchCSSProcessor.new({
  merge_duplicate_selectors: true,
  optimize_shorthand_properties: true
})

results = processor.process_files(['app/assets/stylesheets/**/*.css'])
puts "Total bytes saved: #{results[:total_savings]}"
```

### Memory-Efficient Processing

```ruby
class StreamingCSSProcessor
  def self.process_large_file(input_path, output_path, config = {})
    # For very large CSS files, process in chunks if needed
    css = File.read(input_path)
    
    if css.length > 1_000_000  # 1MB threshold
      # Process in sections for memory efficiency
      sections = css.split(/(?<=\})/)
      compressed_sections = []
      
      sections.each_slice(100) do |section_batch|
        batch_css = section_batch.join('')
        compressed = CSSminify2.compress_enhanced(batch_css, config)
        compressed_sections << compressed
      end
      
      result = compressed_sections.join('')
    else
      result = CSSminify2.compress_enhanced(css, config)
    end
    
    File.write(output_path, result)
  end
end
```

## Integration Patterns

### Rails Asset Pipeline Integration

```ruby
# config/initializers/css_compression.rb
class EnhancedCSSCompressor
  def initialize(options = {})
    @options = {
      merge_duplicate_selectors: true,
      optimize_shorthand_properties: true,
      compress_css_variables: Rails.env.production?,
      advanced_color_optimization: true
    }.merge(options)
  end
  
  def compress(css)
    CSSminify2.compress_enhanced(css, @options)
  rescue => e
    Rails.logger.warn "CSS compression failed: #{e.message}"
    # Fallback to basic compression
    CSSminify2.compress(css)
  end
end

# config/application.rb
config.assets.css_compressor = EnhancedCSSCompressor.new
```

### Webpack Integration via Ruby Bridge

```ruby
# lib/webpack_css_compressor.rb
class WebpackCSSCompressor
  def self.compress(css, options_json = '{}')
    options = JSON.parse(options_json, symbolize_names: true)
    
    stats = CSSminify2.compress_with_stats(css, options)
    
    # Return JSON for JavaScript consumption
    {
      css: stats[:compressed_css],
      stats: stats[:statistics]
    }.to_json
  rescue => e
    {
      css: css,  # Return original on error
      error: e.message,
      stats: { fallback_used: true }
    }.to_json
  end
end
```

### Jekyll Plugin

```ruby
# _plugins/enhanced_css_minifier.rb
module Jekyll
  class EnhancedCSSMinifier < Jekyll::Generator
    safe true
    priority :low
    
    def generate(site)
      config = site.config['cssminify'] || {}
      options = {
        merge_duplicate_selectors: config['merge_selectors'],
        optimize_shorthand_properties: config['optimize_shorthand'],
        compress_css_variables: config['compress_variables']
      }.compact
      
      site.static_files.each do |file|
        next unless file.extname == '.css'
        
        css = File.read(file.path)
        compressed = CSSminify2.compress_enhanced(css, options)
        File.write(file.path, compressed)
      end
    end
  end
end
```

### Gulp Integration

```ruby
# tools/css_compressor.rb
#!/usr/bin/env ruby
require 'cssminify2'
require 'json'

# Read from STDIN, write to STDOUT for Gulp integration
input = STDIN.read
options = JSON.parse(ARGV[0] || '{}', symbolize_names: true)

begin
  stats = CSSminify2.compress_with_stats(input, options)
  
  result = {
    css: stats[:compressed_css],
    originalSize: stats[:statistics][:original_size],
    compressedSize: stats[:statistics][:compressed_size],
    ratio: stats[:statistics][:compression_ratio],
    success: true
  }
  
  puts JSON.generate(result)
rescue => e
  puts JSON.generate({
    css: input,
    error: e.message,
    success: false
  })
  exit 1
end
```

## Troubleshooting

### Debug Mode for Complex Issues

```ruby
class CSSDebugger
  def self.debug_compression(css, options = {})
    puts "=== CSS COMPRESSION DEBUG ==="
    puts "Original size: #{css.length} characters"
    puts "Configuration: #{options.inspect}"
    puts ""
    
    # Test each optimization individually
    optimizations = [
      :merge_duplicate_selectors,
      :optimize_shorthand_properties,
      :compress_css_variables,
      :advanced_color_optimization
    ]
    
    results = {}
    
    optimizations.each do |opt|
      test_config = { opt => true }
      
      begin
        stats = CSSminify2.compress_with_stats(css, test_config)
        results[opt] = {
          success: true,
          size: stats[:statistics][:compressed_size],
          ratio: stats[:statistics][:compression_ratio]
        }
        puts "✅ #{opt}: #{results[opt][:ratio].round(2)}% compression"
      rescue => e
        results[opt] = {
          success: false,
          error: e.message
        }
        puts "❌ #{opt}: FAILED - #{e.message}"
      end
    end
    
    # Test full configuration
    begin
      full_stats = CSSminify2.compress_with_stats(css, options)
      puts ""
      puts "🚀 Full compression: #{full_stats[:statistics][:compression_ratio].round(2)}%"
      puts "Final size: #{full_stats[:statistics][:compressed_size]} characters"
      
      if full_stats[:statistics][:fallback_used]
        puts "⚠️  Fallback compression was used"
      end
    rescue => e
      puts "❌ Full compression failed: #{e.message}"
    end
    
    results
  end
end

# Usage
CSSDebugger.debug_compression(problematic_css, {
  merge_duplicate_selectors: true,
  optimize_shorthand_properties: true
})
```

### Validation and Recovery

```ruby
def safe_compress_with_validation(css, options = {})
  # Pre-compression validation
  validator = CSSValidator.new(css)
  warnings = validator.validate
  
  if warnings.any?
    puts "⚠️  CSS warnings detected:"
    warnings.each { |w| puts "  - #{w}" }
  end
  
  # Attempt compression with error recovery
  begin
    # Try strict mode first
    result = CSSminify2.compress_enhanced(css, options.merge(
      strict_error_handling: true
    ))
    
    puts "✅ Strict compression successful"
    result
  rescue CSSminify2Enhanced::MalformedCSSError => e
    puts "⚠️  CSS validation failed, trying non-strict mode"
    puts "Errors: #{e.css_errors.join(', ')}"
    
    # Fallback to non-strict
    CSSminify2.compress_enhanced(css, options.merge(
      strict_error_handling: false
    ))
  rescue => e
    puts "❌ Enhanced compression failed: #{e.message}"
    puts "Using basic compression"
    
    # Ultimate fallback
    CSSminify2.compress(css)
  end
end

class CSSValidator
  def initialize(css)
    @css = css
  end
  
  def validate
    warnings = []
    
    # Check for potential issues
    warnings << "Many duplicate selectors detected" if duplicate_selectors > 20
    warnings << "Very large file (>500KB)" if @css.length > 500_000
    warnings << "Many CSS variables (>50)" if css_variables > 50
    warnings << "Potentially malformed CSS" if syntax_issues?
    
    warnings
  end
  
  private
  
  def duplicate_selectors
    @css.scan(/([^{]+)\{/).flatten.group_by(&:strip).count { |_, v| v.length > 1 }
  end
  
  def css_variables
    @css.scan(/--[\w-]+/).uniq.count
  end
  
  def syntax_issues?
    @css.count('{') != @css.count('}') ||
    @css.scan(/"/).length.odd? ||
    @css.scan(/'/).length.odd?
  end
end
```

## Best Practices

### 1. **Start Conservative, Scale Up**
```ruby
# Begin with safe optimizations
initial_config = {
  optimize_shorthand_properties: true
}

# Add features as you gain confidence
full_config = {
  merge_duplicate_selectors: true,
  optimize_shorthand_properties: true,
  compress_css_variables: true,
  advanced_color_optimization: true
}
```

### 2. **Use Statistics for Optimization**
```ruby
def optimize_build_process(css_files)
  css_files.each do |file|
    css = File.read(file)
    
    stats = CSSminify2.compress_with_stats(css, full_config)
    
    # Only use advanced features if they provide significant benefit
    if stats[:statistics][:compression_ratio] < 30
      puts "⚠️  #{file}: Low compression ratio, consider reviewing CSS structure"
    end
    
    if stats[:statistics][:fallback_used]
      puts "🚨 #{file}: Fallback used, may need manual review"
    end
  end
end
```

### 3. **Environment-Specific Configurations**
- **Development**: Enable `strict_error_handling` to catch issues early
- **Testing**: Use aggressive optimization to test edge cases
- **Production**: Use balanced configuration with graceful fallbacks

### 4. **Monitor Compression Performance**
```ruby
class CompressionMonitor
  def self.monitor(css, options = {})
    start_time = Time.now
    stats = CSSminify2.compress_with_stats(css, options)
    end_time = Time.now
    
    {
      result: stats[:compressed_css],
      performance: {
        compression_time: (end_time - start_time) * 1000, # ms
        original_size: stats[:statistics][:original_size],
        compressed_size: stats[:statistics][:compressed_size],
        compression_ratio: stats[:statistics][:compression_ratio],
        compression_speed: stats[:statistics][:original_size] / (end_time - start_time) # bytes/sec
      }
    }
  end
end
```

### 5. **Testing Strategy**
```ruby
# Test your CSS compression in your test suite
RSpec.describe 'CSS Compression' do
  it 'compresses CSS without breaking functionality' do
    original_css = File.read('app/assets/stylesheets/application.css')
    
    compressed = CSSminify2.compress_enhanced(original_css, production_config)
    
    expect(compressed.length).to be < original_css.length
    expect(compressed).to include('.main-header')  # Key selectors preserved
    expect(compressed).not_to include('/* comments */')  # Comments removed
  end
  
  it 'handles malformed CSS gracefully' do
    malformed_css = '.test { color: red .broken { }'
    
    expect {
      CSSminify2.compress_enhanced(malformed_css, {
        strict_error_handling: false
      })
    }.not_to raise_error
  end
end
```

This advanced usage guide covers the most common patterns and strategies for getting the most out of CSSminify2's enhanced features. Remember to always test thoroughly when adopting new optimization settings!