require 'savon'
require 'bfabric'
require 'fgcz'
require 'csv'
require 'sushiApp'
require 'sushiToolBox'
require 'SushiWrap'

# TODO: why also has to force it from here?
module Savon
  module SOAP
    class Response
      def to_xml
        http.body.force_encoding('UTF-8')
      end
    end
  end
end

class ApplicationController < ActionController::Base
  include SushiToolBox
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery
  
  before_filter :authenticate_user!  
  
  def get_user_id
    if !session[:bf_user_id]
      if !current_user
        logger.error "No logged in user."
        0
      else
        bf = Bfabric.new(SushiFabric::Application.config.bfabric_user,
                         SushiFabric::Application.config.bfabric_password)
        session[:bf_user_id] = bf.get_user_id current_user.login
      end
    end
    session[:bf_user_id]
  end
  def runnable_application(data_set_headers)
    non_sushi_apps = ['sushiApp.rb', 'sushiToolBox.rb', 'SushiWrap.rb', 'optparse_ex.rb']
    sushi_apps = Dir['lib/*.rb'].select{|script| !non_sushi_apps.include?(File.basename(script))}.to_a.map{|script| File.basename(script)}
    sushi_apps.concat Dir['lib/*.sh'].map{|script| File.basename(script)}

    # filter application with data_set
    sushi_apps = sushi_apps.sort.select do |script|
      class_name = ''
      if script =~ /\.rb/
        class_name = script.gsub(/\.rb/,'')
        require class_name
      elsif script =~ /\.sh/
        class_name = script.gsub(/\.sh/,'')
        sushi_wrap = SushiWrap.new("lib/#{script}")
        sushi_wrap.define_class
      end
      sushi_app = eval(class_name).new
      required_columns = sushi_app.required_columns
      (required_columns - data_set_headers).empty?
    end
    sushi_apps
  end
end
