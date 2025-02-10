# -----------------------------
# Script em R para converter SRT em TextGrid
# Ajustando xmax para não ultrapassar a duração do áudio
# Ignorando intervalos onde xmin > xmax do áudio
# -----------------------------

# Carrega o pacote necessário
library(tuneR)

# Ajuste o caminho do diretório onde estão os arquivos .srt e .wav
dir_path <- "G:/Meu Drive/Em processamento/Protocolo 006886.2025 Comparação de locutor/Em processamento/Padrão"
setwd(dir_path)

# Função para converter tempo SRT (HH:MM:SS,mmm) em segundos
time_to_seconds <- function(timestr) {
  parts <- strsplit(timestr, ":")[[1]]
  hh <- as.numeric(parts[1])
  mm <- as.numeric(parts[2])
  ss_millis <- strsplit(parts[3], ",")[[1]]
  ss <- as.numeric(ss_millis[1])
  ms <- as.numeric(ss_millis[2]) / 1000
  return(hh * 3600 + mm * 60 + ss + ms)
}

# Lista todos os arquivos .srt no diretório
srt_files <- list.files(path = dir_path, pattern = "\\.srt$", full.names = TRUE)

if (length(srt_files) == 0) {
  cat("Nenhum arquivo .srt encontrado no diretório especificado.\n")
}

# Processa cada arquivo SRT
for (srt_file in srt_files) {
  base_name <- tools::file_path_sans_ext(basename(srt_file))
  wav_file <- file.path(dir_path, paste0(base_name, ".wav"))
  
  if (!file.exists(wav_file)) {
    cat("Aviso: arquivo WAV não encontrado para:", base_name, "\n")
    next
  }
  
  textgrid_file <- file.path(dir_path, paste0(base_name, ".TextGrid"))
  srt_lines <- readLines(srt_file, encoding = "UTF-8")
  
  # Obtém a duração do áudio com o pacote tuneR
  audio <- readWave(wav_file, header = TRUE)  # Lê apenas o cabeçalho
  audio_duration <- audio$samples / audio$sample.rate  # Duração em segundos
  
  subtitle_indices <- c()
  start_times <- c()
  end_times <- c()
  texts <- c()
  
  i <- 1
  n_lines <- length(srt_lines)
  
  while (i <= n_lines) {
    index_line <- gsub("\\s+", "", srt_lines[i])
    if (index_line == "") {
      i <- i + 1
      next
    }
    
    subtitle_index <- as.numeric(index_line)
    i <- i + 1
    time_parts <- strsplit(srt_lines[i], " --> ")[[1]]
    start_time <- time_to_seconds(time_parts[1])
    end_time <- time_to_seconds(time_parts[2])
    
    i <- i + 1
    text_block <- c()
    while (i <= n_lines && srt_lines[i] != "") {
      text_block <- c(text_block, srt_lines[i])
      i <- i + 1
    }
    
    subtitle_text <- paste(text_block, collapse = " ")
    
    # **Ignorar intervalos onde xmin > duração do áudio**
    if (start_time > audio_duration) {
      cat("Ignorando legenda fora do áudio:", subtitle_text, "\n")
      next
    }
    
    # **Ajustar xmax caso ultrapasse a duração do áudio**
    if (end_time > audio_duration) {
      end_time <- audio_duration
    }
    
    # **Ignora intervalos onde xmin == xmax**
    if (start_time != end_time) {
      subtitle_indices <- c(subtitle_indices, subtitle_index)
      start_times <- c(start_times, start_time)
      end_times <- c(end_times, end_time)
      texts <- c(texts, subtitle_text)
    }
    
    i <- i + 1
  }
  
  df_subtitles <- data.frame(index = subtitle_indices, start = start_times, end = end_times, text = texts, stringsAsFactors = FALSE)
  df_subtitles <- df_subtitles[order(df_subtitles$start), ]
  
  df_intervals <- data.frame(start = numeric(0), end = numeric(0), text = character(0), stringsAsFactors = FALSE)
  
  if (nrow(df_subtitles) > 0 && df_subtitles$start[1] > 0) {
    df_intervals <- rbind(df_intervals, data.frame(start = 0, end = df_subtitles$start[1], text = ""))
  }
  
  for (k in 1:nrow(df_subtitles)) {
    df_intervals <- rbind(df_intervals, data.frame(start = df_subtitles$start[k], end = df_subtitles$end[k], text = df_subtitles$text[k]))
    
    if (k < nrow(df_subtitles)) {
      next_start <- df_subtitles$start[k+1]
      if (df_subtitles$end[k] < next_start) {
        df_intervals <- rbind(df_intervals, data.frame(start = df_subtitles$end[k], end = next_start, text = ""))
      }
    }
  }
  
  # Define xmax como a duração do áudio
  global_min <- 0
  global_max <- audio_duration  # Agora sempre corresponde à duração real do áudio
  
  # Se o último intervalo terminar antes do áudio, adiciona um intervalo de silêncio até o final
  if (nrow(df_intervals) > 0 && df_intervals$end[nrow(df_intervals)] < global_max) {
    df_intervals <- rbind(df_intervals, data.frame(start = df_intervals$end[nrow(df_intervals)], end = global_max, text = ""))
  }
  
  # **Ignora intervalos onde xmin == xmax na exportação final**
  df_intervals <- df_intervals[df_intervals$start != df_intervals$end, ]
  
  # Cria o cabeçalho do TextGrid
  textgrid_header <- c(
    'File type = "ooTextFile"',
    'Object class = "TextGrid"',
    "",
    paste("xmin =", global_min),
    paste("xmax =", global_max),
    "tiers? <exists> = yes",
    "size = 1",
    "item []:",
    "    item [1]:",
    '        class = "IntervalTier"',
    '        name = "Legenda"',
    paste("        xmin =", global_min),
    paste("        xmax =", global_max),
    paste("        intervals: size =", nrow(df_intervals))
  )
  
  interval_lines <- c()
  for (j in 1:nrow(df_intervals)) {
    subtitle_start <- df_intervals$start[j]
    subtitle_end <- df_intervals$end[j]
    subtitle_text <- gsub('"', '\\"', df_intervals$text[j])
    
    interval_block <- c(
      paste0("        intervals [", j, "]:"),
      paste0("            xmin = ", subtitle_start),
      paste0("            xmax = ", subtitle_end),
      paste0("            text = \"", subtitle_text, "\"")
    )
    
    interval_lines <- c(interval_lines, interval_block)
  }
  
  textgrid_content <- c(textgrid_header, interval_lines)
  writeLines(textgrid_content, con = textgrid_file)
  
  cat("Arquivo TextGrid criado com sucesso para:", base_name, "\n")
}

cat("Processamento concluído.\n")
