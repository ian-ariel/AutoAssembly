#!/bin/bash
echo "ATENÇÃO: Esse script deve ser executado no diretório onde o NextDenovo será instalado!"

# Verificar dependências
if ! command -v wget &> /dev/null || ! command -v tar &> /dev/null; then
  echo "Erro: 'wget' ou 'tar' não estão instalados. Instale-os antes de continuar."
  exit 1
fi

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
echo "Criando arquivo input.fofn..."
find "$input" -name '*.fastq*' > input.fofn
echo "Arquivo input.fofn criado com sucesso."

# Configurar run.cfg
read -p "Tipo de tarefa (all/correct/assemble): " task
if [[ "$task" != "all" && "$task" != "correct" && "$task" != "assemble" ]]; then
  echo "Erro: Tipo de tarefa inválido. Use 'all', 'correct' ou 'assemble'."
  exit 1
fi

read -p "Sobrescrever diretório? (yes/no): " rewrite
if [[ "$rewrite" != "yes" && "$rewrite" != "no" ]]; then
  echo "Erro: Valor inválido para 'rewrite'. Use 'yes' ou 'no'."
  exit 1
fi

read -p "Tipo de input (raw/corrected): " inputype
if [[ "$inputype" != "raw" && "$inputype" != "corrected" ]]; then
  echo "Erro: Tipo de input inválido. Use 'raw' ou 'corrected'."
  exit 1
fi

read -p "Tipo de reads (clr/hifi/ont): " readtype
if [[ "$readtype" != "clr" && "$readtype" != "hifi" && "$readtype" != "ont" ]]; then
  echo "Erro: Tipo de reads inválido. Use 'clr', 'hifi' ou 'ont'."
  exit 1
fi

read -p "Tamanho do genoma (ex: 5m): " size

# Verificar se o diretório de trabalho já existe
if [[ "$rewrite" == "no" && -d "$input/montagemND" ]]; then
  echo "Erro: O diretório $input/montagemND já existe. Defina 'rewrite = yes' para sobrescrevê-lo."
  exit 1
fi

# Gerar run.cfg
cat <<EOF > run.cfg
[General]
job_type = local
job_prefix = nextDenovo
task = $task
rewrite = $rewrite
deltmp = yes
rerun = 3
parallel_jobs = 4
input_type = $inputype
read_type = $readtype
input_fofn = $PWD/input.fofn  # Caminho absoluto
workdir = $input/montagemND

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

echo "Arquivo run.cfg gerado com sucesso."

# Executar NextDenovo
echo "Executando NextDenovo..."
./NextDenovo/nextDenovo run.cfg

echo "NextDenovo configurado e executado com sucesso!"
