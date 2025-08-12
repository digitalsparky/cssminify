# coding: utf-8

require "spec_helper"


describe "CSSminify2" do

  context "application" do

    it "minifies CSS" do
      source = File.open(File.expand_path("../sample.css", __FILE__), "r:UTF-8").read
      minified = CSSminify2.compress(source)
      expect(minified.length).to be < source.length
      expect {
        CSSminify2.compress(minified)
      }.to_not raise_error
    end

    it "honors the specified maximum line length" do
      source = <<-EOS
        .classname1 {
            border: none;
            background: none;
            outline: none;
        }
        .classname2 {
            border: none;
            background: none;
            outline: none;
        }
      EOS
      minified = CSSminify2.compress(source, 30)
      expect(minified.split("\n").length).to eq(2)
      expect(minified).to eq(".classname1{border:0;background:0;outline:0}\n.classname2{border:0;background:0;outline:0}")
    end

    it "handles strings as input format" do
      expect {
        CSSminify2.compress(File.open(File.expand_path("../sample.css", __FILE__), "r:UTF-8").read)
      }.to_not raise_error
      expect(CSSminify2.compress(File.open(File.expand_path("../sample.css", __FILE__), "r:UTF-8").read)).to_not be_empty
    end

    it "handles files as input format" do
      expect {
        CSSminify2.compress(File.open(File.expand_path("../sample.css", __FILE__), "r:UTF-8"))
      }.to_not raise_error
      expect(CSSminify2.compress(File.open(File.expand_path("../sample.css", __FILE__), "r:UTF-8"))).to_not be_empty
    end

    it "works as both class and class instance" do
      expect {
        result1 = CSSminify2.compress(File.open(File.expand_path("../sample.css", __FILE__), "r:UTF-8").read)
        result2 = CSSminify2.new.compress(File.open(File.expand_path("../sample.css", __FILE__), "r:UTF-8").read)
        expect(result1).to_not be_empty
        expect(result2).to_not be_empty
      }.to_not raise_error
    end

  end


  context "compression" do

    it "removes comments and white space" do
      source = <<-EOS
        /*****
          Multi-line comment
          before a new class name
        *****/
        .classname {
            /* comment in declaration block */
            font-weight: normal;
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('.classname{font-weight:normal}')
    end

    it "preserves special comments" do
      source = <<-EOS
        /*!
          (c) Very Important Comment
        */
        .classname {
            /* comment in declaration block */
            font-weight: normal;
        }
      EOS
      result = <<-EOS
/*!
          (c) Very Important Comment
        */.classname{font-weight:normal}
      EOS
      expect(CSSminify2.compress(source) + "\n").to eq(result)
    end

    it "removes last semi-colon in a block" do
      source = <<-EOS
        .classname {
            border-top: 1px;
            border-bottom: 2px;
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('.classname{border-top:1px;border-bottom:2px}')
    end

    it "removes extra semi-colons" do
      source = <<-EOS
        .classname {
            border-top: 1px; ;
            border-bottom: 2px;;;
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('.classname{border-top:1px;border-bottom:2px}')
    end

    it "removes empty declarations" do
      source = <<-EOS
        .empty { ;}
        .nonempty {border: 0;}
      EOS
      expect(CSSminify2.compress(source)).to eq('.nonempty{border:0}')
    end

    it "simplifies zero values" do
      source = <<-EOS
        a {
            margin: 0px 0pt 0em 0%;
            background-position: 0 0ex;
            padding: 0in 0cm 0mm 0pc
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('a{margin:0;background-position:0 0;padding:0}')
    end

    it "simplifies zero values preserving unit when necessary" do
      source = <<-EOS
        @-webkit-keyframes anim {
          0% {
            left: 0;
          }
          100% {
            left: -100%;
          }
        }
        @-moz-keyframes anim {
          0% {
            left: 0;
          }
          100% {
            left: -100%;
          }
        }
        @-ms-keyframes anim {
          0% {
            left: 0;
          }
          100% {
            left: -100%;
          }
        }
        @-o-keyframes anim {
          0% {
            left: 0;
          }
          100% {
            left: -100%;
          }
        }
        @keyframes anim {
          0% {
            left: 0;
          }
          100% {
            left: -100%;
          }
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('@-webkit-keyframes anim{0%{left:0}100%{left:-100%}}@-moz-keyframes anim{0%{left:0}100%{left:-100%}}@-ms-keyframes anim{0%{left:0}100%{left:-100%}}@-o-keyframes anim{0%{left:0}100%{left:-100%}}@keyframes anim{0%{left:0}100%{left:-100%}}')
    end

    it "removes leading zeros from floats" do
      source = <<-EOS
        .classname {
            margin: 0.6px 0.333pt 1.2em 8.8cm;
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('.classname{margin:.6px .333pt 1.2em 8.8cm}')
    end

    it "removes leading zeros from groups" do
      source = <<-EOS
        a {
          margin: 0px 0pt 0em 0%;
          _padding-top: 0ex;
          background-position: 0 0;
          padding: 0in 0cm 0mm 0pc;
          transition: opacity .0s;
          transition-delay: 0.0ms;
          transform: rotate3d(0grad, 0rad, 0deg);
          pitch: 0khz;
          pitch:
        0hz /* intentionally on next line */;
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('a{margin:0;_padding-top:0;background-position:0 0;padding:0;transition:opacity 0;transition-delay:0;transform:rotate3d(0,0,0);pitch:0;pitch:0}')
    end

    it "simplifies color values but preserves filter properties, RGBa values and ID strings" do
      source = <<-EOS
        .color-me {
            color: rgb(123, 123, 123);
            border-color: #ffeedd;
            background: none repeat scroll 0 0 rgb(255, 0,0);
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('.color-me{color:#7b7b7b;border-color:#fed;background:none repeat scroll 0 0 red}')

      source = <<-EOS
        #AABBCC {
            color: rgba(1, 2, 3, 4);
            filter: chroma(color="#FFFFFF");
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('#AABBCC{color:rgba(1,2,3,4);filter:chroma(color="#FFFFFF")}')
    end

    it "only keeps the first charset declaration" do
      source = <<-EOS
        @charset "utf-8";
        #foo {
            border-width: 1px;
        }

        /* second css, merged */
        @charset "another one";
        #bar {
            border-width: 10px;
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('@charset "utf-8";#foo{border-width:1px}#bar{border-width:10px}')
    end

    it "simplifies the IE opacity filter syntax" do
      source = <<-EOS
        .classname {
            -ms-filter: "progid:DXImageTransform.Microsoft.Alpha(Opacity=80)"; /* IE 8 */
            filter: progid:DXImageTransform.Microsoft.Alpha(Opacity=80);       /* IE < 8 */
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('.classname{-ms-filter:"alpha(opacity=80)";filter:alpha(opacity=80)}')
    end

    it "replaces 'none' values with 0 where allowed" do
      source = <<-EOS
        .classname {
            border: none;
            background: none;
            outline: none;
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('.classname{border:0;background:0;outline:0}')
    end

    it "tolerates underscore/star hacks" do
      source = <<-EOS
        #element {
            width: 1px;
            *width: 2px;
            _width: 3px;
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('#element{width:1px;*width:2px;_width:3px}')
    end

    it "tolerates child selector hacks" do
      source = <<-EOS
        html >/**/ body p {
            color: blue;
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('html>/**/body p{color:blue}')
    end

    it "tolerates IE5/Mac hacks" do
      source = <<-EOS
        /* Ignore the next rule in IE mac \\*/
        .selector {
            color: khaki;
        }
        /* Stop ignoring in IE mac */
      EOS
      expect(CSSminify2.compress(source)).to eq('/*\*/.selector{color:khaki}/**/')
    end

    it "tolerates box model hacks" do
      source = <<-EOS
        #elem {
            width: 100px; /* IE */
            voice-family: "\\"}\\"";
            voice-family:inherit;
            width: 200px; /* others */
        }
        html>body #elem {
            width: 200px; /* others */
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('#elem{width:100px;voice-family:"\"}\"";voice-family:inherit;width:200px}html>body #elem{width:200px}')
    end

    it "keeps a space before opening brace in calc" do
      source = <<-EOS
        .content { 
          height: calc(35% - 30px);
          width: calc(35% - (30px / 2)); 
          background-image: url("./bg.png");
        }
      EOS
      expect(CSSminify2.compress(source)).to eq('.content{height:calc(35% - 30px);width:calc(35% - (30px / 2));background-image:url("./bg.png")}')
    end

    it "should pass all the original tests included in the YUI compressor package" do
      puts "Now running original YUI compressor test files:"

      files = Dir.glob(File.join(File.dirname(__FILE__), 'tests', '*.css'))

      for file in files do
        print "  -- testing #{file} ..."
        expect(CSSminify2.compress(File.read(file)).chomp.strip).to eq(File.read(file + '.min').chomp.strip)
        print "successful\n"
      end
    end

  end

end
