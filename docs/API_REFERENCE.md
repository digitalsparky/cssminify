# API Reference

Complete API documentation for CSSminify2 with examples and detailed parameter descriptions.

## Table of Contents

- [Core API (Original)](#core-api-original)
- [Enhanced API (New Features)](#enhanced-api-new-features)
- [Configuration Classes](#configuration-classes)
- [Error Classes](#error-classes)
- [Examples](#examples)

## Core API (Original)

### CSSminify2.compress(source, line_length = 5000)

Basic CSS compression using YUI compressor algorithm.

**Parameters:**
- `source` (String|IO): CSS content to compress. Can be a string or any object that responds to `.read`
- `line_length` (Integer, optional): Maximum line length for output. Default: 5000

**Returns:** String - Compressed CSS

**Examples:**
```ruby
# String input
CSSminify2.compress('body { margin: 0; padding: 0; }')
# => "body{margin:0;padding:0}"

# File input
CSSminify2.compress(File.open('styles.css'))

# Custom line length
CSSminify2.compress(css_string, 200)
```

### CSSminify2#compress(source, line_length = 5000)

Instance method equivalent of the class method.

**Examples:**
```ruby
compressor = CSSminify2.new
compressor.compress('body { margin: 0; }')
# => "body{margin:0}"
```

## Enhanced API (New Features)

### CSSminify2.compress_enhanced(source, options = {})

Advanced CSS compression with configurable optimization features.

**Parameters:**
- `source` (String|IO): CSS content to compress
- `options` (Hash): Configuration options

**Options:**
- `merge_duplicate_selectors` (Boolean): Merge duplicate CSS selectors. Default: false
- `optimize_shorthand_properties` (Boolean): Optimize margin, padding, and other shorthand properties. Default: false
- `compress_css_variables` (Boolean): Optimize CSS custom properties (variables). Default: false
- `advanced_color_optimization` (Boolean): Enhanced color optimization with IE filter protection. Default: false
- `strict_error_handling` (Boolean): Enable strict CSS validation with detailed errors. Default: false
- `linebreakpos` (Integer): Maximum line length. Default: 5000

**Returns:** String - Compressed CSS

**Examples:**
```ruby
# Basic enhanced compression
CSSminify2.compress_enhanced(css, {
  optimize_shorthand_properties: true
})

# Full optimization
CSSminify2.compress_enhanced(css, {
  merge_duplicate_selectors: true,
  optimize_shorthand_properties: true,
  compress_css_variables: true,
  advanced_color_optimization: true
})

# With strict error handling
CSSminify2.compress_enhanced(css, {
  optimize_shorthand_properties: true,
  strict_error_handling: true
})
```

### CSSminify2.compress_with_stats(source, options = {})

Enhanced compression that returns detailed statistics about the compression process.

**Parameters:**
- `source` (String|IO): CSS content to compress
- `options` (Hash): Same options as `compress_enhanced`

**Returns:** Hash with keys:
- `compressed_css` (String): The compressed CSS result
- `statistics` (Hash): Detailed compression statistics

**Statistics Hash:**
- `original_size` (Integer): Original CSS size in characters
- `compressed_size` (Integer): Compressed CSS size in characters
- `compression_ratio` (Float): Compression ratio as percentage
- `selectors_merged` (Integer): Number of duplicate selectors merged
- `properties_optimized` (Integer): Number of properties optimized
- `colors_converted` (Integer): Number of colors converted
- `fallback_used` (Boolean): Whether fallback compression was used

**Examples:**
```ruby
stats = CSSminify2.compress_with_stats(css, {
  merge_duplicate_selectors: true,
  optimize_shorthand_properties: true
})

puts "Compressed: #{stats[:compressed_css]}"
puts "Original: #{stats[:statistics][:original_size]} chars"
puts "Compressed: #{stats[:statistics][:compressed_size]} chars"
puts "Ratio: #{stats[:statistics][:compression_ratio]}%"
puts "Selectors merged: #{stats[:statistics][:selectors_merged]}"
```

## Configuration Classes

### CSSminify2Enhanced::Configuration

Configuration object for enhanced compression features.

**Attributes:**
- `merge_duplicate_selectors` (Boolean)
- `optimize_shorthand_properties` (Boolean)
- `advanced_color_optimization` (Boolean)
- `preserve_ie_hacks` (Boolean)
- `compress_css_variables` (Boolean)
- `strict_error_handling` (Boolean)
- `generate_source_map` (Boolean)
- `statistics_enabled` (Boolean)

**Class Methods:**

#### Configuration.conservative
Returns a configuration with all enhanced features disabled (default behavior).

```ruby
config = CSSminify2Enhanced::Configuration.conservative
# All enhanced features disabled
```

#### Configuration.aggressive
Returns a configuration with all optimization features enabled.

```ruby
config = CSSminify2Enhanced::Configuration.aggressive
# merge_duplicate_selectors: true
# optimize_shorthand_properties: true
# advanced_color_optimization: true
# compress_css_variables: true
```

#### Configuration.modern
Returns aggressive configuration plus additional modern features.

```ruby
config = CSSminify2Enhanced::Configuration.modern
# All aggressive features plus:
# generate_source_map: true
# statistics_enabled: true
```

**Examples:**
```ruby
# Custom configuration
config = CSSminify2Enhanced::Configuration.new
config.merge_duplicate_selectors = true
config.optimize_shorthand_properties = true
config.strict_error_handling = true

compressor = CSSminify2Enhanced::Compressor.new(config)
result = compressor.compress(css)
```

### CSSminify2Enhanced::Compressor

Enhanced compressor class with configuration support.

#### Constructor
```ruby
compressor = CSSminify2Enhanced::Compressor.new(configuration)
```

**Parameters:**
- `configuration` (Configuration): Configuration object. Default: Conservative configuration

#### Methods

##### #compress(css, linebreakpos = 5000)
Compress CSS with the configured options.

**Parameters:**
- `css` (String): CSS to compress
- `linebreakpos` (Integer): Maximum line length

**Returns:** String - Compressed CSS

##### #statistics
Access compression statistics after calling `#compress`.

**Returns:** Hash - Statistics about the last compression

**Examples:**
```ruby
config = CSSminify2Enhanced::Configuration.aggressive
compressor = CSSminify2Enhanced::Compressor.new(config)

result = compressor.compress(css)
stats = compressor.statistics

puts "Compression ratio: #{stats[:compression_ratio]}%"
puts "Selectors merged: #{stats[:selectors_merged]}"
```

## Error Classes

### CSSminify2Enhanced::EnhancedCompressionError

Raised when enhanced compression fails in strict mode.

**Attributes:**
- `original_error` - The underlying error that caused the failure

**Example:**
```ruby
begin
  CSSminify2.compress_enhanced(malformed_css, {
    strict_error_handling: true
  })
rescue CSSminify2Enhanced::EnhancedCompressionError => e
  puts "Compression failed: #{e.message}"
  puts "Original error: #{e.original_error}"
end
```

### CSSminify2Enhanced::MalformedCSSError

Raised when CSS validation fails in strict mode.

**Attributes:**
- `css_errors` - Array of specific validation errors found

**Example:**
```ruby
begin
  CSSminify2.compress_enhanced(invalid_css, {
    strict_error_handling: true
  })
rescue CSSminify2Enhanced::MalformedCSSError => e
  puts "CSS validation failed: #{e.message}"
  e.css_errors.each { |error| puts "- #{error}" }
end
```

## Examples

### Basic Usage

```ruby
require 'cssminify2'

# Simple compression
css = "body { margin: 0; padding: 0; }"
compressed = CSSminify2.compress(css)
puts compressed  # => "body{margin:0;padding:0}"

# File compression
File.write('output.min.css', CSSminify2.compress(File.read('input.css')))
```

### Enhanced Features

```ruby
require 'cssminify2'

css = <<-CSS
  .btn { color: red; }
  .btn { background: blue; }
  .container { 
    margin: 10px 10px 10px 10px;
    padding: 0.0px 0rem 0vh;
  }
CSS

# Use enhanced features
result = CSSminify2.compress_enhanced(css, {
  merge_duplicate_selectors: true,
  optimize_shorthand_properties: true,
  advanced_color_optimization: true
})

puts result
# => ".btn{color:red;background:blue}.container{margin:10px;padding:0}"
```

### CSS Variables Optimization

```ruby
css_with_vars = <<-CSS
:root {
  --primary-color: #FF0000;
  --unused-var: blue;
  --single-use: 10px;
}

.component {
  color: var(--primary-color);
  margin: var(--single-use);
  padding: var(--primary-color);
}
CSS

result = CSSminify2.compress_enhanced(css_with_vars, {
  compress_css_variables: true,
  advanced_color_optimization: true
})

puts result
# Variables optimized: unused removed, single-use inlined, colors optimized
```

### Error Handling

```ruby
malformed_css = ".test { color: red .broken { }"

# Non-strict mode (default) - always succeeds with fallback
result = CSSminify2.compress_enhanced(malformed_css, {
  strict_error_handling: false
})
puts "Result: #{result}"  # Gets some result, possibly with warnings

# Strict mode - validates and throws errors
begin
  result = CSSminify2.compress_enhanced(malformed_css, {
    strict_error_handling: true
  })
rescue CSSminify2Enhanced::MalformedCSSError => e
  puts "Validation failed: #{e.message}"
  puts "Errors: #{e.css_errors.join(', ')}"
end
```

### Configuration Presets

```ruby
# Conservative (default) - no enhanced features
conservative_result = CSSminify2.compress_enhanced(css, 
  CSSminify2Enhanced::Configuration.conservative
)

# Aggressive - all optimizations enabled
aggressive_result = CSSminify2.compress_enhanced(css,
  CSSminify2Enhanced::Configuration.aggressive  
)

# Modern - aggressive plus additional features
modern_config = CSSminify2Enhanced::Configuration.modern
compressor = CSSminify2Enhanced::Compressor.new(modern_config)
modern_result = compressor.compress(css)
statistics = compressor.statistics
```

### Statistics and Monitoring

```ruby
stats = CSSminify2.compress_with_stats(large_css_file, {
  merge_duplicate_selectors: true,
  optimize_shorthand_properties: true,
  compress_css_variables: true
})

puts "=== Compression Report ==="
puts "Original size: #{stats[:statistics][:original_size]} chars"
puts "Compressed size: #{stats[:statistics][:compressed_size]} chars"
puts "Compression ratio: #{stats[:statistics][:compression_ratio].round(2)}%"
puts "Selectors merged: #{stats[:statistics][:selectors_merged]}"
puts "Properties optimized: #{stats[:statistics][:properties_optimized]}"
puts "Colors converted: #{stats[:statistics][:colors_converted]}"

if stats[:statistics][:fallback_used]
  puts "⚠️  Fallback compression was used"
end

# Save the compressed CSS
File.write('compressed.css', stats[:compressed_css])
```

### Integration with Build Tools

```ruby
# Rails Asset Pipeline
class EnhancedCSSCompressor
  def initialize(options = {})
    @config = CSSminify2Enhanced::Configuration.aggressive
    @config.strict_error_handling = false  # Graceful fallbacks in production
  end

  def compress(css)
    CSSminify2Enhanced::Compressor.new(@config).compress(css)
  rescue => e
    Rails.logger.warn "Enhanced CSS compression failed: #{e.message}"
    CSSminify2.compress(css)  # Fallback to basic compression
  end
end

# In config/application.rb
config.assets.css_compressor = EnhancedCSSCompressor.new
```

### Batch Processing

```ruby
class BatchProcessor
  def self.process_directory(input_dir, output_dir)
    Dir.glob("#{input_dir}/**/*.css").each do |file|
      css = File.read(file)
      
      stats = CSSminify2.compress_with_stats(css, {
        merge_duplicate_selectors: true,
        optimize_shorthand_properties: true,
        compress_css_variables: true
      })
      
      output_file = file.gsub(input_dir, output_dir).gsub('.css', '.min.css')
      FileUtils.mkdir_p(File.dirname(output_file))
      File.write(output_file, stats[:compressed_css])
      
      puts "#{file}: #{stats[:statistics][:compression_ratio].round(1)}% compression"
    end
  end
end

BatchProcessor.process_directory('src/css', 'dist/css')
```

## Performance Considerations

### Memory Usage
- Basic compression: Minimal memory overhead
- Enhanced features: ~2-3x memory usage during processing
- Large files (>1MB): Consider processing in chunks for memory efficiency

### Processing Speed
- Basic compression: ~2ms per 100KB
- Enhanced compression: ~5-8ms per 100KB
- Batch processing: Use persistent Compressor instances to avoid configuration overhead

### Best Practices
1. Start with conservative settings and gradually enable features
2. Use statistics to monitor compression effectiveness
3. Enable strict error handling in development, disable in production
4. Cache compressed results when possible
5. Test compression results thoroughly in your target browsers