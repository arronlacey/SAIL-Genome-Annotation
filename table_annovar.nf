params.help = null
params.output_folder = "."
params.table_extension = "vcf"
params.cpu = 1
params.annovar_db = "humandb/"
params.mem = 4
params.buildver = "hg19"
params.annovar_params = "-protocol refGene,dbnsfp35a,clinvar_20180603,gnomad211_genome -operation gx,f,f,f -vcfinput -nastring ."

if (params.help) {
    log.info ''
    log.info '--------------------------------------------------------------'
    log.info 'table_annovar-nf: Nextflow pipeline to run TABLE ANNOVAR'
    log.info '--------------------------------------------------------------'
    log.info ''
    log.info 'Usage: '
    log.info 'nextflow run table_annovar.nf --table_folder myinputfolder'
    log.info ''
    log.info 'Mandatory arguments:'
    log.info '    --table_folder       FOLDER            Folder containing tables to process.'
    log.info 'Optional arguments:'
    log.info '    --cpu                INTEGER           Number of cpu used by annovar (default: 1).'
    log.info '    --mem                INTEGER           Size of memory (in GB) (default: 4).'
    log.info '    --output_folder      FOLDER		 Folder where output is written.'
    log.info '    --table_extension    STRING		 Extension of input tables (default: tsv).'
    log.info '    --annovar_db         FOLDER  	  	 Folder with annovar databases (default: Annovar_db)'
    log.info '    --buildver 	       STRING		 Version of genome build (default: hg19)'
    log.info '    --annovar_params     STRING		 Parameters given to table_annovar.pl (default: multiple databases--see README)'
    log.info ''
    exit 0
}

log.info "table_folder=${params.table_folder}"

tables = Channel.fromPath( params.table_folder).ifEmpty { error "empty table folder, please verify your input." }

annodb = file( params.annovar_db )

process annovar {
  cpus params.cpu
  memory params.mem+'G'
  tag { file_name }

  input:
  file table from tables
  file annodb

  output:
  file "*multianno*.txt" into output_annovar_txt
  file "*multianno*.vcf" optional true into output_annovar_vcf

  publishDir params.output_folder, mode: 'copy', pattern: '{*.txt}' 
  publishDir "${params.output_folder}/coding_changes", mode: 'copy', pattern: '{*.fa}'

  shell:
  file_name = table.baseName
  '''
  perl /home/arron/annovar-nextflow/table_annovar.pl !{params.table_folder} !{annodb} -buildver !{params.buildver} -out !{file_name} !{params.annovar_params}
  '''
}

process CompressAndIndex {
    tag { vcf_name }

    input:
    file(vcf) from output_annovar_vcf

    output:
    set file("*.vcf.gz"), file("*.vcf.gz.tbi") into output_annovar_vcfgztbi

    publishDir params.output_folder, mode: 'copy'

    shell:
    vcf_name = vcf.baseName
    '''
    bcftools view -O z !{vcf} > !{vcf_name}.vcf.gz
    bcftools index -t !{vcf_name}.vcf.gz
    '''
}
