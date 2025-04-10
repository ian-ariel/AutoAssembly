#!/bin/bash
echo "ATENÇÃO: Esse script deve ser executado no diretório onde o NextDenovo será instalado!"

# Função para instalar dependências
install_dependencies() {
  echo "Instalando dependências..."
  if command -v apt-get &> /dev/null; then
    # Para sistemas baseados em Debian/Ubuntu
    sudo apt-get update
    sudo apt-get install -y wget tar python3
  elif command -v yum &> /dev/null; then
    # Para sistemas baseados em RHEL/CentOS
    sudo yum install -y wget tar python3
  elif command -v dnf &> /dev/null; then
    # Para sistemas baseados em Fedora
    sudo dnf install -y wget tar python3
  elif command -v zypper &> /dev/null; then
    # Para sistemas baseados em openSUSE
    sudo zypper install -y wget tar python3
  elif command -v pacman &> /dev/null; then
    # Para sistemas baseados em Arch Linux
    sudo pacman -Syu --noconfirm wget tar python
  else
    echo "Erro: Gerenciador de pacotes não suportado. Instale manualmente: wget, tar, python3 e pip."
    exit 1
  fi

  # Instalar pip se não estiver instalado
  if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
    echo "Instalando pip..."
    wget https://bootstrap.pypa.io/get-pip.py
    python3 get-pip.py
    rm get-pip.py
  fi

  # Instalar paralleltask usando pip
  echo "Instalando paralleltask..."
  pip install paralleltask
}

# Verificar e instalar dependências
if ! command -v wget &> /dev/null || ! command -v tar &> /dev/null || ! command -v python3 &> /dev/null || ! pip show paralleltask &> /dev/null; then
  echo "Dependências faltando: wget, tar, python3 ou paralleltask."
  install_dependencies
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

#!/bin/bash
echo "ATENÇÃO: Esse script deve ser executado no diretório onde o NextDenovo será instalado!"

# [Seção de instalação de dependências permanece igual...]

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

# Escolha do número de tarefas paralelas
read -p "Número de tarefas paralelas (recomendado: 4): " parallel_jobs
if ! [[ "$parallel_jobs" =~ ^[0-9]+$ ]]; then
  echo "Erro: O número de tarefas paralelas deve ser um valor numérico."
  exit 1
fi

# Escolha do número de threads para minimap2
read -p "Número de threads para minimap2 (recomendado: 8): " threads
if ! [[ "$threads" =~ ^[0-9]+$ ]]; then
  echo "Erro: O número de threads deve ser um valor numérico."
  exit 1
fi

# Verificar e criar/limpar diretório de trabalho
if [[ -d "$input/montagemND" ]]; then
    if [[ "$rewrite" == "yes" ]]; then
        echo "Aviso: O diretório $input/montagemND já existe e será sobrescrito."
        rm -rf "$input/montagemND"
        mkdir -p "$input/montagemND"
    else
        echo "Erro: O diretório $input/montagemND já existe. Defina 'rewrite = yes' para sobrescrevê-lo."
        exit 1
    fi
else
    echo "Criando diretório $input/montagemND..."
    mkdir -p "$input/montagemND"
fi

# Gerar run.cfg corretamente formatado
echo "Gerando arquivo run.cfg..."
cat > run.cfg <<EOF
[General]
job_type = local
job_prefix = nextDenovo
task = $task
rewrite = $rewrite
deltmp = yes
rerun = 3
parallel_jobs = $parallel_jobs
input_type = $inputype
read_type = $readtype
input_fofn = $PWD/input.fofn
workdir = $input/montagemND

[correct_option]
read_cutoff = 1k
genome_size = $size
pa_correction = 2
sort_options = -m 1g -t 2
minimap2_options_raw = -t $threads
correction_options = -p 15

[assemble_option]
minimap2_options_cns = -t $threads
nextgraph_options = -a 1
EOF

echo "Arquivo run.cfg gerado com sucesso."

# Executar NextDenovo
echo "Executando NextDenovo..."
./NextDenovo/nextDenovo run.cfg

echo "NextDenovo configurado e executado com sucesso!"
