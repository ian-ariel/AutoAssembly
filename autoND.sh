#!/bin/bash

# Verificar e instalar NextDenovo se necessário
if ! command -v nextDenovo &> /dev/null; then
  echo "Erro: NextDenovo não encontrado. Instalando..."
  wget https://github.com/Nextomics/NextDenovo/releases/latest/download/NextDenovo.tgz
  tar -vxzf NextDenovo.tgz
  export PATH="$PWD/NextDenovo:$PATH" # Adiciona ao PATH temporariamente
fi

# Preparar input
read -p "Qual o caminho das reads a serem montadas (sem / no final)? " input

# Verificar arquivos FASTQ
if [ -z "$(find "$input" -maxdepth 1 -name '*.fastq*' -print -quit)" ]; then
  echo "Erro: Não há arquivos FASTQ em $input."
  exit 1
fi

# Criar input.fofn no diretório atual
find "$input" -name '*.fastq*' > input.fofn

# Configurar run.cfg
read -p "Tipo de tarefa (all/correct/assemble): " task
read -p "Sobrescrever diretório? (yes/no): " rewrite
read -p "Tipo de input (raw/corrected): " inputype
read -p "Tipo de reads (clr/hifi/ont): " readtype
read -p "Tamanho do genoma (ex: 5m): " size

cat <<EOF > run.cfg
[General]
job_type = local
job_prefix = nextDenovo
task = $task
rewrite = $rewrite
deltmp = yes
rerun = 3
parallel_jobs = 10
input_type = $inputype
read_type = $readtype
input_fofn = $PWD/input.fofn  # Caminho absoluto
workdir = 01_rundir

[correct_option]
read_cutoff = 1k
genome_size = $size
pa_correction = 2
sort_options = -m 1g -t 2
minimap2_options_raw = -t 8
correction_options = -p 15

[assemble_option]
minimap2_options_cns = -t 8
nextgraph_options = -a 1
EOF

# Executar
nextDenovo $input/run.cfg
