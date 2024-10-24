#!/bin/bash
#Verificar se Canu está instalado e se não estiver, verificar se Conda está instalado.
if ! command -v canu &> /dev/null; then
    echo "Canu não está instalado. Instalando-o através do Conda"
    
    if ! command -v conda &> /dev/null; then
        echo "Conda não está instalado. Instalando-o..."
	wget https://repo.anaconda.com/archive/Anaconda3-2024.06-1-Linux-x86_64.sh
	chmod +x Anaconda3-2024.06-1-Linux-x86_64.sh
	./Anaconda3-2024.06-1-Linux-x86_64.sh
    fi
    conda install -c conda-forge -c bioconda -c defaults canu #Agora com conda instalado, instalar Canu
fi

#Perguntas de input de parâmetros

read -p "Qual o prefixo para os arquivos de saída? " prefix
read -p "Qual o caminho e o seu diretório de saída? " saida
read -p "Qual o tamanho esperado do genoma (<number>[g|m|k])? " size
read -p "Qual o máximo de memória para usar para essa tarefa? " memory
read -p "Qual o número de threads para dedicar a essa tarefa? " threads
read -p "Qual o seu tipo de leituras (-pacbio-raw | -pacbio-corrected | -nanopore-raw | -nanopore-corrected)? " long
read -p "Qual o caminho das reads a serem montadas? (*fastq ou *fastq.gz no final do caminho) " input

#aviso de falta de input
if ls "$input"/*.fastq* &> /dev/null; then
    :
else
    echo "Nenhum arquivo .fastq ou .fastq.gz encontrado em $input."
    exit 1
fi

#execução canu
echo "Execução do Canu iniciada com sucesso!"
canu -p "$prefix" -d "$saida" genomeSize="$size" maxMemory="$memory" maxThreads="$threads" "$long" "$input" gnuplotTested=true
