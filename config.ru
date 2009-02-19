require 'rack/request'
require 'rack/response'
require 'rubygems' rescue nil
require 'sass' rescue nil
require 'red'
require 'optparse'
require 'ftools'

Object.instance_eval \
{include Red

module Rack
  class Herring
    HerringRoot = ::File.dirname(__FILE__)
    
    def call(env)
      $mc = MethodCompiler.new
      path_info = Request.new(env).path_info
      herring_path = HerringRoot + path_info
      data, headers = handle(herring_path)
      
      Response.new([], 200, headers) do |r|
        r.write data
      end.finish
    end
    
    def handle(path)
      case ::File.extname(path)
        when '.red'
          [rb_to_js(path), {"Content-Type" => "text/js"}]
        when '.html'
          [::File.read(path), {"Content-Type" => "text/html"}]
        when '.ico'
          ['', {"Content-Type" => "image/ico"}]
        when '.js'
          [::File.read(path), {"Content-Type" => "text/js"}]
        else
          ["", {}]
      end
    end
    
    def update_page(js_text)
      return if js_text.empty?
      js_text.translate_to_sexp_array.red!
    end
  end
end

if $0 == __FILE__
  require 'rack'
  require 'rack/showexceptions'
  rack_herr = Rack::Herring.new
  rack_lint = Rack::Lint.new(rack_herr)
  rack_show = Rack::ShowExceptions.new(rack_lint)
  Rack::Handler::WEBrick.run(rack_show, :Port => 9292)
end}

system 'clear'
puts "Starting up rack..."
use Rack::ShowExceptions
run Rack::Herring.new
puts "Rack is now running on port 9292"
