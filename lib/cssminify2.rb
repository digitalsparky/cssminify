# coding: utf-8

require "cssminify2/cssmin"
require "cssminify2/version"

# Optional enhanced features (backward compatible)
begin
  require "cssminify2/enhanced"
rescue LoadError
  # Enhanced features not available, continue with basic functionality
end

class CSSminify2

  def initialize
  end

  #
  # Compress CSS with YUI (Original API - Unchanged)
  #
  # @param [String, #read] CSS String or IO-like object that supports #read
  # @param [Integer] length Maximum line length
  # @return [String] Compressed CSS
  def self.compress(source, length = 5000)
    self.new.compress(source, length)
  end

  #
  # Compress CSS with YUI (Original API - Unchanged)
  #
  # @param [String, #read] CSS String or IO-like object that supports #read
  # @param [Integer] length Maximum line length
  # @return [String] Compressed CSS
  def compress(source = '', length = 5000)
    source = source.respond_to?(:read) ? source.read : source.to_s

    CssCompressor.compress(source, length)
  end

  # 
  # Enhanced compression with additional features (New, Optional)
  #
  # @param [String, #read] CSS String or IO-like object that supports #read
  # @param [Hash] options Configuration options for enhanced features
  # @option options [Boolean] :merge_duplicate_selectors Merge duplicate selectors
  # @option options [Boolean] :optimize_shorthand_properties Optimize margin/padding shorthand
  # @option options [Boolean] :advanced_color_optimization Enhanced color optimization
  # @option options [Integer] :linebreakpos Maximum line length (default: 5000)
  # @return [String] Compressed CSS
  def self.compress_enhanced(source, options = {})
    if defined?(CSSminify2Enhanced)
      CSSminify2Enhanced.compress(source, options)
    else
      # Fallback to original compression if enhanced features not available
      compress(source, options[:linebreakpos] || 5000)
    end
  end

  #
  # Enhanced compression with statistics (New, Optional)
  #
  # @param [String, #read] CSS String or IO-like object that supports #read
  # @param [Hash] options Configuration options
  # @return [Hash] Hash containing :compressed_css and :statistics
  def self.compress_with_stats(source, options = {})
    if defined?(CSSminify2Enhanced)
      CSSminify2Enhanced.compress_with_stats(source, options)
    else
      # Fallback with basic stats
      original = source.respond_to?(:read) ? source.read : source.to_s
      compressed = compress(original, options[:linebreakpos] || 5000)
      {
        compressed_css: compressed,
        statistics: {
          original_size: original.length,
          compressed_size: compressed.length,
          compression_ratio: ((original.length - compressed.length).to_f / original.length * 100).round(2),
          enhanced_features_used: false
        }
      }
    end
  end
end
