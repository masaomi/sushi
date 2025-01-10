class DataSet < ActiveRecord::Base
#  attr_accessible :name, :md5, :comment
  has_many :samples
  has_many :jobs, :foreign_key => :next_dataset_id
  belongs_to :project
  has_many :data_sets, :foreign_key => :parent_id
  belongs_to :data_set, :foreign_key => :parent_id
  serialize :runnable_apps, Hash
  belongs_to :user
  serialize :order_ids, Array
  serialize :job_parameters, Hash

  def headers
    self.samples.map{|sample| sample.to_hash.keys}.flatten.uniq
  end
  def factor_first_headers
    headers.sort_by do |col| 
      if col == 'Name' 
        0
      elsif col.scan(/\[(.*)\]/).flatten.join =~ /Factor/
        1
      else
        2
      end
    end
  end
  def saved?
    if DataSet.find_by_md5(md5hexdigest)
      true
    else
      false
    end
  end
  def md5hexdigest
    key_value = self.samples.map{|sample| sample.key_value}.join + self.parent_id.to_s + self.project_id.to_s
    Digest::MD5.hexdigest(key_value)
  end
  def tsv_string
    string = CSV.generate(:col_sep=>"\t") do |out|
      out << headers
      self.samples.each do |sample|
        out << headers.map{|header| 
          val = sample.to_hash[header]
          val.to_s.empty? ? nil:val}
      end
    end
    string
  end
  def samples_length
    unless self.num_samples
      self.num_samples=self.samples.length
      self.save
    end
    self.num_samples
  end
  def check_order_ids
    order_ids_ = {}
    self.samples.each do |sample_|
      sample = sample_.to_hash
      if order_ids__ = sample["Order Id [B-Fabric]"]
        order_ids__.strip!
        order_ids__.split(",").each do |order_id|
          order_id.strip!
          order_ids_[order_id] = true
        end
      end
    end
    unless order_ids_.empty?
      self.order_ids.concat(order_ids_.keys)
      self.order_ids.uniq!
      self.order_ids.sort!

      # OrderID save
      if self.order_ids.uniq.length == 1 and order_id = self.order_ids.first.to_i
        self.order_id = order_id
      end

      self.save
    end
  end
  def register_bfabric(op = 'new', bfabric_application_number: nil, register_child_dataset_too: nil)
    register_command = "register_sushi_dataset_into_bfabric"
    check_command = "check_dataset_bfabric"
    parent_dataset = self.data_set
    if parent_dataset.nil? or parent_dataset.bfabric_id
      if SushiFabric::Application.config.fgcz? and system("which #{register_command} > /dev/null 2>&1") and system("which #{check_command} > /dev/null 2>&1")
        time = Time.new.strftime("%Y%m%d-%H%M%S")
        dataset_tsv = File.join(SushiFabric::Application.config.scratch_dir, "dataset.#{self.id}_#{time}.tsv")
        option_check = if ((op == 'new' or op == 'only_one') and !self.bfabric_id) or op == 'renewal'
                         true
                       elsif op == 'update' and bfabric_id = self.bfabric_id
                         com = "#{check_command} #{bfabric_id}"
                         puts "$ #{com}"
                         if out = `#{com}`
                           puts "# returned: #{out.chomp.downcase}"
                           eval(out.chomp.downcase)
                         end
                       end

        self.check_order_ids

        puts "parent_dataset.nil?= #{parent_dataset.nil?}"
        puts "self.order_ids= #{self.order_ids}"
        command = if self.order_ids.uniq.length == 1 and order_id = self.order_ids.first.to_i
                    if parent_dataset.nil? # root dataset
                      if order_id > 8000
                        [register_command, "o#{self.order_ids.first}", dataset_tsv, self.name, self.id, "--skip-file-check"].join(" ")
                      else
                        [register_command, "p#{self.project.number}", dataset_tsv, self.name, self.id, "--skip-file-check"].join(" ")
                      end
                    elsif parent_dataset and bfabric_id = parent_dataset.bfabric_id and register_child_dataset_too # child dataset
                      if order_id > 8000
                        [register_command, "o#{self.order_ids.first}", dataset_tsv, self.name, self.id, bfabric_id, "--sushi-app #{self.sushi_app_name} --skip-file-check"].join(" ")
                      else
                        [register_command, "p#{self.project.number}", dataset_tsv, self.name, self.id, bfabric_id, "--sushi-app #{self.sushi_app_name} --skip-file-check"].join(" ")
                      end
                    end
                  elsif self.order_ids.uniq.length > 1 # multi order dataset
                    if parent_dataset.nil? # root dataset
                        [register_command, "p#{self.project.number}", dataset_tsv, self.name, self.id, "--skip-file-check"].join(" ")
                    elsif parent_dataset and bfabric_id = parent_dataset.bfabric_id and register_child_dataset_too # child dataset
                        [register_command, "p#{self.project.number}", dataset_tsv, self.name, self.id, bfabric_id, "--sushi-app #{self.sushi_app_name} --skip-file-check"].join(" ")
                    end
                  end

        if command and bfabric_application_number
          command << " -a #{bfabric_application_number}"
        end
        if command and option_check
          open(dataset_tsv, "w") do |out|
            out.print self.tsv_string
          end
          puts "# created: #{dataset_tsv}"
          if File.exist?(dataset_tsv) and bfabric_ids = `#{command}`
            puts "$ #{command}"
            puts "# mode: #{op}"
            puts "# bfabric_ids: #{bfabric_ids}"
            if bfabric_ids.split(/\n/).uniq.length < 2
              workunit_id, dataset_id = bfabric_ids.chomp.split(',')
              if workunit_id.to_i > 0
                self.bfabric_id = dataset_id.to_i
                self.workunit_id = workunit_id.to_i
                puts "# DataSetID  (BFabric): #{self.bfabric_id}"
                puts "# WorkunitID (BFabric): #{self.workunit_id}"
                self.save
              end
            else
              puts "# Not executed properly:"
              puts "# BFabricID: #{bfabric_id}"
            end
            File.unlink dataset_tsv
            puts "# removed: #{dataset_tsv}"
          end
        else
          puts "# Not run DataSet#register_bfabric due to OrderID is missing in DataSet"
        end
        unless op == 'only_one'
          if child_data_sets = self.data_sets
            child_data_sets.each do |child_data_set|
              child_data_set.register_bfabric(op)
            end
          end
        end
      end
    else
      puts "# Not run DataSet#register_bfabric because its parental dataset is not registered in bfabric"
    end
  end
  def update_resource_size
    #command = "update_resource_size -w #{self.workunit_id} --test"
    command = "update_resource_size -w #{self.workunit_id}"
    #p command
    `#{command}`
  end
  def paths
    dirs = []
    samples.each do |sample|
      sample.to_hash.each do |header, file|
        if (header.tag?('File') or header.tag?('Link')) and file !~ /http/
          dirs << File.dirname(file)
        end
      end
    end
    dirs = dirs.map{|path| path.split('/')[0,2].join('/')}.uniq
  end
  def save_as_tsv(out_file=nil)
    file_name = out_file||"#{self.name}_dataset.tsv"
    File.write(file_name, tsv_string)
  end
end
