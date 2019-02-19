#!/usr/bin/env ruby
# encoding: utf-8

require 'sushi_fabric'
require_relative 'global_variables'
include GlobalVariables

class CellRangerApp <  SushiFabric::SushiApp
  def initialize
    super
    @name = 'CellRangerCount'
    @analysis_category = 'SingleCell'
    @description =<<-EOS
This wrapper runs <a href='https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/count',>cellranger count</a> in Single-library analysis mode.
    EOS
    @required_columns = ['Name','RawDataDir','Species']
    @required_params = ['name']
    @params['cores'] = '8'
    @params['ram'] = '40'
    @params['scratch'] = '200'
    @params['name'] = 'CellRangerCount'
    @params['refBuild'] = ref_selector
    @params['refFeatureFile'] = 'genes.gtf'
    @params['featureLevel'] = 'gene'
    @params['TenXLibrary'] = ['GEX', 'VDJ']
    @params['TenXLibrary', 'description'] = 'Which 10X library? GEX or VDJ.'
    @params['scMode'] = ['SC', 'SN']
    @params['scMode', 'description'] = 'Single-cell or single-nuclei?'
    @params['chemistry'] = ['auto', 'threeprime', 'fiveprime', 'SC3Pv1', 'SC3Pv2', 'SC3Pv3', 'SC5P-PE', 'SC5P-R2']
    @params['chemistry', 'description'] = 'Assay configuration. NOTE: by default the assay configuration is detected automatically, which is the recommended mode.'
    @params['controlSeqs'] = ''
    @params['controlSeqs', 'description'] = 'The extra control sequences (such as spikein sequences) available in https://fgcz-gstore.uzh.ch/reference/controlSeqs.fa'
    @params['specialOptions'] = ''
    @params['mail'] = ""
    @modules = ["Dev/R"]
    @inherit_tags = ["B-Fabric"]
  end
  def set_default_parameters
  end
  def next_dataset
    report_dir = File.join(@result_dir,"#{@dataset['Name']}")
    dataset = {
      'Name'=>@dataset['Name'],
      'ResultDir [File]'=>report_dir,
      'Report [Link]'=>File.join(report_dir, 'outs/web_summary.html'),
      'BAM [Link]'=>File.join(report_dir, 'outs/possorted_genome_bam.bam'),
      'BAI [Link]'=>File.join(report_dir, 'outs/possorted_genome_bam.bam.bai'),
      'Species'=>@dataset['Species'],
      'refBuild'=>@params['refBuild'],
      'refFeatureFile'=>@params['refFeatureFile'],
      'featureLevel'=>@params['featureLevel'],
      'CountMatrix [Link]'=>File.join(report_dir, 'outs/filtered_feature_bc_matrix')
    }.merge(extract_columns(@inherit_tags))
    dataset
  end
  def commands
    run_RApp("EzAppCellRanger")
  end
end

if __FILE__ == $0

end
