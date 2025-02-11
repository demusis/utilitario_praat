library(av)
library(curl)
library(httr)
library(jsonlite)

# Defina sua API key para o Whisper API da OpenAI
api_key <- "sua chave"

# Função para transcrever áudio e salvar em arquivo .srt
transcrever_audio <- function(caminho_audio, api_key, caminho_saida_srt) {
  resposta <- httr::POST(
    url = "https://api.openai.com/v1/audio/transcriptions",
    httr::add_headers(Authorization = paste("Bearer", api_key)),
    body = list(
      file            = httr::upload_file(caminho_audio),
      model           = "whisper-1",
      language        = "pt",
      response_format = "srt"
    ),
    encode = "multipart",
    httr::timeout(3600) # Tempo limite configurado
  )
  
  # Verificar se a resposta foi bem-sucedida
  if (httr::status_code(resposta) == 200) {
    conteudo_srt <- content(resposta, "text")
    writeLines(conteudo_srt, con = caminho_saida_srt)
    message(sprintf("Transcrição salva em: %s", caminho_saida_srt))
  } else {
    stop(sprintf("Erro na transcrição. Código HTTP: %d", httr::status_code(resposta)))
  }
}

# Diretório com os arquivos .wav
diretorio_audio <- "G:/Meu Drive/Em processamento/Protocolo 25251.2016/Em processamento/CD1 - Questionado/wav/erro"

# Diretório para salvar os arquivos .srt (pode ser o mesmo ou um subdiretório)
diretorio_saida <- file.path(diretorio_audio, "transcricoes_srt")
if (!dir.exists(diretorio_saida)) dir.create(diretorio_saida)

# Obter todos os arquivos .wav no diretório
arquivos_wav <- list.files(diretorio_audio, pattern = "\\.wav$", full.names = TRUE)

# Processar cada arquivo .wav
for (arquivo_wav in arquivos_wav) {
  # Nome do arquivo de saída .srt
  nome_arquivo_srt <- paste0(tools::file_path_sans_ext(basename(arquivo_wav)), ".srt")
  caminho_saida_srt <- file.path(diretorio_saida, nome_arquivo_srt)
  
  # Transcrever e salvar
  tryCatch({
    transcrever_audio(arquivo_wav, api_key, caminho_saida_srt)
  }, error = function(e) {
    message(sprintf("Erro ao processar o arquivo %s: %s", arquivo_wav, e$message))
  })
}
