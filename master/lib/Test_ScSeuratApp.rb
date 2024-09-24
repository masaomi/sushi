#!/usr/bin/env ruby
# encoding: utf-8

require 'sushi_fabric'
require_relative 'global_variables'
include GlobalVariables


class Test_ScSeuratApp < SushiFabric::SushiApp
  def initialize
    super
    @name = 'ScSeurat'
    @params['process_mode'] = 'SAMPLE'
    @analysis_category = 'SingleCell'
    @description =<<-EOS
Single cell report<br/>
    EOS
    @required_columns = ['Name', 'Species', 'refBuild', 'CountMatrix', 'ResultDir', 'Condition']
    @required_params = ['name']
    # optional params
    @params['cores'] = '4'
    @params['ram'] = '100'
    @params['scratch'] = '100'
    @params['name'] = 'ScSeurat'
    @params['refBuild'] = ref_selector
    @params['refFeatureFile'] = 'genes.gtf'
    @params['geneCountModel'] = ''
    @params['geneCountModel', 'description'] = '(STARsolo Input Only) The gene count model, i.e. Solo features, to use from the previous step'
    @params['SCT.regress.CellCycle'] = false
    @params['SCT.regress.CellCycle', 'description'] = 'Choose CellCycle to be regressed out when using the SCTransform method if it is a bias.'
    @params['DE.method'] = ['wilcox', 'LR']
    @params['DE.method', 'description'] ='Method to be used when calculating gene cluster markers. Use LR if you want to include cell cycle in the regression model.'
    @params['min.pct'] = 0.1
    @params['min.pct', 'description'] = 'Used in calculating cluster markers: The minimum fraction of cells in either of the two tested populations.'
    @params['min.diff.pct'] = 0.1
    @params['min.diff.pct', 'description'] = 'Used for filtering cluster markers: The minimum difference of cell fraction of the two tested populations.'
    @params['pvalue_allMarkers'] = 0.01
    @params['pvalue_allMarkers', 'description'] = 'Used for filtering cluster markers: adjusted pValue threshold for marker detection.'
    @params['logfc.threshold'] = 0.25
    @params['logfc.threshold', 'description'] = 'Used in calculating cluster markers: Limit testing to genes which show, on average, at least X-fold difference (log-scale) between the two groups of cells.'
    @params['tissue'] = []
    @params['tissue','multi_selection'] = true
    @params['tissue','all_selected'] = true
    @params['tissue', 'multi_selection_size'] = 10
    tissue = {}
    CSV.foreach("/srv/GT/databases/scGeneSets/CellMarker_2.0-2023-09-27/Cell_marker_All_tissueList.txt", headers: true, col_sep: "\t") do |e|
      tissue[e["tissue_class"]] = true
    end
    @params['tissue'] = tissue.keys.sort
    @params['tissue', 'description'] = 'Select the tissues from the CellMarker2 database to identify celltypes using AUCell'
    @params['enrichrDatabase'] = ['Tabula_Muris', 'Tabula_Sapiens', 'Azimuth_Cell_Types_2021', 'PanglaoDB_Augmented_2021', 
                                  'CellMarker_Augmented_2021', 'Allen_Brain_Atlas_10x_scRNA_2021', 'Human_Gene_Atlas', 'Mouse_Gene_Atlas', ]
    @params['enrichrDatabase','multi_selection'] = true
    @params['enrichrDatabase','all_selected'] = true
    @params['Azimuth'] = ["none", "adiposeref", "bonemarrowref", "fetusref", "heartref", "humancortexref", 
                          "kidneyref", "lungref", "mousecortexref", "pancreasref", "pbmcref", "tonsilref","/srv/GT/databases/Azimuth/humanLiver_Azimuth_v1.0"]
    @params['SingleR'] = ['none', 'BlueprintEncodeData', 'DatabaseImmuneCellExpressionData', 'HumanPrimaryCellAtlasData', 
                          'ImmGenData', 'MonacoImmuneData', 'MouseRNAseqData', 'NovershternHematopoieticData']
    @params['SingleR', 'description'] = "Use reference datasets from the celldex package to find marker-based celltype annotation with SingleR"
  
  
    @params['cellxgene_URL_rds', 'description'] = 'Input the dataset rds downloading URL'
    #@params['cellxgene', 'description'] = 'Find the dataset id that you want to use, on the datasets page but not on the collections page. First, click the "explore" button of the interest datasets. Second, input the data set ID from the website address. For example, "https://cellxgene.cziscience.com/e/3faad104-2ab8-4434-816d-474d8d2641db.cxg/", the data set ID is "3faad104-2ab8-4434-816d-474d8d2641db".'
    @params['cellxgene_column_name_of_cell_label', 'description'] = 'Choose the column name of cell label that you want to use on the explore web page'
    #@params['column_name_of_cell_label', 'description'] = 'After clicking the "explore" button, on the left you will find the column name of cell label. For example, in this dataset, "https://cellxgene.cziscience.com/e/3faad104-2ab8-4434-816d-474d8d2641db.cxg/", the cell label name is "predicted.celltype.l2".'
   
   
   
   
    @params['npcs'] = 20
    @params['npcs', 'description'] = 'The maximal top dimensions (pcs) to use for reduction. Do not use more principal components than pcGenes (when used).'
    @params['pcGenes'] = ''
    @params['pcGenes', 'description'] = 'The genes used in supervised clustering'
    @params['resolution'] = [0.6, 0.2, 0.4, 0.6, 0.8, 1]
    @params['resolution', 'description'] = 'Clustering resolution. A higher number will lead to more clusters.'
    @params['nreads'] = ''
    @params['nreads', 'description'] = "Low quality cells have less than 'nreads' reads. Only when applying fixed thresholds"
    @params['ngenes'] = ''
    @params['ngenes', 'description'] = "Low quality cells have less than 'ngenes' genes. Only when applying fixed thresholds"
    @params['perc_mito'] = ''
    @params['perc_mito', 'description'] = "Low quality cells have more than 'perc_mito' percent of mitochondrial genes. Only when applying fixed thresholds"
    @params['perc_riboprot'] = '70'
    @params['perc_riboprot', 'description'] = "Low quality cells have more than 'perc_ribo' percent of ribosomal genes. Only when applying fixed thresholds"
    @params['cellsFraction'] = 0.0001
    @params['cellsFraction', 'description'] = 'A gene will be kept if it is expressed in at least this fraction of cells'
    @params['nUMIs'] = 1
    @params['nUMIs', 'description'] = 'A gene will be kept if it has at least nUMIs in the fraction of cells specified before'
    @params['filterByExpression'] = ''
    @params['filterByExpression', 'description'] = 'Keep cells according to specific gene expression. i.e. Set > 1 | Pkn3 > 1'
    @params['estimateAmbient'] = true
    @params['estimateAmbient', 'description'] = 'run SoupX and DecontX to estimate ambientRNA levels'
    @params['computePathwayTFActivity'] = false
    @params['computePathwayTFActivity', 'description'] = 'Whether to calculate the TF and pathway activities (Note: Only for human and mouse)'
    @params['specialOptions'] = ''
    @params['mail'] = ""
    @modules = ["Dev/R"]
    @inherit_tags = ["Factor", "B-Fabric"]
  end
  def preprocess
    @random_string = (1..12).map{[*('a'..'z')].sample}.join
  end
  def next_dataset
    report_file = File.join(@result_dir, "#{@dataset['Name']}_SCReport")
    report_link = File.join(report_file, '00index.html')
    {'Name'=>@dataset['Name'],
     'Species'=>@dataset['Species'],
     'refBuild'=>@params['refBuild'],
     'refFeatureFile'=>@params['refFeatureFile'],
     'Static Report [Link]'=>report_link,
     'SC Cluster Report [File]'=>report_file,
     'SC Seurat'=>File.join(report_file, "scData.qs"),
    }.merge(extract_columns(@inherit_tags))
  end
  def set_default_parameters
    @params['refBuild'] = @dataset[0]['refBuild']
    if dataset_has_column?('refFeatureFile')
      @params['refFeatureFile'] = @dataset[0]['refFeatureFile']
    end
    if dataset_has_column?('soloFeatures')
      @params['geneCountModel'] = @dataset[0]['soloFeatures'].split(',')
    else
      @params.delete('geneCountModel')
    end
  end
  def commands
    #command = "module load #{@params["Rversion"]}\n"
    run_RApp("EzAppScSeurat")
  end
end

if __FILE__ == $0

end

