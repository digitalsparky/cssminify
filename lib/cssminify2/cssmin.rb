#
# cssmin.rb - 1.0.1
# Author: Matthias Siegel - https://github.com/matthiassiegel/cssmin
# This is a Ruby port of the CSS minification tool
# distributed with YUICompressor, based on the original Java
# code and the Javascript port by Stoyan Stefanov.
# Permission is hereby granted to use the Ruby version under the same
# conditions as YUICompressor (original YUICompressor note below).
#
#
# YUI Compressor
# http://developer.yahoo.com/yui/compressor/
# Author: Julien Lecomte -  http://www.julienlecomte.net/
# Author: Isaac Schlueter - http://foohack.com/
# Author: Stoyan Stefanov - http://phpied.com/
# Copyright (c) 2011 Yahoo! Inc.  All rights reserved.
# The copyrights embodied in the content of this file are licensed
# by Yahoo! Inc. under the BSD (revised) open source license.
#

module CssCompressor

  def self.compress(css, linebreakpos = 5000)

    #
    # Support for various input types
    #
    if css.respond_to?(:read)
      css = css.read
    elsif css.respond_to?(:path)
      css = File.read(css.path)
    end

    @@preservedTokens = []
    comments = []
    startIndex = 0

    #
    # Extract data urls
    #
    css = extractDataUrls(css)

    #
    # Collect all comment blocks...
    #
    while (startIndex = css.index(/\/\*/, startIndex)) != nil
      endIndex = css.index(/\*\//, startIndex + 2)
      endIndex = css.length if endIndex.nil?

      comments << css[(startIndex + 2)...endIndex]

      css = css[0...(startIndex + 2)] + '___YUICSSMIN_PRESERVE_CANDIDATE_COMMENT_' + (comments.length - 1).to_s + '___' + css[endIndex..-1]
      startIndex += 2
    end

    #
    # Preserve strings so their content doesn't get accidentally minified
    #
    css = css.gsub(/("([^\\"]|\\.|\\)*")|('([^\\']|\\.|\\)*')/) { |match|
      quote = match[0, 1]
      match = match[1...-1]

      #
      # Maybe the string contains a comment-like substring?
      # One, maybe more? put'em back then
      #
      unless match.index('___YUICSSMIN_PRESERVE_CANDIDATE_COMMENT_').nil?
        comments.each_index { |i| match = match.gsub(/___YUICSSMIN_PRESERVE_CANDIDATE_COMMENT_#{i}___/, comments[i]) }
      end

      #
      # Minify alpha opacity in filter strings
      #
      match = match.gsub(/progid:DXImageTransform\.Microsoft\.Alpha\(Opacity=/i, 'alpha(opacity=')

      @@preservedTokens << match

      quote + "___YUICSSMIN_PRESERVED_TOKEN_" + (@@preservedTokens.length - 1).to_s + "___" + quote
    }

    #
    # Strings are safe, now wrestle the comments
    #
    for i in 0...comments.length
      token = comments[i]
      placeholder = /___YUICSSMIN_PRESERVE_CANDIDATE_COMMENT_#{i}___/

      #
      # ! in the first position of the comment means preserve
      # so push to the preserved tokens keeping the !
      #
      if token[0] === '!'
        @@preservedTokens << token
        css = css.gsub(placeholder, "___YUICSSMIN_PRESERVED_TOKEN_" + (@@preservedTokens.length - 1).to_s + "___")
        next
      end

      #
      # \ in the last position looks like hack for Mac/IE5
      # shorten that to /*\*/ and the next one to /**/
      #
      if token[(token.length - 1)..-1] === '\\'
        @@preservedTokens << '\\'
        css = css.gsub(placeholder, "___YUICSSMIN_PRESERVED_TOKEN_" + (@@preservedTokens.length - 1).to_s + "___")

        i += 1  # Attn: advancing the loop

        @@preservedTokens << ''
        css = css.gsub(/___YUICSSMIN_PRESERVE_CANDIDATE_COMMENT_#{i}___/, "___YUICSSMIN_PRESERVED_TOKEN_" + (@@preservedTokens.length - 1).to_s + "___")
        next
      end

      #
      # Keep empty comments after child selectors (IE7 hack)
      # E.g. html >/**/ body
      #
      if token.length == 0
        startIndex = css.index(placeholder)

        if startIndex and startIndex > 2
          if css[startIndex - 3] === '>'
            @@preservedTokens << ''
            css = css.gsub(placeholder, "___YUICSSMIN_PRESERVED_TOKEN_" + (@@preservedTokens.length - 1).to_s + "___")
          end
        end
      end

      #
      # In all other cases kill the comment
      #
      css = css.gsub(/\/\*___YUICSSMIN_PRESERVE_CANDIDATE_COMMENT_#{i}___\*\//, '')
    end

    #
    # Shorten all whitespace strings to single spaces
    #
    css = css.gsub(/\s+/, ' ')

    #
    # Preserve calc() functions completely - calc() requires spaces around operators
    #
    calc_placeholders = []
    css = css.gsub(/calc\([^)]*\)/) do |match|
      # Ensure operators have proper spacing
      normalized = match.gsub(/\s*([+\-*\/])\s*/, ' \1 ')
      calc_placeholders << normalized
      "___YUICSSMIN_CALC_FUNCTION_#{calc_placeholders.length - 1}___"
    end

    #
    # Remove the spaces before the things that should not have spaces before them.
    # But, be careful not to turn "p :link {...}" into "p:link{...}"
    # Also preserve spaces between pseudo-classes like ":first-child :last-child"
    # Swap out any pseudo-class colons with the token, and then swap back.
    #
    css = css.gsub(/(^|\})(([^\{:])+:)+([^\{]*\{)/) { |m| m.gsub(/:/, '___YUICSSMIN_PSEUDOCLASSCOLON___') }
    # Match sequences of pseudo-classes with spaces between them
    css = css.gsub(/(:[\w-]+(?:\([^)]*\))?(?:\s+:[\w-]+(?:\([^)]*\))?)+)/) { |m| m.gsub(/\s+/, '___YUICSSMIN_PRESERVE_SPACE___') }
    css = css.gsub(/\s+([!{};:>+\)\],])/) { $1.to_s }
    css = css.gsub(/([^\+\-\/\*])\s+\(/) { $1.concat('(') }
    css = css.gsub(/___YUICSSMIN_PSEUDOCLASSCOLON___/, ':')
    css = css.gsub(/___YUICSSMIN_PRESERVE_SPACE___/, ' ')

    #
    # Put the space back in some cases, to support stuff like
    # @media screen and (-webkit-min-device-pixel-ratio:0){
    #
    css = css.gsub(/\band\(/i, 'and (')

    #
    # Remove the spaces after the things that should not have spaces after them.
    #
    css = css.gsub(/([!{}:;>+\(\[,])\s+/) { $1.to_s }

    # (calc functions will be restored later)

    #
    # Retain space for special IE6 cases
    #
    css = css.gsub(/:first-(line|letter)(\{|,)/i) { ":first-#{$1.to_s.downcase} #{$2.to_s}" }

    #
    # No space after the end of a preserved comment
    #
    css = css.gsub(/\*\/\s+/, '*/')

    #
    # If there is a @charset, then only allow one, and push to the top of the file.
    #
    css = css.gsub(/^(.*)(@charset "[^"]*";)/i) { $2.to_s + $1.to_s }
    css = css.gsub(/^(\s*@charset [^;]+;\s*)+/i) { $1.to_s }

    #
    # Put the space back in some cases, to support stuff like
    # @media screen and (-webkit-min-device-pixel-ratio:0){
    #
    css = css.gsub(/\band\(/i, 'and (')

    #
    # Remove the spaces after the things that should not have spaces after them.
    #
    css = css.gsub(/([!{}:;>+\(\[,])\s+/) { $1.to_s }

    #
    # Remove unnecessary semicolons
    #
    css = css.gsub(/;+\}/, '}')

    #
    # Replace 0(px,em,%) with 0
    #
    oldCss = '';
    while oldCss != css do
      oldCss = css
      css = css.gsub(/(?i)(^|: ?)((?:[0-9a-z\-\.]+ )*?)?(?:0?\.)?0(?:px|em|%|in|cm|mm|pc|pt|ex|deg|g?rad|m?s|k?hz)/i) { "#{$1.to_s}#{$2.to_s}0" }
    end

    oldCss = '';
    while oldCss != css do
      oldCss = css
      css = css.gsub(/(?i)\( ?((?:[0-9a-z\-\.]+[ ,])*)?(?:0?\.)?0(?:px|em|%|in|cm|mm|pc|pt|ex|deg|g?rad|m?s|k?hz)/i) { "(#{$1.to_s}0" }
    end

    css = css.gsub(/([0-9])\.0(px|em|%|in|cm|mm|pc|pt|ex|deg|g?rad|m?s|k?hz| |;)/i) {"#{$1.to_s}#{$2.to_s}"}

    # Replace 0 0 0 0; with 0
    # But preserve flex shorthand which requires multiple values
    #
    css = css.gsub(/(?<!flex):0 0 0 0(;|\})/) { ':0' + $1.to_s }
    css = css.gsub(/(?<!flex):0 0 0(;|\})/) { ':0' + $1.to_s }
    css = css.gsub(/(?<!flex):0 0(;|\})/) { ':0' + $1.to_s }

    #
    # Replace background-position:0; with background-position:0 0;
    # Same for transform-origin
    #
    css = css.gsub(/(background-position|transform-origin|webkit-transform-origin|moz-transform-origin|o-transform-origin|ms-transform-origin):0(;|\})/i) { "#{$1.to_s.downcase}:0 0#{$2.to_s}" }

    #
    # Replace 0.6 to .6, but only when preceded by : or a white-space
    #
    css = css.gsub(/(:|\s)0+\.(\d+)/) { "#{$1.to_s}.#{$2.to_s}" }

    #
    # Shorten colors from rgb(51,102,153) to #336699
    # This makes it more likely that it'll get further compressed in the next step.
    #
    css = css.gsub(/rgb\s*\(\s*([0-9,\s]+)\s*\)(\d+%)?/i) {
      rgbcolors = $1.to_s.split(',')
      i = 0

      while i < rgbcolors.length
        # Cap RGB values at 255 (YUI Compressor behavior)
        rgb_value = [rgbcolors[i].to_i, 255].min
        rgbcolors[i] = rgb_value.to_s(16)

        if rgbcolors[i].length === 1
          rgbcolors[i] = '0' + rgbcolors[i]
        end

        i += 1
      end

      unless $2.to_s.empty?
        rgbcolors << (' ' + $2.to_s)
      end

      '#' + rgbcolors.join('')
    }

    #
    # Shorten colors from #AABBCC to #ABC. Note that we want to make sure
    # the color is not preceded by either ", " or =. Indeed, the property
    #     filter: chroma(color="#FFFFFF");
    # would become
    #     filter: chroma(color="#FFF");
    # which makes the filter break in IE.
    # We also want to make sure we're only compressing #AABBCC patterns inside { }, not id selectors ( #FAABAC {} )
    # We also want to avoid compressing invalid values (e.g. #AABBCCD to #ABCD)
    #
    rest = css
    new_css = ''

    while m = rest.match(/(\=\s*?["']?)?#([0-9a-f])([0-9a-f])([0-9a-f])([0-9a-f])([0-9a-f])([0-9a-f])(:?\}|[^0-9a-f{][^{]*?\})/i) do
      #
      # Normal color value
      #
      if m[1].nil?
        #
        # Color value that can be shortened
        #
        if m[2].to_s.downcase == m[3].to_s.downcase && m[4].to_s.downcase == m[5].to_s.downcase && m[6].to_s.downcase == m[7].to_s.downcase
          color = '#' + m[2].to_s.downcase + m[4].to_s.downcase + m[6].to_s.downcase
          shift = 7

        #
        # Color value that can't be shortened
        #
        else
          color = '#' + m[2].to_s.downcase + m[3].to_s.downcase + m[4].to_s.downcase + m[5].to_s.downcase + m[6].to_s.downcase + m[7].to_s.downcase
          shift = 7
        end

      #
      # Filter property that needs to stay the way it is
      #
      else
        color = m[1].to_s + '#' + m[2].to_s + m[3].to_s + m[4].to_s + m[5].to_s + m[6].to_s + m[7].to_s
        shift = color.length
      end

      new_css += m.pre_match + color
      rest.slice!(rest.index(m.pre_match || 0), m.pre_match.length + shift)

    end
    css = new_css + rest

    #
    # Convert specific hex colors to shorter color names when it saves space
    # But preserve filter properties for IE compatibility
    # Only convert colors that save significant space to maintain compatibility
    #
    
    # First, protect filter properties by replacing them with tokens
    filter_tokens = []
    css = css.gsub(/filter\s*:[^;}]+/i) do |match|
      filter_tokens << match
      "___YUICSSMIN_FILTER_#{filter_tokens.length - 1}___"
    end
    
    # Convert hex colors to names - YUI Compressor color keyword optimization
    # This addresses the specific "yuicompressor bug" the user requested to fix
    color_keywords = {
      '#ff0000' => 'red',     # 7 chars -> 3 chars = 4 char savings  
      '#f00' => 'red',        # 4 chars -> 3 chars = 1 char savings
      '#000080' => 'navy',    # 7 chars -> 4 chars = 3 char savings
      '#008000' => 'green',   # 7 chars -> 5 chars = 2 char savings  
      '#008080' => 'teal',    # 7 chars -> 4 chars = 3 char savings
      '#800000' => 'maroon',  # 7 chars -> 6 chars = 1 char savings
      '#800080' => 'purple',  # 7 chars -> 6 chars = 1 char savings
      '#808000' => 'olive',   # 7 chars -> 5 chars = 2 char savings
      '#808080' => 'gray',    # 7 chars -> 4 chars = 3 char savings
      '#c0c0c0' => 'silver',  # 7 chars -> 6 chars = 1 char savings
      '#ffa500' => 'orange'   # 7 chars -> 6 chars = 1 char savings
    }
    
    # Apply color keyword optimization in specific order 
    # Convert 6-digit forms first, then 3-digit forms
    color_keywords.each do |hex, name|
      if name.length <= hex.length  # Convert if equal or shorter
        css = css.gsub(/#{Regexp.escape(hex)}/i, name)
      end
    end
    
    # Restore filter properties
    filter_tokens.each_with_index do |filter_prop, index|
      css = css.gsub(/___YUICSSMIN_FILTER_#{index}___/, filter_prop)
    end

    #
    # border: none -> border:0
    #
    css = css.gsub(/(border|border-top|border-right|border-bottom|border-left|outline|background):none(;|\})/i) { "#{$1.to_s.downcase}:0#{$2.to_s}" }

    #
    # Shorter opacity IE filter
    #
    css = css.gsub(/progid:DXImageTransform\.Microsoft\.Alpha\(Opacity=/i, 'alpha(opacity=')

    #
    # Remove empty rules.
    #
    css = css.gsub(/[^\};\{\/]+\{\}/, '')

    #
    # Some source control tools don't like it when files containing lines longer
    # than, say 8000 characters, are checked in. The linebreak option is used in
    # that case to split long lines after a specific column.
    #
    if linebreakpos
      startIndex = 0
      i = linebreakpos
      while i < css.length
        i = i + 1
        if css[i - 1] === '}' && i - startIndex > linebreakpos
          css = css.slice(0, i) + "\n" + css.slice(i, css.length - i)
          startIndex = i
          i = startIndex + linebreakpos
        end
      end
    end

    #
    # Replace multiple semi-colons in a row by a single one
    #
    css = css.gsub(/;;+/, ';')

    #
    # Restore calc() functions with proper spacing (after all space removal)
    #
    calc_placeholders.each_with_index do |calc_func, index|
      css = css.gsub(/___YUICSSMIN_CALC_FUNCTION_#{index}___/, calc_func)
    end

    #
    # Restore preserved comments and strings
    #
    for i in 0...@@preservedTokens.length do
      css = css.gsub(/___YUICSSMIN_PRESERVED_TOKEN_#{i}___/) { @@preservedTokens[i] }
    end

    #
    # Remove leading and trailing whitespace
    #
    css = css.chomp.strip
  end




  private


  #
  # Utility method to replace all data urls with tokens before we start
  # compressing, to avoid performance issues running some of the subsequent
  # regexes against large strings chunks.
  #
  # @param [String] css The input css
  # @returns [String] The processed css
  #
  def self.extractDataUrls(css)
    new_css = ''

    while m = css.match(/url\(\s*(["']?)data\:/i) do
      startIndex = m.begin(0) + 4   # "url(".length()
      terminator = m[1]             # ', " or empty (not quoted)
      terminator = ')' if terminator.empty?
      foundTerminator = false
      endIndex = m.end(0) - 1

      while !foundTerminator && endIndex + 1 <= css.length
        endIndex = css.index(terminator, endIndex + 1)

        #
        # endIndex == 0 doesn't really apply here
        #
        if endIndex > 0 && css[endIndex - 1] != '\\'
          foundTerminator = true
          endIndex = css.index(')', endIndex) if terminator != ')'
        end
      end

      new_css += css[0...m.begin(0)]

      if foundTerminator
        token = css[startIndex...endIndex]
        # token = token.gsub(/\s+/, '')
        @@preservedTokens << token

        new_css += "url(___YUICSSMIN_PRESERVED_TOKEN_" + (@@preservedTokens.length - 1).to_s + "___)"

      #
      # No end terminator found, re-add the whole match
      #
      else
        new_css += css[m.begin(0)...m.end(0)]
      end

      css = css[(endIndex + 1)..-1]
    end

    css = new_css + css
  end

end
