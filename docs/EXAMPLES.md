# Examples & Usage Patterns

Real-world examples and common usage patterns for CSSminify2.

## Table of Contents

- [Basic Usage Examples](#basic-usage-examples)
- [Enhanced Feature Examples](#enhanced-feature-examples)
- [Framework Integration Examples](#framework-integration-examples)
- [Build Tool Examples](#build-tool-examples)
- [Error Handling Examples](#error-handling-examples)
- [Performance Optimization Examples](#performance-optimization-examples)

## Basic Usage Examples

### Simple CSS Compression

```ruby
require 'cssminify2'

# Basic string compression
css = "body { margin: 0; padding: 0; }"
result = CSSminify2.compress(css)
puts result
# Output: "body{margin:0;padding:0}"

# File compression
original_css = File.read('styles.css')
compressed_css = CSSminify2.compress(original_css)
File.write('styles.min.css', compressed_css)
```

### With Line Length Control

```ruby
long_css = ".very-long-selector { background: url('very-long-url.png'); }"

# Default line length (5000 characters)
default_result = CSSminify2.compress(long_css)

# Custom line length (80 characters)
short_lines = CSSminify2.compress(long_css, 80)
puts "Short lines result:\n#{short_lines}"
```

### Instance-Based Usage

```ruby
compressor = CSSminify2.new

css_files = ['main.css', 'components.css', 'utilities.css']
css_files.each do |file|
  css = File.read(file)
  compressed = compressor.compress(css)
  File.write(file.gsub('.css', '.min.css'), compressed)
end
```

## Enhanced Feature Examples

### Duplicate Selector Merging

```ruby
css_with_duplicates = <<-CSS
.btn { color: red; }
.card { background: white; }
.btn { background: blue; }
.btn { color: green; }  /* This will override the red */
.card { border: 1px solid gray; }
CSS

result = CSSminify2.compress_enhanced(css_with_duplicates, {
  merge_duplicate_selectors: true
})

puts result
# Output: ".btn{color:green;background:blue}.card{background:white;border:1px solid gray}"

# Note: Properties are merged correctly, with later declarations taking precedence
```

### Shorthand Property Optimization

```ruby
css_with_longhand = <<-CSS
.container {
  margin: 10px 10px 10px 10px;
  padding: 20px 20px;
  border: 1px solid red 1px;
  background: none repeat scroll 0 0 #ffffff;
}

.grid {
  flex: 1 1 auto;
  grid-gap: 15px 15px;
}
CSS

result = CSSminify2.compress_enhanced(css_with_longhand, {
  optimize_shorthand_properties: true
})

puts result
# Output includes optimizations like:
# margin: 10px (instead of 10px 10px 10px 10px)
# padding: 20px (instead of 20px 20px)
# gap: 15px (instead of grid-gap: 15px 15px)
```

### CSS Variables Optimization

```ruby
css_with_variables = <<-CSS
:root {
  --primary-color: #3366CC;
  --secondary-color: #FF6633;
  --unused-variable: #DEAD00;
  --single-use-spacing: 8px;
  --very-long-variable-name-for-padding: 16px;
}

.component-one {
  color: var(--primary-color);
  background: var(--secondary-color);
  margin: var(--single-use-spacing);  /* Only used once */
  padding: var(--very-long-variable-name-for-padding);
}

.component-two {
  color: var(--primary-color);
  padding: var(--very-long-variable-name-for-padding);
}
CSS

result = CSSminify2.compress_enhanced(css_with_variables, {
  compress_css_variables: true,
  advanced_color_optimization: true
})

puts result
# Output optimizes variables:
# - Removes --unused-variable (never used)
# - Inlines --single-use-spacing (used only once)
# - Shortens --very-long-variable-name-for-padding to --v1
# - Converts #3366CC to #36C, #FF6633 to #f63
```

### Modern CSS Layout Optimization

```ruby
modern_css = <<-CSS
.layout {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  grid-gap: 20px 20px;
  justify-content: flex-start;
  align-items: flex-start;
}

.flex-container {
  display: flex;
  flex: 1 1 auto;
  justify-content: flex-end;
  align-items: center;
  transform: translate(0, 0) scale(1, 1) rotate(0deg);
}
CSS

result = CSSminify2.compress_enhanced(modern_css, {
  optimize_shorthand_properties: true
})

puts result
# Output includes modern optimizations:
# gap: 20px (instead of grid-gap: 20px 20px)
# justify-content: start (instead of flex-start)
# flex: 1 (instead of 1 1 auto)
# transform: translate(0) scale(1) (removing unnecessary values)
```

### Color Optimization

```ruby
css_with_colors = <<-CSS
.colors {
  color: #FF0000;
  background: #00FF00;
  border-color: #0000FF;
  box-shadow: 0 0 10px rgba(255, 0, 0, 0.5);
}

.ie-filter {
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#FF0000', endColorstr='#00FF00');
}
CSS

result = CSSminify2.compress_enhanced(css_with_colors, {
  advanced_color_optimization: true
})

puts result
# Output:
# - #FF0000 → red (shorter)
# - #00FF00 → lime
# - #0000FF → blue  
# - IE filter properties are protected from color conversion
```

## Framework Integration Examples

### Rails Application

```ruby
# app/lib/enhanced_css_compressor.rb
class EnhancedCSSCompressor
  def initialize(options = {})
    @base_config = {
      merge_duplicate_selectors: true,
      optimize_shorthand_properties: true,
      advanced_color_optimization: true
    }
    
    # Environment-specific overrides
    @config = case Rails.env
    when 'development'
      @base_config.merge(
        strict_error_handling: true  # Catch issues early
      )
    when 'production'
      @base_config.merge(
        compress_css_variables: true,  # More aggressive in production
        strict_error_handling: false   # Graceful fallbacks
      )
    else
      @base_config
    end
  end

  def compress(css)
    stats = CSSminify2.compress_with_stats(css, @config)
    
    # Log compression metrics
    Rails.logger.info "CSS compressed: #{stats[:statistics][:compression_ratio].round(2)}% reduction"
    
    if stats[:statistics][:fallback_used]
      Rails.logger.warn "CSS compression used fallback mode"
    end
    
    stats[:compressed_css]
  rescue => e
    Rails.logger.error "CSS compression failed: #{e.message}"
    # Ultimate fallback to basic compression
    CSSminify2.compress(css)
  end
end

# config/application.rb
config.assets.css_compressor = EnhancedCSSCompressor.new
```

### Sinatra Application

```ruby
require 'sinatra'
require 'cssminify2'

class CSSMinifyApp < Sinatra::Base
  configure :production do
    # Enable CSS compression for production
    set :compress_css, true
    set :css_compressor_options, {
      merge_duplicate_selectors: true,
      optimize_shorthand_properties: true,
      compress_css_variables: true
    }
  end

  get '/styles.css' do
    content_type 'text/css'
    
    css = File.read('public/styles.css')
    
    if settings.compress_css?
      stats = CSSminify2.compress_with_stats(css, settings.css_compressor_options)
      
      # Add compression info as comment in development
      if development?
        compression_info = "/* Compressed: #{stats[:statistics][:compression_ratio].round(2)}% reduction */"
        "#{compression_info}\n#{stats[:compressed_css]}"
      else
        stats[:compressed_css]
      end
    else
      css
    end
  end
end
```

### Jekyll Site

```ruby
# _plugins/css_optimizer.rb
require 'cssminify2'

module Jekyll
  class CSSOptimizer < Generator
    safe true
    priority :low

    def generate(site)
      return unless site.config['css_compression']
      
      config = site.config['css_compression']
      options = {
        merge_duplicate_selectors: config['merge_selectors'] || false,
        optimize_shorthand_properties: config['optimize_shorthand'] || true,
        compress_css_variables: config['compress_variables'] || false,
        advanced_color_optimization: config['advanced_colors'] || true
      }

      # Process CSS files
      site.static_files.select { |f| f.extname == '.css' }.each do |file|
        optimize_css_file(file, options, site)
      end
      
      # Process CSS in pages and posts
      (site.pages + site.posts.docs).each do |page|
        optimize_inline_css(page, options) if page.content.include?('<style>')
      end
    end

    private

    def optimize_css_file(file, options, site)
      css = File.read(file.path)
      
      stats = CSSminify2.compress_with_stats(css, options)
      File.write(file.path, stats[:compressed_css])
      
      Jekyll.logger.info "CSS:", "#{file.relative_path} compressed #{stats[:statistics][:compression_ratio].round(1)}%"
    end

    def optimize_inline_css(page, options)
      page.content = page.content.gsub(/<style[^>]*>(.*?)<\/style>/m) do |match|
        style_tag = match
        css_content = $1
        
        begin
          compressed = CSSminify2.compress_enhanced(css_content, options)
          style_tag.sub(css_content, compressed)
        rescue => e
          Jekyll.logger.warn "CSS:", "Failed to compress inline CSS in #{page.relative_path}: #{e.message}"
          match  # Return original on error
        end
      end
    end
  end
end
```

## Build Tool Examples

### Rake Task

```ruby
# lib/tasks/css_compression.rake
namespace :css do
  desc "Compress CSS files with enhanced features"
  task :compress do
    require 'cssminify2'
    
    css_files = Dir.glob('app/assets/stylesheets/**/*.css')
    total_original = 0
    total_compressed = 0
    
    css_files.each do |file|
      next if file.end_with?('.min.css')  # Skip already minified files
      
      css = File.read(file)
      
      stats = CSSminify2.compress_with_stats(css, {
        merge_duplicate_selectors: true,
        optimize_shorthand_properties: true,
        compress_css_variables: true,
        advanced_color_optimization: true
      })
      
      # Create minified version
      min_file = file.sub('.css', '.min.css')
      File.write(min_file, stats[:compressed_css])
      
      # Track totals
      total_original += stats[:statistics][:original_size]
      total_compressed += stats[:statistics][:compressed_size]
      
      puts "#{file} → #{min_file} (#{stats[:statistics][:compression_ratio].round(2)}%)"
    end
    
    overall_ratio = ((total_original - total_compressed).to_f / total_original * 100).round(2)
    puts "\nOverall compression: #{overall_ratio}% (#{total_original} → #{total_compressed} bytes)"
  end
  
  desc "Validate CSS compression results"
  task :validate do
    require 'cssminify2'
    
    css_files = Dir.glob('app/assets/stylesheets/**/*.css')
    issues = []
    
    css_files.each do |file|
      css = File.read(file)
      
      begin
        # Test with strict validation
        CSSminify2.compress_enhanced(css, {
          merge_duplicate_selectors: true,
          optimize_shorthand_properties: true,
          strict_error_handling: true
        })
        puts "✓ #{file}"
      rescue => e
        issues << "✗ #{file}: #{e.message}"
        puts "✗ #{file}: #{e.message}"
      end
    end
    
    if issues.any?
      puts "\n#{issues.length} files have issues:"
      issues.each { |issue| puts "  #{issue}" }
      exit 1
    else
      puts "\n✓ All CSS files validated successfully"
    end
  end
end
```

### Guard Integration

```ruby
# Guardfile
require 'cssminify2'

guard :shell do
  watch(%r{^app/assets/stylesheets/(.+\.css)$}) do |m|
    input_file = m[0]
    output_file = input_file.sub('.css', '.min.css')
    
    css = File.read(input_file)
    
    begin
      stats = CSSminify2.compress_with_stats(css, {
        merge_duplicate_selectors: true,
        optimize_shorthand_properties: true,
        compress_css_variables: ENV['RAILS_ENV'] == 'production'
      })
      
      File.write(output_file, stats[:compressed_css])
      
      puts "CSS compressed: #{input_file} → #{output_file} (#{stats[:statistics][:compression_ratio].round(2)}%)"
      
      if stats[:statistics][:fallback_used]
        puts "  ⚠️  Fallback compression was used"
      end
      
    rescue => e
      puts "CSS compression failed for #{input_file}: #{e.message}"
    end
  end
end
```

### Docker Build Integration

```dockerfile
# Dockerfile
FROM ruby:3.1

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# Compress CSS as part of build process
RUN ruby -e "
require 'cssminify2'

Dir.glob('public/css/**/*.css').each do |file|
  next if file.end_with?('.min.css')
  
  css = File.read(file)
  stats = CSSminify2.compress_with_stats(css, {
    merge_duplicate_selectors: true,
    optimize_shorthand_properties: true,
    compress_css_variables: true,
    advanced_color_optimization: true
  })
  
  File.write(file.sub('.css', '.min.css'), stats[:compressed_css])
  puts \"Compressed: #{file} (#{stats[:statistics][:compression_ratio].round(2)}%)\"
end
"

CMD ['ruby', 'app.rb']
```

## Error Handling Examples

### Graceful Fallbacks

```ruby
def safe_css_compression(css, options = {})
  begin
    # Try enhanced compression first
    stats = CSSminify2.compress_with_stats(css, options.merge(
      strict_error_handling: true
    ))
    
    {
      css: stats[:compressed_css],
      method: 'enhanced',
      stats: stats[:statistics],
      success: true
    }
  rescue CSSminify2Enhanced::MalformedCSSError => e
    puts "CSS validation failed: #{e.message}"
    puts "Errors: #{e.css_errors.join(', ')}"
    
    # Try enhanced compression without strict validation
    begin
      result = CSSminify2.compress_enhanced(css, options.merge(
        strict_error_handling: false
      ))
      
      {
        css: result,
        method: 'enhanced_fallback',
        warnings: ['CSS validation failed, used non-strict mode'],
        success: true
      }
    rescue => fallback_error
      puts "Enhanced compression failed: #{fallback_error.message}"
      
      # Final fallback to basic compression
      basic_result = CSSminify2.compress(css)
      
      {
        css: basic_result,
        method: 'basic_fallback',
        warnings: ['Enhanced compression failed, used basic compression'],
        success: true
      }
    end
  rescue => e
    puts "Unexpected error: #{e.message}"
    
    # Always ensure we return something
    {
      css: css,  # Return original CSS if all else fails
      method: 'none',
      error: e.message,
      success: false
    }
  end
end

# Usage
result = safe_css_compression(problematic_css, {
  merge_duplicate_selectors: true,
  optimize_shorthand_properties: true
})

puts "Compression method used: #{result[:method]}"
puts "Result: #{result[:css]}"
puts "Warnings: #{result[:warnings].join(', ')}" if result[:warnings]
```

### Development vs Production Error Handling

```ruby
class EnvironmentAwareCSSCompressor
  def initialize(environment = Rails.env)
    @environment = environment
    @config = compression_config_for_environment
  end

  def compress(css)
    if development_or_test?
      # Strict validation in development to catch issues early
      compress_with_strict_validation(css)
    else
      # Graceful fallbacks in production
      compress_with_fallbacks(css)
    end
  end

  private

  def development_or_test?
    %w[development test].include?(@environment)
  end

  def compression_config_for_environment
    base_config = {
      optimize_shorthand_properties: true,
      merge_duplicate_selectors: true
    }

    case @environment
    when 'development'
      base_config.merge(strict_error_handling: true)
    when 'test'
      base_config.merge(
        strict_error_handling: true,
        compress_css_variables: true  # Test more aggressive compression
      )
    when 'production'
      base_config.merge(
        compress_css_variables: true,
        advanced_color_optimization: true,
        strict_error_handling: false
      )
    else
      base_config
    end
  end

  def compress_with_strict_validation(css)
    CSSminify2.compress_enhanced(css, @config)
  rescue CSSminify2Enhanced::MalformedCSSError => e
    error_message = "CSS Validation Error:\n"
    error_message += "#{e.message}\n"
    error_message += "Specific issues:\n"
    e.css_errors.each { |error| error_message += "  - #{error}\n" }
    error_message += "\nPlease fix these CSS issues before proceeding."
    
    raise StandardError, error_message
  end

  def compress_with_fallbacks(css)
    # Production: try enhanced, fallback gracefully
    CSSminify2.compress_enhanced(css, @config)
  rescue => e
    Rails.logger.warn "Enhanced CSS compression failed: #{e.message}"
    
    # Log the error but continue with basic compression
    Rails.logger.warn "Falling back to basic CSS compression"
    CSSminify2.compress(css)
  end
end
```

## Performance Optimization Examples

### Benchmarking and Profiling

```ruby
require 'benchmark'
require 'cssminify2'

def benchmark_css_compression(css_files)
  puts "CSS Compression Benchmarks"
  puts "=" * 50
  
  css_files.each do |file|
    css = File.read(file)
    puts "\nFile: #{file} (#{css.length} characters)"
    
    Benchmark.bm(20) do |x|
      basic_result = nil
      enhanced_result = nil
      
      x.report("Basic compression:") do
        basic_result = CSSminify2.compress(css)
      end
      
      x.report("Enhanced (safe):") do
        enhanced_result = CSSminify2.compress_enhanced(css, {
          optimize_shorthand_properties: true
        })
      end
      
      x.report("Enhanced (full):") do
        CSSminify2.compress_enhanced(css, {
          merge_duplicate_selectors: true,
          optimize_shorthand_properties: true,
          compress_css_variables: true,
          advanced_color_optimization: true
        })
      end
      
      # Show compression ratios
      basic_ratio = ((css.length - basic_result.length).to_f / css.length * 100).round(2)
      enhanced_ratio = ((css.length - enhanced_result.length).to_f / css.length * 100).round(2)
      
      puts "  Basic ratio: #{basic_ratio}%"
      puts "  Enhanced ratio: #{enhanced_ratio}%"
      puts "  Improvement: #{(enhanced_ratio - basic_ratio).round(2)}%"
    end
  end
end

# Run benchmarks
css_files = Dir.glob('test/fixtures/**/*.css')
benchmark_css_compression(css_files)
```

### Memory-Efficient Processing

```ruby
class MemoryEfficientCSSProcessor
  def self.process_large_file(input_file, output_file, options = {})
    # Read file size
    file_size = File.size(input_file)
    puts "Processing #{input_file} (#{file_size} bytes)"
    
    if file_size > 1_000_000  # 1MB threshold
      process_in_chunks(input_file, output_file, options)
    else
      process_normally(input_file, output_file, options)
    end
  end

  private

  def self.process_in_chunks(input_file, output_file, options)
    css = File.read(input_file)
    
    # Split CSS into logical sections (at rule boundaries)
    sections = css.split(/(?<=\})\s*(?=\.|#|@|\w)/)
    
    compressed_sections = []
    
    sections.each_slice(50) do |section_batch|  # Process 50 rules at a time
      batch_css = section_batch.join('')
      
      begin
        compressed = CSSminify2.compress_enhanced(batch_css, options)
        compressed_sections << compressed
      rescue => e
        puts "Warning: Batch compression failed, using basic compression: #{e.message}"
        compressed = CSSminify2.compress(batch_css)
        compressed_sections << compressed
      end
    end
    
    # Combine all compressed sections
    final_result = compressed_sections.join('')
    File.write(output_file, final_result)
    
    puts "Processed in #{sections.length} sections, #{compressed_sections.length} batches"
  end

  def self.process_normally(input_file, output_file, options)
    css = File.read(input_file)
    
    stats = CSSminify2.compress_with_stats(css, options)
    File.write(output_file, stats[:compressed_css])
    
    puts "Compressed: #{stats[:statistics][:compression_ratio].round(2)}% reduction"
  end
end

# Usage
MemoryEfficientCSSProcessor.process_large_file(
  'large-framework.css',
  'large-framework.min.css',
  {
    merge_duplicate_selectors: true,
    optimize_shorthand_properties: true,
    compress_css_variables: true
  }
)
```

### Caching and Persistent Compressors

```ruby
class CachingCSSCompressor
  def initialize(cache_dir = 'tmp/css_cache')
    @cache_dir = cache_dir
    @compressor = CSSminify2Enhanced::Compressor.new(
      CSSminify2Enhanced::Configuration.aggressive
    )
    
    FileUtils.mkdir_p(@cache_dir)
  end

  def compress(css)
    # Generate cache key from CSS content
    cache_key = Digest::SHA256.hexdigest(css)
    cache_file = File.join(@cache_dir, "#{cache_key}.css")
    
    # Return cached result if available
    if File.exist?(cache_file)
      puts "Using cached compression for #{cache_key[0..7]}..."
      return File.read(cache_file)
    end
    
    # Compress and cache result
    result = @compressor.compress(css)
    File.write(cache_file, result)
    
    puts "Compressed and cached #{cache_key[0..7]}..."
    result
  end

  def cache_stats
    cached_files = Dir.glob(File.join(@cache_dir, '*.css'))
    total_size = cached_files.sum { |f| File.size(f) }
    
    {
      cached_files: cached_files.length,
      total_cache_size: total_size,
      cache_directory: @cache_dir
    }
  end

  def clear_cache
    FileUtils.rm_rf(@cache_dir)
    FileUtils.mkdir_p(@cache_dir)
    puts "CSS compression cache cleared"
  end
end

# Usage
compressor = CachingCSSCompressor.new

# Process multiple files with caching
css_files = Dir.glob('assets/**/*.css')
css_files.each do |file|
  css = File.read(file)
  compressed = compressor.compress(css)  # Will use cache on repeat calls
  
  output_file = file.sub('.css', '.min.css')
  File.write(output_file, compressed)
end

puts "Cache stats: #{compressor.cache_stats}"
```

These examples demonstrate the flexibility and power of CSSminify2's enhanced features across different use cases, from simple compression to complex build pipeline integration.