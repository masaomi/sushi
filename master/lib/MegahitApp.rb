#!/usr/bin/env ruby
# encoding: utf-8
Version = '20181127-155223'

require 'sushi_fabric'
require_relative 'global_variables'
include GlobalVariables

class MegahitApp < SushiFabric::SushiApp
def initialize
super
@name = 'Megahit'
@analysis_category = 'Metagenomics'
@description =<<-EOS
Denovo metagenomics assembly with Megahit, and annotation with Prodigal and Diamond. 
<a href='https://drive5.com/uparse/'>https://drive5.com/uparse/</a>
<a href='https://github.com/hyattpd/prodigal/wiki'>https://github.com/hyattpd/prodigal/wiki</a>
<a href='https://github.com/bbuchfink/diamond'>https://github.com/bbuchfink/diamond</a>
  EOS
@required_columns = ['Name', 'Read1']
@required_params = ['megahitKmerList','diamondEvalue','diamondMaxSeqs']
@params['cores'] = '1'
@params['ram'] = '8'
@params['scratch'] = '10'
@params['megahitKmerList'] = '69,79,89'
@params['megahitKmerList', 'description'] = 'Comma-separated list of k-mer for the assembly.'
@params['diamondEvalue'] = '0.05'
@params['diamondEvalue', 'description'] = 'Blast e-value cut-off.'
@params['diamondMaxSeqs'] = '30'
@params['diamondMaxSeqs', 'description'] = 'Blast maximum number of sequences to report.'
@params['mail'] = ""
@inherit_tags = ["Factor", "B-Fabric", "Characteristic"]
@modules = ["Dev/R"]
end
  def preprocess
    if @params['paired']
      @required_columns << 'Read2'
    end
  end
  def set_default_parameters
     @params['paired'] = dataset_has_column?('Read2')
  end
def next_dataset
     {'Name'=>@dataset['Name'],
     'contigFile [File]' => File.join(@result_dir, "#{@dataset['Name']}.contigs.fasta"),
     'prodigalPredictionFile [File]' => File.join(@result_dir, "#{@dataset['Name']}.prodigalAnnotation.gff"),
     'diamondAnnotationFile [File]' => File.join(@result_dir, "#{@dataset['Name']}.annotatedProteins.tsv")
}
end
def commands
run_RApp("EzAppMegahit")
end
end

if __FILE__ == $0
end
