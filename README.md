# Utilitários para o Praat

Este repositório contém dois scripts em R desenvolvidos para auxiliar no processamento de dados de fala utilizando o software **Praat**. Os utilitários foram criados para facilitar a geração de arquivos de legenda (**.srt**) e arquivos do tipo **TextGrid**, que são comumente usados para anotação fonética.

## Scripts Disponíveis

### 1. cria_srts.R
Gera arquivos de legenda (**.srt**) para todos os arquivos de áudio no formato **.wav** de uma pasta especificada. Utiliza a API da OpenAI para transcrição automática do áudio.

#### Dependências
- **R** (versão 4.0 ou superior recomendada)
- Pacotes: `httr`, `jsonlite`
- Chave de API da OpenAI

#### Uso
- O script irá percorrer a pasta especificada, processar os arquivos de áudio e salvar os arquivos **.srt** com base nas transcrições retornadas pela OpenAI.

### 2. srt_textgrid.R
Converte arquivos de legenda no formato **.srt** em arquivos **TextGrid**, compatíveis com o Praat. O TextGrid gerado manterá a segmentação temporal original do **.srt**.

#### Dependências
- **R** (versão 4.0 ou superior recomendada)
- Pacotes: `stringr`, `readr`

#### Uso
- O script busca arquivos **.srt** e **.wav** na pasta especificada e cria os arquivos **TextGrid** correspondentes.
