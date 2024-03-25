#!/usr/bin/env ruby
# encoding: utf-8
Version = '20171109-095008'

require 'sushi_fabric'
require_relative 'global_variables'
include GlobalVariables

class ProdigalApp < SushiFabric::SushiApp
  def initialize
    super
    @name = 'Prodigal'
    @analysis_category = 'Annotate'
    @description =<<-EOS
Prodigal: rapid prokaryotic genome annotation
<a href='https://github.com/hyattpd/Prodigal'>https://github.com/hyattpd/Prodigal</a>
EOS
    @required_columns = ['Name','Draft']
    @required_params = ['cores', 'ram', 'scratch', 'kingdom']
    # optional params
    @params['cores'] = '4'
    @params['ram'] = '30'
    @params['scratch'] = '50'
    @params['translation_table'] = ['11']
    @params['translation_table', 'description'] = 'translation table to use (default 11)'
    @params['format'] = ['gbk']
    @params['format', 'description'] = 'Select output format (gbk, gff, or sco).  Default is gbk.'
    @params['cmdOptions'] = ''
    @params['cmdOptions', 'description'] = 'specify other commandline options for prokka; do not specify any option that is already covered by the dedicated input fields'
    @params['mail'] = ""
    @modules = ["Dev/R","Tools/Prodigal"]
    @inherit_tags = ["Factor", "B-Fabric", "Characteristic"]
  end
  def next_dataset
    {'Name'=>@dataset['Name'],
     'Out [File]'=>File.join(@result_dir, "#{@dataset['Name']}.genes"),
     'Proteins [File]'=>File.join(@result_dir, "#{@dataset['Name']}.proteins"),
     'Species'=>@dataset['Species'],
    }.merge(extract_columns(@inherit_tags))
  end
  def commands
    run_RApp("EzAppProdigal")
  end
end

if __FILE__ == $0
  run ProdigalApp
  #usecase = Bowtie2App.new

  #usecase.project = "p1001"
  #usecase.user = 'masamasa'

  # set user parameter
  # for GUI sushi
  #usecase.params['process_mode'].value = 'SAMPLE'
  #usecase.params['refBuild'] = 'mm10'
  #usecase.params['paired'] = true
  #usecase.params['strandMode'] = 'both'
  #usecase.params['cores'] = 8
  #usecase.params['node'] = 'fgcz-c-048'

  # also possible to load a parameterset csv file
  # mainly for CUI sushi
  #usecase.parameterset_tsv_file = 'tophat_parameterset.tsv'
  #usecase.parameterset_tsv_file = 'test.tsv'

  # set input dataset
  # mainly for CUI sushi
  #usecase.dataset_tsv_file = 'tophat_dataset.tsv'

  # also possible to load a input dataset from Sushi DB
  #usecase.dataset_sushi_id = 3

  # run (submit to workflow_manager)

end

