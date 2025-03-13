#!/bin/bash
echo "ATENÇÃO: Esse script deve ser executado no diretório onde o NextDenovo será instalado!"

# Verificar e configurar o NextDenovo
if [ ! -f "$PWD/NextDenovo/nextDenovo" ]; then
  echo "Erro: O script 'nextDenovo' não foi encontrado."
  echo "Este script deve ser executado no diretório onde o NextDenovo será instalado."
  
  # Baixar e instalar o NextDenovo
  echo "Instalando NextDenovo..."
  wget https://github.com/Nextomics/NextDenovo/releases/latest/download/NextDenovo.tgz
  tar -vxzf NextDenovo.tgz
  
  # Verificar se o script foi extraído corretamente
  if [ -f "$PWD/NextDenovo/nextDenovo" ]; then
    echo "NextDenovo instalado com sucesso."
    chmod +x "$PWD/NextDenovo/nextDenovo" # Dá permissão de execução
    export PATH="$PWD/NextDenovo:$PATH" # Adiciona ao PATH temporariamente
  else
    echo "Erro: Falha ao instalar o NextDenovo. Verifique o download."
    exit 1
  fi
else
  # Se o script já existe, garante permissão de execução
  chmod +x "$PWD/NextDenovo/nextDenovo"
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
./NextDenovo/nextDenovo run.cfg
