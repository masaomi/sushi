#!/usr/bin/env ruby
# encoding: utf-8
# Version = '20250110-141350'

require 'pathname'

RAILS_ROOT='/srv/sushi/production/master'
YEAR = Time.now.strftime("%Y")

help =-> () do
  puts <<-eos
  usage:
   #{File.basename(__FILE__)} [task name] (--run, --year [YEAR], --rails-root [RAILS_ROOT], --daemon-mode, --help)

  RAILS_ROOT (default): #{RAILS_ROOT}

  default (for test run):
   #{File.basename(__FILE__)} --year #{YEAR}

  recommend (for production run):
   #{File.basename(__FILE__)} --run --daemon-mode > #{File.basename(__FILE__).gsub(/.rb/, "_#{Time.now.strftime("%Y%m%d")}.log")}

  --daemon-mode
   * start the registraiton process at 0:00 AM every night

  e.g.:
   #{File.basename(__FILE__)} --year 2024
   #{File.basename(__FILE__)} --run
   #{File.basename(__FILE__)} --year 2024 --run
   #{File.basename(__FILE__)} ds:register_datasets[2024,]
   #{File.basename(__FILE__)} ds:register_datasets[2024,run]
  eos
  exit
end

if ARGV.index("-h") or ARGV.index("--help")
  help.()
end

run = ARGV.index("--run")
year = if i=ARGV.index("--year")
         ARGV[i+1]
       else
         Time.now.strftime("%Y")
       end

rails_root = if i=ARGV.index("--rails-root")
               ARGV[i+1]
             else
               Pathname.new(RAILS_ROOT)
             end
unless File.exist?(rails_root)
  warn "# WARN: #{rails_root} does not exist"
  help.()
end

daemon_mode = ARGV.index("--daemon-mode")

ENV['RAILS_ENV'] = 'production'
ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'

task_name_with_args = if ARGV[0] =~ /^ds\:register_datasets/
                        ARGV[0]
                      elsif run
                        "ds:register_datasets[#{year},run]"
                      else
                        "ds:register_datasets[#{year},]"
                      end

command = "bundle exec rake #{task_name_with_args}"
Dir.chdir(rails_root) do
  if daemon_mode
    loop do
      now = Time.now
      next_midnight = Time.new(now.year, now.month, now.day + 1, 0, 0, 0)
      wait_time = next_midnight - now
      sleep(wait_time)
      system(command)
    end
  else
    system(command)
  end
end


