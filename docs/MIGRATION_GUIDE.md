# Migration Guide

Complete guide for migrating to CSSminify2 v2.x and adopting enhanced features.

## Table of Contents

- [From v1.x to v2.x](#from-v1x-to-v2x)
- [Adopting Enhanced Features](#adopting-enhanced-features)
- [Framework Integration Updates](#framework-integration-updates)
- [Build Tool Integration](#build-tool-integration)
- [Troubleshooting Migration Issues](#troubleshooting-migration-issues)

## From v1.x to v2.x

### Zero Breaking Changes

**Good news!** CSSminify2 v2.x is 100% backward compatible with v1.x. Your existing code will continue to work exactly as before.

```ruby
# This code works identically in v1.x and v2.x
CSSminify2.compress(css_string)
CSSminify2.compress(css_string, 200)  # With line length

compressor = CSSminify2.new
compressor.compress(css_string)
```

### What's New in v2.x

- **Enhanced compression engine** - Up to 63% compression ratios
- **Modern CSS support** - Grid, Flexbox, Custom Properties
- **Configurable optimizations** - Enable only what you need
- **Detailed statistics** - Performance insights and metrics
- **Robust error handling** - Production-ready reliability
- **Comprehensive test suite** - 95.8% YUI compatibility

### Dependency Updates

If you're upgrading from v1.x, you may need to update your dependencies:

```ruby
# Gemfile - Old
gem 'rspec', '~> 2.7'
source 'http://rubygems.org'

# Gemfile - New (v2.x)
gem 'rspec', '~> 3.12'  # Updated for modern Ruby compatibility
source 'https://rubygems.org'  # HTTPS for security
```

## Adopting Enhanced Features

### Phase 1: Safe Optimizations

Start with the safest optimizations that provide good benefits with minimal risk:

```ruby
# Replace this
result = CSSminify2.compress(css)

# With this
result = CSSminify2.compress_enhanced(css, {
  optimize_shorthand_properties: true
})
```

**Benefits:**
- Optimizes `margin: 10px 10px 10px 10px` → `margin: 10px`
- Converts `padding: 0.0px 0rem 0vh` → `padding: 0`
- Zero risk of breaking existing CSS functionality

### Phase 2: Selector Optimization  

Add selector merging for additional compression:

```ruby
result = CSSminify2.compress_enhanced(css, {
  optimize_shorthand_properties: true,
  merge_duplicate_selectors: true  # New feature
})
```

**Benefits:**
- Merges `.btn { color: red; } .btn { background: blue; }` → `.btn { color: red; background: blue; }`
- Handles cascade order correctly
- Works with media queries and keyframes

**Testing Recommendation:**
```ruby
# Compare before and after
original_result = CSSminify2.compress(css)
enhanced_result = CSSminify2.compress_enhanced(css, {
  optimize_shorthand_properties: true,
  merge_duplicate_selectors: true
})

puts "Original: #{original_result.length} chars"
puts "Enhanced: #{enhanced_result.length} chars"
puts "Improvement: #{((original_result.length - enhanced_result.length).to_f / original_result.length * 100).round(2)}%"
```

### Phase 3: Full Optimization

Enable all optimizations for maximum compression:

```ruby
result = CSSminify2.compress_enhanced(css, {
  merge_duplicate_selectors: true,
  optimize_shorthand_properties: true,
  compress_css_variables: true,      # New feature
  advanced_color_optimization: true  # New feature
})
```

**Additional Benefits:**
- Optimizes CSS custom properties (variables)
- Enhanced color optimization with IE filter protection
- Modern CSS layout optimizations (Grid, Flexbox)

### Phase 4: Statistics and Monitoring

Add compression monitoring to your build process:

```ruby
stats = CSSminify2.compress_with_stats(css, {
  merge_duplicate_selectors: true,
  optimize_shorthand_properties: true,
  compress_css_variables: true,
  advanced_color_optimization: true
})

# Log compression metrics
Rails.logger.info "CSS compressed: #{stats[:statistics][:compression_ratio].round(2)}% reduction"
Rails.logger.warn "CSS compression used fallback" if stats[:statistics][:fallback_used]

# Use the compressed CSS
result = stats[:compressed_css]
```

## Framework Integration Updates

### Rails Asset Pipeline

#### Current Integration (v1.x style)
```ruby
# config/application.rb - Old way (still works)
config.assets.css_compressor = CSSminify2.new
```

#### Enhanced Integration (v2.x)
```ruby
# config/initializers/css_compression.rb
class EnhancedCSSCompressor
  def initialize
    @config = case Rails.env
    when 'development'
      {
        optimize_shorthand_properties: true,
        strict_error_handling: true  # Catch issues early
      }
    when 'test'  
      {
        merge_duplicate_selectors: true,
        optimize_shorthand_properties: true,
        strict_error_handling: true
      }
    when 'production'
      {
        merge_duplicate_selectors: true,
        optimize_shorthand_properties: true,
        compress_css_variables: true,
        advanced_color_optimization: true,
        strict_error_handling: false  # Graceful fallbacks
      }
    else
      {}  # Conservative defaults
    end
  end

  def compress(css)
    CSSminify2.compress_enhanced(css, @config)
  rescue => e
    Rails.logger.warn "Enhanced CSS compression failed: #{e.message}"
    # Fallback to basic compression
    CSSminify2.compress(css)
  end
end

# config/application.rb
config.assets.css_compressor = EnhancedCSSCompressor.new
```

### Sprockets Integration

#### Basic Update
```ruby
# Old
require 'cssminify2'
Sprockets.register_compressor 'text/css', :cssminify2, CSSminify2

# New - Enhanced
require 'cssminify2'

class SprocketsEnhancedCompressor
  def compress(css)
    CSSminify2.compress_enhanced(css, {
      merge_duplicate_selectors: true,
      optimize_shorthand_properties: true
    })
  end
end

Sprockets.register_compressor 'text/css', :cssminify2_enhanced, SprocketsEnhancedCompressor
```

### Jekyll Integration

#### Create Jekyll Plugin
```ruby
# _plugins/enhanced_css_minifier.rb
module Jekyll
  class EnhancedCSSMinifier < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      # Read configuration from _config.yml
      config = site.config['cssminify'] || {}
      
      options = {
        merge_duplicate_selectors: config['merge_selectors'] || false,
        optimize_shorthand_properties: config['optimize_shorthand'] || true,
        compress_css_variables: config['compress_variables'] || false,
        advanced_color_optimization: config['advanced_colors'] || false
      }

      site.static_files.each do |file|
        next unless file.extname == '.css'
        
        original_css = File.read(file.path)
        
        begin
          stats = CSSminify2.compress_with_stats(original_css, options)
          File.write(file.path, stats[:compressed_css])
          
          Jekyll.logger.info "CSSminify2:", "#{file.relative_path} - #{stats[:statistics][:compression_ratio].round(2)}% compression"
        rescue => e
          Jekyll.logger.warn "CSSminify2:", "Failed to compress #{file.relative_path}: #{e.message}"
        end
      end
    end
  end
end
```

#### Jekyll Configuration
```yaml
# _config.yml
cssminify:
  merge_selectors: true
  optimize_shorthand: true
  compress_variables: false  # Conservative for theme compatibility
  advanced_colors: true
```

## Build Tool Integration

### Gulp Integration

#### Create Ruby Bridge Script
```ruby
#!/usr/bin/env ruby
# tools/css_compressor.rb
require 'cssminify2'
require 'json'

# Read from STDIN, write to STDOUT for Gulp integration
input_css = STDIN.read
options_json = ARGV[0] || '{}'

begin
  options = JSON.parse(options_json, symbolize_names: true)
  
  stats = CSSminify2.compress_with_stats(input_css, options)
  
  result = {
    css: stats[:compressed_css],
    originalSize: stats[:statistics][:original_size],
    compressedSize: stats[:statistics][:compressed_size],
    compressionRatio: stats[:statistics][:compression_ratio],
    selectorsmerged: stats[:statistics][:selectors_merged] || 0,
    success: true
  }
  
  puts JSON.generate(result)
rescue => e
  error_result = {
    css: input_css,  # Return original on error
    error: e.message,
    success: false
  }
  
  STDERR.puts JSON.generate(error_result)
  exit 1
end
```

#### Gulp Task
```javascript
const { src, dest } = require('gulp');
const { spawn } = require('child_process');
const through = require('through2');

function cssminify(options = {}) {
  return through.obj(function(file, enc, cb) {
    if (file.isNull()) {
      cb(null, file);
      return;
    }

    const ruby = spawn('ruby', ['tools/css_compressor.rb', JSON.stringify(options)]);
    let result = '';
    let error = '';

    ruby.stdout.on('data', (data) => result += data);
    ruby.stderr.on('data', (data) => error += data);

    ruby.on('close', (code) => {
      if (code !== 0) {
        cb(new Error(`CSS compression failed: ${error}`));
        return;
      }

      try {
        const compression_result = JSON.parse(result);
        file.contents = Buffer.from(compression_result.css);
        
        console.log(`CSS compressed: ${compression_result.compressionRatio.toFixed(2)}% reduction`);
        cb(null, file);
      } catch (parseError) {
        cb(parseError);
      }
    });

    ruby.stdin.write(file.contents);
    ruby.stdin.end();
  });
}

// Usage
function compressCSS() {
  return src('src/**/*.css')
    .pipe(cssminify({
      merge_duplicate_selectors: true,
      optimize_shorthand_properties: true,
      compress_css_variables: true
    }))
    .pipe(dest('dist/'));
}

exports.css = compressCSS;
```

### Webpack Integration

#### Create Webpack Plugin
```ruby
# lib/webpack_css_plugin.rb
class WebpackCSSPlugin
  def self.compress(css_content, options_json = '{}')
    require 'cssminify2'
    require 'json'
    
    options = JSON.parse(options_json, symbolize_names: true)
    
    stats = CSSminify2.compress_with_stats(css_content, options)
    
    {
      css: stats[:compressed_css],
      stats: {
        originalSize: stats[:statistics][:original_size],
        compressedSize: stats[:statistics][:compressed_size],
        compressionRatio: stats[:statistics][:compression_ratio],
        selectorsmerged: stats[:statistics][:selectors_merged] || 0
      }
    }.to_json
  rescue => e
    {
      css: css_content,
      error: e.message,
      stats: { fallbackUsed: true }
    }.to_json
  end
end
```

## Troubleshooting Migration Issues

### Common Issues and Solutions

#### Issue: "Enhanced features not working"
```ruby
# Problem: Using old API
result = CSSminify2.compress(css, { merge_duplicate_selectors: true })  # ❌ Won't work

# Solution: Use enhanced API
result = CSSminify2.compress_enhanced(css, { merge_duplicate_selectors: true })  # ✅ Correct
```

#### Issue: "CSS breaks after compression"
```ruby
# Problem: Aggressive settings breaking CSS
result = CSSminify2.compress_enhanced(css, {
  merge_duplicate_selectors: true,
  strict_error_handling: false  # Hiding errors
})

# Solution: Enable strict mode to catch issues
begin
  result = CSSminify2.compress_enhanced(css, {
    merge_duplicate_selectors: true,
    strict_error_handling: true  # Will throw detailed errors
  })
rescue CSSminify2Enhanced::MalformedCSSError => e
  puts "CSS validation failed:"
  e.css_errors.each { |error| puts "- #{error}" }
  # Fix CSS issues or use conservative settings
end
```

#### Issue: "Unexpected compression results"
```ruby
# Problem: Not understanding what optimizations are applied
result = CSSminify2.compress_enhanced(css, options)

# Solution: Use statistics to understand what happened
stats = CSSminify2.compress_with_stats(css, options)
puts "Fallback used: #{stats[:statistics][:fallback_used]}"
puts "Selectors merged: #{stats[:statistics][:selectors_merged]}"
puts "Properties optimized: #{stats[:statistics][:properties_optimized]}"

if stats[:statistics][:fallback_used]
  puts "⚠️  Enhanced compression failed, basic compression was used instead"
end
```

#### Issue: "Performance regression"
```ruby
# Problem: Enhanced features taking too long
# Solution: Use configuration presets and measure performance

start_time = Time.now

# Conservative approach for performance-critical builds
config = CSSminify2Enhanced::Configuration.conservative
config.optimize_shorthand_properties = true  # Safe and fast

compressor = CSSminify2Enhanced::Compressor.new(config)
result = compressor.compress(css)

end_time = Time.now
puts "Compression took: #{(end_time - start_time) * 1000}ms"
```

### Migration Testing Strategy

#### 1. Gradual Rollout
```ruby
class GradualMigrationCompressor
  def initialize
    @use_enhanced = Rails.env.development? || 
                   ENV['CSS_ENHANCED_ENABLED'] == 'true'
  end

  def compress(css)
    if @use_enhanced
      # Test enhanced features in development
      CSSminify2.compress_enhanced(css, {
        optimize_shorthand_properties: true,
        merge_duplicate_selectors: true
      })
    else
      # Use stable compression in production
      CSSminify2.compress(css)
    end
  end
end
```

#### 2. A/B Testing
```ruby
class ABTestingCompressor
  def compress(css)
    # Compress with both methods
    basic_result = CSSminify2.compress(css)
    enhanced_result = CSSminify2.compress_enhanced(css, {
      optimize_shorthand_properties: true,
      merge_duplicate_selectors: true
    })

    # Log comparison metrics
    basic_size = basic_result.length
    enhanced_size = enhanced_result.length
    improvement = ((basic_size - enhanced_size).to_f / basic_size * 100).round(2)

    Rails.logger.info "CSS compression A/B test: #{improvement}% improvement with enhanced"

    # Use enhanced if it provides significant improvement
    improvement > 5 ? enhanced_result : basic_result
  end
end
```

#### 3. Validation Testing
```ruby
# Create a comprehensive test to validate migration
class MigrationValidator
  def self.validate_compression(css_files)
    css_files.each do |file|
      css = File.read(file)
      
      # Test both methods
      basic = CSSminify2.compress(css)
      enhanced = CSSminify2.compress_enhanced(css, {
        merge_duplicate_selectors: true,
        optimize_shorthand_properties: true
      })
      
      # Validate results
      puts "File: #{file}"
      puts "  Basic: #{basic.length} chars"
      puts "  Enhanced: #{enhanced.length} chars"
      puts "  Improvement: #{((basic.length - enhanced.length).to_f / basic.length * 100).round(2)}%"
      
      # Check for obvious issues
      if enhanced.count('{') != enhanced.count('}')
        puts "  ⚠️  WARNING: Unbalanced braces in enhanced result"
      end
      
      if enhanced.length > basic.length
        puts "  ⚠️  WARNING: Enhanced result is larger than basic"
      end
      
      puts ""
    end
  end
end

# Run validation
MigrationValidator.validate_compression(Dir.glob('app/assets/**/*.css'))
```

### Best Practices for Migration

1. **Start Small**: Begin with `optimize_shorthand_properties` only
2. **Test Thoroughly**: Validate in development and staging environments
3. **Monitor Performance**: Use statistics to track compression effectiveness
4. **Enable Gradually**: Add features one at a time to isolate any issues
5. **Plan Rollback**: Keep basic compression as fallback option
6. **Document Changes**: Record which features you enable and why

### Getting Help

If you encounter issues during migration:

1. **Enable debug mode**: Set `$VERBOSE = true` to see warnings
2. **Use strict error handling**: Enable detailed error messages
3. **Check statistics**: Look for `fallback_used` indicators
4. **Test with minimal CSS**: Isolate problematic CSS patterns
5. **Open an issue**: Report bugs with minimal reproducible examples

### Migration Checklist

- [ ] Update gemfile and run `bundle update`
- [ ] Test existing code works unchanged
- [ ] Enable `optimize_shorthand_properties` 
- [ ] Test CSS output in target browsers
- [ ] Add `merge_duplicate_selectors` if beneficial
- [ ] Test complex CSS files (frameworks, etc.)
- [ ] Enable `compress_css_variables` for projects using CSS variables
- [ ] Add statistics monitoring to build process
- [ ] Enable `advanced_color_optimization` if no IE filter issues
- [ ] Test full production build pipeline
- [ ] Document final configuration for team

**Migration complete!** You're now using CSSminify2 v2.x with enhanced features.