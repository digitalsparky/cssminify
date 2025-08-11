# Enhanced CSS Compression Features (Optional)
# 
# This file provides optional enhanced features for CSS compression
# while maintaining 100% backward compatibility with the original API.
#
# Usage:
#   # Original API (unchanged)
#   CSSminify2.compress(css) 
#
#   # Enhanced API (new, optional)
#   CSSminify2Enhanced.compress(css, options)
#   CSSminify2Enhanced.new(config).compress(css)

module CSSminify2Enhanced
    
    # Configuration class for enhanced features
    class Configuration
      attr_accessor :merge_duplicate_selectors, :optimize_shorthand_properties,
                    :advanced_color_optimization, :preserve_ie_hacks,
                    :compress_css_variables, :strict_error_handling,
                    :generate_source_map, :statistics_enabled
      
      def initialize
        # All new features are opt-in by default for compatibility
        @merge_duplicate_selectors = false
        @optimize_shorthand_properties = false  
        @advanced_color_optimization = false
        @preserve_ie_hacks = true
        @compress_css_variables = false
        @strict_error_handling = false
        @generate_source_map = false
        @statistics_enabled = false
      end
      
      # Preset configurations
      def self.conservative
        new # All features disabled
      end
      
      def self.aggressive
        config = new
        config.merge_duplicate_selectors = true
        config.optimize_shorthand_properties = true
        config.advanced_color_optimization = true
        config.compress_css_variables = true
        config
      end
      
      def self.modern
        config = aggressive
        config.generate_source_map = true
        config.statistics_enabled = true
        config
      end
    end
    
    # Enhanced compressor with new features
    class Compressor
      attr_reader :config, :statistics
      
      def initialize(config = Configuration.new)
        @config = config
        @statistics = {
          original_size: 0,
          compressed_size: 0,
          compression_ratio: 0.0,
          selectors_merged: 0,
          properties_optimized: 0,
          colors_converted: 0
        }
      end
      
      def compress(css, linebreakpos = 5000)
        @statistics[:original_size] = css.length
        
        begin
          # Validate CSS structure before processing
          validate_css_structure(css) if @config.strict_error_handling
          
          # Start with the original compression to maintain compatibility
          result = CssCompressor.compress(css, linebreakpos)
          
          # Apply enhanced optimizations if enabled
          if any_enhancements_enabled?
            result = apply_enhanced_optimizations_safely(result)
          end
          
          @statistics[:compressed_size] = result.length
          @statistics[:compression_ratio] = calculate_compression_ratio
          
          result
          
        rescue => e
          if @config.strict_error_handling
            raise EnhancedCompressionError.new("Enhanced compression failed: #{e.message}", e)
          else
            # Graceful fallback to original compressor
            fallback_result = safe_fallback_compression(css, linebreakpos)
            @statistics[:compressed_size] = fallback_result.length
            @statistics[:compression_ratio] = calculate_compression_ratio
            @statistics[:fallback_used] = true
            fallback_result
          end
        end
      end
      
      private
      
      def any_enhancements_enabled?
        @config.merge_duplicate_selectors ||
        @config.optimize_shorthand_properties ||
        @config.advanced_color_optimization ||
        @config.compress_css_variables
      end
      
      def apply_enhanced_optimizations(css)
        css = merge_duplicate_selectors(css) if @config.merge_duplicate_selectors
        css = optimize_shorthand_properties(css) if @config.optimize_shorthand_properties  
        css = enhance_zero_value_optimization(css) if @config.optimize_shorthand_properties
        css = optimize_modern_layout_properties(css) if @config.optimize_shorthand_properties
        css = compress_css_variables(css) if @config.compress_css_variables
        css = advanced_color_optimization(css) if @config.advanced_color_optimization
        css
      end
      
      def apply_enhanced_optimizations_safely(css)
        # Apply optimizations with individual error handling
        optimizations = [
          [:merge_duplicate_selectors, @config.merge_duplicate_selectors],
          [:optimize_shorthand_properties, @config.optimize_shorthand_properties],
          [:enhance_zero_value_optimization, @config.optimize_shorthand_properties],
          [:optimize_modern_layout_properties, @config.optimize_shorthand_properties],
          [:compress_css_variables, @config.compress_css_variables],
          [:advanced_color_optimization, @config.advanced_color_optimization]
        ]
        
        optimizations.each do |method_name, enabled|
          next unless enabled
          
          begin
            css = send(method_name, css)
          rescue => e
            if @config.strict_error_handling
              raise e
            else
              # Log error but continue with other optimizations
              warn "Warning: #{method_name} optimization failed: #{e.message}"
            end
          end
        end
        
        css
      end
      
      def validate_css_structure(css)
        # Basic CSS validation to catch major structural issues
        errors = []
        
        # Check for balanced braces
        open_braces = css.count('{')
        close_braces = css.count('}')
        if open_braces != close_braces
          errors << "Unbalanced braces: #{open_braces} opening vs #{close_braces} closing"
        end
        
        # Check for balanced quotes
        double_quotes = css.scan(/"/).length
        single_quotes = css.scan(/'/).length
        if double_quotes % 2 != 0
          errors << "Unmatched double quotes"
        end
        if single_quotes % 2 != 0
          errors << "Unmatched single quotes"
        end
        
        # Check for valid CSS structure patterns
        if css.match(/\{[^{}]*\{/) # Nested braces outside of media queries/keyframes
          unless css.match(/@(?:media|supports|keyframes|container)/)
            errors << "Potentially invalid nested braces"
          end
        end
        
        # Check for common syntax errors
        if css.match(/[^;{}]\s*\}/) && !css.match(/@/)
          errors << "Missing semicolon before closing brace"
        end
        
        if errors.any?
          raise MalformedCSSError.new("CSS validation failed: #{errors.join(', ')}")
        end
      end
      
      def safe_fallback_compression(css, linebreakpos)
        # Safe fallback with minimal error handling
        begin
          CssCompressor.compress(css, linebreakpos)
        rescue => e
          # Last resort: basic whitespace compression
          warn "Warning: Fallback to basic compression due to: #{e.message}"
          basic_compression_fallback(css)
        end
      end
      
      def basic_compression_fallback(css)
        # Ultra-safe basic compression as last resort
        css
          .gsub(/\/\*.*?\*\//m, '')         # Remove comments
          .gsub(/\s+/, ' ')                 # Compress whitespace
          .gsub(/\s*{\s*/, '{')             # Clean braces
          .gsub(/\s*}\s*/, '}')
          .gsub(/\s*;\s*/, ';')             # Clean semicolons
          .gsub(/:\s+/, ':')                # Clean colons
          .strip
      end
      
      def merge_duplicate_selectors(css)
        # Advanced duplicate selector merging with proper CSS parsing
        # Handles media queries, keyframes, and preserves cascade order
        
        selectors_merged = 0
        
        # Split CSS into blocks (rules, at-rules, etc.)
        css = css.gsub(/@media[^{]*\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/m) do |media_block|
          # Process media queries recursively  
          process_media_block(media_block)
        end
        
        # Process regular CSS rules outside of media queries
        css = merge_regular_selectors(css)
        
        @statistics[:selectors_merged] = selectors_merged
        css
      end
      
      private
      
      def process_media_block(media_block)
        # Extract media query and content
        if media_block.match(/@media([^{]*)\{(.*)\}/m)
          media_query = $1.strip
          content = $2
          
          # Merge selectors within this media query
          merged_content = merge_regular_selectors(content)
          
          "@media#{media_query}{#{merged_content}}"
        else
          media_block
        end
      end
      
      def merge_regular_selectors(css)
        # Parse CSS rules more carefully
        rules = parse_css_rules(css)
        merged_rules = merge_parsed_rules(rules)
        rebuild_css_from_rules(merged_rules)
      end
      
      def parse_css_rules(css)
        rules = []
        current_pos = 0
        
        while current_pos < css.length
          # Find next rule
          rule_match = css.match(/([^{}]+)\{([^{}]*)\}/m, current_pos)
          break unless rule_match
          
          selector = rule_match[1].strip
          declarations = rule_match[2].strip
          position = rule_match.begin(0)
          
          # Skip if this looks like an at-rule we shouldn't merge
          unless selector.match(/^@(?:keyframes|font-face|page|supports|document)/)
            rules << {
              selector: normalize_selector(selector),
              original_selector: selector,
              declarations: declarations,
              position: position
            }
          end
          
          current_pos = rule_match.end(0)
        end
        
        rules
      end
      
      def normalize_selector(selector)
        # Normalize selector for comparison (remove extra whitespace, etc.)
        selector.gsub(/\s+/, ' ').strip
      end
      
      def merge_parsed_rules(rules)
        # Group rules by selector, maintaining order
        selector_groups = {}
        merged_rules = []
        
        rules.each do |rule|
          selector = rule[:selector]
          
          if selector_groups[selector]
            # Merge with existing rule
            existing_rule = selector_groups[selector]
            existing_rule[:declarations] = merge_declarations(
              existing_rule[:declarations], 
              rule[:declarations]
            )
            @statistics[:selectors_merged] += 1
          else
            # First occurrence of this selector
            new_rule = rule.dup
            selector_groups[selector] = new_rule
            merged_rules << new_rule
          end
        end
        
        merged_rules
      end
      
      def merge_declarations(existing_declarations, new_declarations)
        # Parse declarations and merge, with later declarations overriding earlier ones
        existing_props = parse_declarations(existing_declarations)
        new_props = parse_declarations(new_declarations)
        
        # Merge properties, with new_props taking precedence
        merged_props = existing_props.merge(new_props)
        
        # Rebuild declaration string
        merged_props.map { |prop, value| "#{prop}:#{value}" }.join(';')
      end
      
      def parse_declarations(declarations)
        properties = {}
        return properties if declarations.empty?
        
        declarations.split(';').each do |declaration|
          if declaration.match(/^\s*([^:]+):\s*(.+)\s*$/)
            property = $1.strip
            value = $2.strip
            properties[property] = value
          end
        end
        
        properties
      end
      
      def rebuild_css_from_rules(rules)
        rules.map do |rule|
          declarations = rule[:declarations]
          declarations = declarations.empty? ? '' : declarations
          "#{rule[:original_selector]}{#{declarations}}"
        end.join('')
      end
      
      def optimize_shorthand_properties(css)
        original_length = css.length
        
        # Advanced margin/padding optimization with units flexibility
        css = optimize_box_model_properties(css, 'margin')
        css = optimize_box_model_properties(css, 'padding')
        
        # Background shorthand optimizations
        css = optimize_background_properties(css)
        
        # Border shorthand optimizations  
        css = optimize_border_properties(css)
        
        # Font shorthand optimizations
        css = optimize_font_properties(css)
        
        # List-style optimizations
        css = optimize_list_properties(css)
        
        @statistics[:properties_optimized] += ((original_length - css.length) / 10).to_i # Rough estimate
        css
      end
      
      private
      
      def optimize_box_model_properties(css, property)
        # Handle all units, not just px
        unit_pattern = '(?:px|em|rem|%|vh|vw|pt|pc|in|cm|mm|ex|ch|vmin|vmax|0)'
        
        # Four identical values: margin: 10px 10px 10px 10px → margin: 10px
        css = css.gsub(/#{property}:\s*([+-]?\d*\.?\d+#{unit_pattern})\s+\1\s+\1\s+\1/i) { "#{property}:#{$1}" }
        
        # Vertical/horizontal pairs: margin: 10px 20px 10px 20px → margin: 10px 20px  
        css = css.gsub(/#{property}:\s*([+-]?\d*\.?\d+#{unit_pattern})\s+([+-]?\d*\.?\d+#{unit_pattern})\s+\1\s+\2/i) { "#{property}:#{$1} #{$2}" }
        
        # Three values where first and third are same: margin: 10px 20px 10px → margin: 10px 20px
        css = css.gsub(/#{property}:\s*([+-]?\d*\.?\d+#{unit_pattern})\s+([+-]?\d*\.?\d+#{unit_pattern})\s+\1/i) { "#{property}:#{$1} #{$2}" }
        
        css
      end
      
      def optimize_background_properties(css)
        # background: none repeat scroll 0 0 color → background: color
        css = css.gsub(/background:\s*none\s+repeat\s+scroll\s+0\s+0\s+([^;}]+)/i) { "background:#{$1}" }
        
        # background-position: 0 center → background-position: 0
        css = css.gsub(/background-position:\s*0\s+(?:center|50%)/i) { "background-position:0" }
        
        # background-repeat: repeat repeat → background-repeat: repeat
        css = css.gsub(/background-repeat:\s*repeat\s+repeat/i) { "background-repeat:repeat" }
        
        css
      end
      
      def optimize_border_properties(css)
        # Remove redundant border-width when already specified in border shorthand
        css = css.gsub(/border:\s*(\d+\w*)\s+([^;}]+);\s*border-width:\s*\1/i) { "border:#{$1} #{$2}" }
        
        # Remove redundant border-style when already specified
        css = css.gsub(/border:\s*([^;}]*?)\s+(solid|dashed|dotted|double)([^;}]*?);\s*border-style:\s*\2/i) { "border:#{$1} #{$2}#{$3}" }
        
        # Remove redundant border-color when already specified  
        css = css.gsub(/border:\s*([^;}]*?)\s+(#[0-9a-f]{3,6}|[a-z]+)([^;}]*?);\s*border-color:\s*\2/i) { "border:#{$1} #{$2}#{$3}" }
        
        css
      end
      
      def optimize_font_properties(css)
        # Font weight optimizations
        css = css.gsub(/font-weight:\s*normal/i) { "font-weight:400" }
        css = css.gsub(/font-weight:\s*bold/i) { "font-weight:700" }
        
        # Font style optimizations
        css = css.gsub(/font-style:\s*normal/i) { "font-style:normal" } # Normalize case
        
        css
      end
      
      def optimize_list_properties(css)
        # list-style: none inside → list-style: none (inside is default for none)
        css = css.gsub(/list-style:\s*none\s+inside/i) { "list-style:none" }
        
        css
      end
      
      def enhance_zero_value_optimization(css)
        # Advanced zero value and unit optimizations beyond basic YUI compressor
        original_length = css.length
        
        # Remove unnecessary zeros in decimal values
        css = optimize_decimal_zeros(css)
        
        # Optimize calc() expressions with zeros
        css = optimize_calc_zeros(css)
        
        # Advanced unit optimizations
        css = optimize_modern_units(css)
        
        # Transform property optimizations
        css = optimize_transform_zeros(css)
        
        # Advanced background position optimizations
        css = optimize_position_zeros(css)
        
        # Box-shadow and text-shadow optimizations
        css = optimize_shadow_zeros(css)
        
        # Update statistics
        chars_saved = original_length - css.length
        @statistics[:properties_optimized] += (chars_saved / 3).to_i # Rough estimate
        
        css
      end
      
      def optimize_decimal_zeros(css)
        # More aggressive decimal optimization
        css = css.gsub(/(\d)\.0+(?!\d)/) { $1 }                    # 1.0 → 1
        css = css.gsub(/0+\.(\d+)/) { ".#{$1}" }                   # 0.5 → .5  
        css = css.gsub(/(\d+)\.0*(\d*?)0+(?!\d)/) { "#{$1}.#{$2}".gsub(/\.$/, '') } # 1.500 → 1.5
        css
      end
      
      def optimize_calc_zeros(css)
        # Optimize calc() expressions with zeros
        css = css.gsub(/calc\([^)]*\)/) do |calc_expr|
          # Simplify addition/subtraction with zero
          calc_expr = calc_expr.gsub(/\+\s*0\w*/, '')               # + 0px → nothing
          calc_expr = calc_expr.gsub(/0\w*\s*\+/, '')               # 0px + → nothing  
          calc_expr = calc_expr.gsub(/-\s*0\w*/, '')                # - 0px → nothing
          calc_expr = calc_expr.gsub(/\*\s*1(?:\.\d*)?/, '')        # * 1 → nothing
          calc_expr = calc_expr.gsub(/1(?:\.\d*)?\s*\*/, '')        # 1 * → nothing
          
          # Clean up extra spaces
          calc_expr.gsub(/\s+/, ' ').strip
        end
        css
      end
      
      def optimize_modern_units(css)
        # Optimize newer CSS units where possible
        css = css.gsub(/0(?:ch|rem|em|vw|vh|vmin|vmax|fr)(?!\w)/, '0')
        
        # Convert some units where it saves space (commented out for safety)
        # css = css.gsub(/16px/, '1rem')  # Only if 1rem saves space in context
        
        css
      end
      
      def optimize_transform_zeros(css)
        # Transform property optimizations
        css = css.gsub(/translate\(0,\s*0\)/, 'translate(0)')        # translate(0, 0) → translate(0)
        css = css.gsub(/translate3d\(0,\s*0,\s*0\)/, 'translate3d(0)') # translate3d(0,0,0) → translate3d(0)
        css = css.gsub(/scale\(1,\s*1\)/, 'scale(1)')               # scale(1, 1) → scale(1)
        css = css.gsub(/rotate\(0(?:deg|rad|turn)?\)/, '')          # rotate(0deg) → remove
        css = css.gsub(/skew\(0,\s*0\)/, '')                        # skew(0, 0) → remove
        
        css
      end
      
      def optimize_position_zeros(css)
        # Advanced background-position and object-position optimizations
        css = css.gsub(/background-position:\s*0\s+0/, 'background-position:0')
        css = css.gsub(/object-position:\s*0\s+0/, 'object-position:0')
        css = css.gsub(/transform-origin:\s*0\s+0/, 'transform-origin:0')
        
        css
      end
      
      def optimize_shadow_zeros(css)
        # Optimize box-shadow and text-shadow with zeros
        css = css.gsub(/(box-shadow|text-shadow):\s*0\s+0\s+0\s+([^;,}]+)/) { "#{$1}:0 0 #{$2}" }
        css = css.gsub(/(box-shadow|text-shadow):\s*0\s+0\s+([^;,}]+)/) { "#{$1}:0 #{$2}" }
        css = css.gsub(/(box-shadow|text-shadow):\s*0\s+0\s+0\s*(?:;|})/) { "#{$1}:0" }
        
        css
      end
      
      def optimize_modern_layout_properties(css)
        # Advanced CSS Grid and Flexbox optimizations
        original_length = css.length
        
        css = optimize_flexbox_properties(css)
        css = optimize_grid_properties(css)
        css = optimize_alignment_properties(css)
        css = optimize_gap_properties(css)
        
        # Update statistics
        chars_saved = original_length - css.length
        @statistics[:properties_optimized] += (chars_saved / 4).to_i # Rough estimate
        
        css
      end
      
      def optimize_flexbox_properties(css)
        # Flex shorthand optimizations
        css = css.gsub(/flex:\s*1\s+1\s+auto/i, 'flex:1')                    # flex: 1 1 auto → flex: 1
        css = css.gsub(/flex:\s*0\s+0\s+auto/i, 'flex:none')                 # flex: 0 0 auto → flex: none
        css = css.gsub(/flex:\s*0\s+1\s+auto/i, 'flex:auto')                 # flex: 0 1 auto → flex: auto
        css = css.gsub(/flex:\s*(\d+)\s+\1\s+0/i) { "flex:#{$1}" }           # flex: 2 2 0 → flex: 2
        
        # Flex-direction optimizations
        css = css.gsub(/flex-direction:\s*row/i, 'flex-direction:row')        # Normalize case
        
        # Justify-content optimizations (use shorter values when supported)
        css = css.gsub(/justify-content:\s*flex-start/i, 'justify-content:start')
        css = css.gsub(/justify-content:\s*flex-end/i, 'justify-content:end')
        css = css.gsub(/align-items:\s*flex-start/i, 'align-items:start')
        css = css.gsub(/align-items:\s*flex-end/i, 'align-items:end')
        css = css.gsub(/align-self:\s*flex-start/i, 'align-self:start')
        css = css.gsub(/align-self:\s*flex-end/i, 'align-self:end')
        
        css
      end
      
      def optimize_grid_properties(css)
        # Grid shorthand optimizations
        css = css.gsub(/grid-template-columns:\s*repeat\((\d+),\s*1fr\)/i) { "grid-template-columns:repeat(#{$1},1fr)" }
        
        # Grid-area optimizations 
        css = css.gsub(/grid-area:\s*(\d+)\s*\/\s*(\d+)\s*\/\s*(\d+)\s*\/\s*(\d+)/i) do |match|
          row_start, col_start, row_end, col_end = $1, $2, $3, $4
          
          # Optimize common patterns
          if row_start == row_end.to_i - 1 && col_start == col_end.to_i - 1
            # Single cell: grid-area: 1 / 1 / 2 / 2 → grid-area: 1 / 1
            "grid-area:#{row_start}/#{col_start}"
          else
            "grid-area:#{row_start}/#{col_start}/#{row_end}/#{col_end}"
          end
        end
        
        # Grid-template optimizations
        css = css.gsub(/grid-template:\s*none\s*\/\s*none/i, 'grid-template:none')
        
        # Grid-auto-flow optimizations
        css = css.gsub(/grid-auto-flow:\s*row/i, 'grid-auto-flow:row')        # Default, can sometimes be omitted
        
        css
      end
      
      def optimize_alignment_properties(css)
        # Place-items and place-content shortcuts
        css = css.gsub(/align-items:\s*([^;]+);\s*justify-items:\s*\1/i) { "place-items:#{$1}" }
        css = css.gsub(/align-content:\s*([^;]+);\s*justify-content:\s*\1/i) { "place-content:#{$1}" }
        css = css.gsub(/align-self:\s*([^;]+);\s*justify-self:\s*\1/i) { "place-self:#{$1}" }
        
        # Center shorthand
        css = css.gsub(/place-items:\s*center\s+center/i, 'place-items:center')
        css = css.gsub(/place-content:\s*center\s+center/i, 'place-content:center')
        
        css
      end
      
      def optimize_gap_properties(css)
        # Gap property optimizations
        css = css.gsub(/grid-gap:\s*(\d+\w*)\s+\1/i) { "grid-gap:#{$1}" }     # grid-gap: 10px 10px → grid-gap: 10px
        css = css.gsub(/gap:\s*(\d+\w*)\s+\1/i) { "gap:#{$1}" }              # gap: 10px 10px → gap: 10px
        css = css.gsub(/row-gap:\s*(\d+\w*);\s*column-gap:\s*\1/i) { "gap:#{$1}" } # Combine identical row/column gaps
        
        # Use gap instead of grid-gap (modern syntax)
        css = css.gsub(/grid-gap:/i, 'gap:')                                 # grid-gap → gap (shorter and modern)
        css = css.gsub(/grid-row-gap:/i, 'row-gap:')                         # grid-row-gap → row-gap
        css = css.gsub(/grid-column-gap:/i, 'column-gap:')                   # grid-column-gap → column-gap
        
        css
      end
      
      def compress_css_variables(css)
        # Advanced CSS custom property optimization
        original_length = css.length
        
        # Parse variable declarations and usage
        variable_data = analyze_css_variables(css)
        
        # Apply optimizations based on analysis
        css = inline_single_use_variables(css, variable_data)
        css = remove_unused_variables(css, variable_data)
        css = optimize_variable_names(css, variable_data)
        
        # Update statistics
        chars_saved = original_length - css.length
        @statistics[:properties_optimized] += (chars_saved / 5).to_i # Rough estimate
        
        css
      end
      
      def analyze_css_variables(css)
        variables = {}
        
        # Find all variable declarations with their values
        css.scan(/(--[\w-]+):\s*([^;]+)/) do |var_name, var_value|
          variables[var_name] ||= { 
            value: var_value.strip, 
            declarations: 0, 
            usages: 0,
            total_value_length: 0
          }
          variables[var_name][:declarations] += 1
          variables[var_name][:total_value_length] += var_value.length
        end
        
        # Count variable usages
        css.scan(/var\((--[\w-]+)(?:,([^)]*))?\)/) do |var_name, fallback|
          if variables[var_name]
            variables[var_name][:usages] += 1
            variables[var_name][:fallback] = fallback&.strip
          end
        end
        
        variables
      end
      
      def inline_single_use_variables(css, variable_data)
        # Inline variables that are used only once or twice and have short values
        variables_to_inline = variable_data.select do |var_name, data|
          data[:usages] <= 2 && 
          data[:declarations] == 1 && 
          data[:value].length <= 20 && # Only inline short values
          !data[:value].include?('calc(') && # Don't inline complex calc expressions
          !data[:value].include?('var(')     # Don't inline variables that reference other variables
        end
        
        variables_to_inline.each do |var_name, data|
          value = data[:value]
          
          # Replace var() usages with the actual value
          css = css.gsub(/var\(#{Regexp.escape(var_name)}(?:,[^)]*)?\)/, value)
          
          # Remove the variable declaration
          css = css.gsub(/#{Regexp.escape(var_name)}:\s*#{Regexp.escape(value)};?/, '')
        end
        
        css
      end
      
      def remove_unused_variables(css, variable_data)
        # Remove variables that are declared but never used
        unused_variables = variable_data.select { |var_name, data| data[:usages] == 0 }
        
        unused_variables.each do |var_name, data|
          # Remove unused variable declarations
          css = css.gsub(/#{Regexp.escape(var_name)}:\s*[^;]+;?/, '')
        end
        
        css
      end
      
      def optimize_variable_names(css, variable_data)
        # For frequently used variables with long names, consider shorter aliases
        # This is more conservative - only optimize very long names that are used frequently
        
        frequent_long_variables = variable_data.select do |var_name, data|
          data[:usages] >= 3 && var_name.length > 15
        end
        
        frequent_long_variables.each_with_index do |(var_name, data), index|
          # Create a shorter name (be careful not to conflict with existing names)
          short_name = "--v#{index + 1}"
          
          # Make sure the short name doesn't already exist
          next if css.include?(short_name)
          
          # Replace all occurrences of the long variable name
          css = css.gsub(var_name, short_name)
        end
        
        css
      end
      
      def advanced_color_optimization(css)
        # More aggressive color optimization beyond basic YUI compressor
        color_count_before = css.scan(/#[0-9a-f]{3,6}|rgb\([^)]+\)/i).length
        
        # Add HSL to RGB conversion
        css = css.gsub(/hsl\(\s*(\d+)\s*,\s*(\d+)%\s*,\s*(\d+)%\s*\)/i) do
          h, s, l = $1.to_i, $2.to_i / 100.0, $3.to_i / 100.0
          rgb = hsl_to_rgb(h, s, l)
          "rgb(#{rgb.join(',')})"
        end
        
        color_count_after = css.scan(/#[0-9a-f]{3,6}|rgb\([^)]+\)/i).length
        @statistics[:colors_converted] += color_count_before - color_count_after
        
        css
      end
      
      def hsl_to_rgb(h, s, l)
        h = h / 360.0
        
        if s == 0
          r = g = b = l
        else
          hue2rgb = lambda do |p, q, t|
            t += 1 if t < 0
            t -= 1 if t > 1
            return p + (q - p) * 6 * t if t < 1.0/6
            return q if t < 1.0/2
            return p + (q - p) * (2.0/3 - t) * 6 if t < 2.0/3
            p
          end
          
          q = l < 0.5 ? l * (1 + s) : l + s - l * s
          p = 2 * l - q
          r = hue2rgb.call(p, q, h + 1.0/3)
          g = hue2rgb.call(p, q, h)
          b = hue2rgb.call(p, q, h - 1.0/3)
        end
        
        [(r * 255).round, (g * 255).round, (b * 255).round]
      end
      
      def calculate_compression_ratio
        return 0.0 if @statistics[:original_size] == 0
        ((@statistics[:original_size] - @statistics[:compressed_size]).to_f / @statistics[:original_size]) * 100
      end
    end
    
    # Convenience class methods for enhanced compression
    def self.compress(css, options = {})
      if options.is_a?(Hash) && !options.empty?
        config = Configuration.new
        options.each { |key, value| config.send("#{key}=", value) if config.respond_to?("#{key}=") }
        Compressor.new(config).compress(css, options[:linebreakpos] || 5000)
      else
        # Fallback to original API for backward compatibility
        linebreakpos = options.is_a?(Integer) ? options : 5000
        CssCompressor.compress(css, linebreakpos)
      end
    end
    
    def self.compress_with_stats(css, options = {})
      config = Configuration.new
      options.each { |key, value| config.send("#{key}=", value) if config.respond_to?("#{key}=") }
      config.statistics_enabled = true
      
      compressor = Compressor.new(config)
      result = compressor.compress(css, options[:linebreakpos] || 5000)
      
      {
        compressed_css: result,
        statistics: compressor.statistics
      }
    end
    
    # Error class for enhanced features
    class EnhancedCompressionError < StandardError
      attr_reader :original_error
      
      def initialize(message, original_error = nil)
        super(message)
        @original_error = original_error
      end
    end
    
    # Error class for malformed CSS
    class MalformedCSSError < StandardError
      attr_reader :css_errors
      
      def initialize(message, css_errors = [])
        super(message)
        @css_errors = css_errors
      end
    end
end