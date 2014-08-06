#!/usr/bin/env ruby

require "logger"

# CONFIGURATION
TSE_HOST = "http://divulgacand2014.tse.jus.br"
TSE_PATH = "/divulga-cand-2014/eleicao/2014/UF/%s/candidatos/cargo/%s"
PHOTO_PATH = "/divulga-cand-2014/eleicao/2014/UF/%s/foto/%s.jpg"
@estados = %w(AC AL AP AM BA CE DF ES GO MA MT MS MG 
              PA PB PR PE PI RJ RN RS RO RR SC SP SE TO) 
# Vetor cujo indice mapeia para o mesmo do site do TSE
@cargos  = [
  "Eleitor",
  "Presidente",
  "Vice-Presidente",
  "Governador",
  "Vice-Governador",
  "Senador",
  "Deputado Federal",
  "Deputado Estadual",
  "Deputado Distrital",
  "Senador 1o. Suplente",
  "Senador 2o. Suplente"
]
# Adicione os campos que você quer pegar e incluir no CSS
# page pode ser :lista ou :candidato
@campos = {
  "name" => {:selector => "", :page => :lista},
  "full_name" => {:selector => "", :page => :lista},
  "number" => {:selector => "", :page => :lista},
  "party" => {:selector => "", :page => :lista},
  "position" => {:selector => "", :page => :lista},
  "location" => {:selector => "", :page => :lista},
  "source_id" => {:selector => "", :page => :lista},
  "source_url" => {:selector => "", :page => :lista},
  "photo_url" => {:selector => "", :page => :candidato}
}
LIST_ITEM_SELECTOR = "#tbl-candidatos > tbody > tr > td > a"

OUTPUT_FILE             = "./output/lista_de_candidatos_zip.csv" 
LOGGER_LEVEL            = Logger::INFO
# END OF CONFIGURATION

require "rubygems"
require "mechanize"
require "uri"
require "csv"
require "smarter_csv"

# Sshhhh, don't tell anybody, I'm monkey patching
class Logger::LogDevice
  def add_log_header(file)
  end
end

@logger = Logger.new(STDOUT)
@logger.level = LOGGER_LEVEL
@logger.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime}] #{severity}: #{msg}\n"
end

unless File.exists?(OUTPUT_FILE)
  system "echo \"#{@campos.keys.join(",")}\" > "+ OUTPUT_FILE
end
file = File.open(OUTPUT_FILE, File::WRONLY | File::APPEND )
@output = Logger.new(file)
@output.formatter = proc do |severity, datetime, progname, msg|
  "#{msg}"
end

@logger.info "******************************"

def chupar_pagina(estado, cargo)
  page = @agent.get(TSE_HOST + (TSE_PATH % [estado,cargo]))
  cand = page.search("#tbl-candidatos > tbody > tr > td > a")
  cand.each do |c|
    linha = criar_candidato(c, estado, cargo)
    @output.info(linha.to_csv)
  end
end

def criar_candidato(c, estado, cargo)
  linha = []
  tds = c.parent.parent.search("td")
  linha << tds[1].text
  linha << c.text
  linha << tds[2].text
  linha << tds[4].text
  linha << @cargos[cargo]
  linha << estado
  source_id = c.attr("id").split("-")[1]
  linha << source_id
  #linha << TSE_HOST + c.attr("href")
  #linha << TSE_HOST + (PHOTO_PATH % [estado,source_id])
  return linha
end

@agent = Mechanize.new

@logger.info ">>[Presidente,BR]..."
chupar_pagina("BR", 1)
@logger.info ">>[Vice-Presidente,BR]..."
chupar_pagina("BR", 2)

@estados.each do |estado| 
  (3..10).each do |cargo|
    @logger.info ">>[#{estado},#{@cargos[cargo]}]..."
    chupar_pagina(estado, cargo)
  end
end

