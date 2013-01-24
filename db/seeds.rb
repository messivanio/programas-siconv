# encoding: utf-8

def load_data_from_csv(file)
  data = Array.new
  text = File.read(file)  
  csv = CSV.parse(text, :headers => true, :force_quotes => true, :col_sep => ',')
  columns = csv.headers
  
  csv.each do |row|
    row_data = Hash.new
    columns.each do |column|
      row_data[column] = row[column]
    end
    
    data << row_data
  end
  
  data
end

def get_tags_without_stopwords(text)
  return [] if text.nil? || text.empty?
  
  tags = text.split(/[\s\/]/)
  tags.each {|tag| tag.downcase! }
  tags.delete_if {|t| STOPWORDS.include? t }
end

def time_to_date_s(time)
  return '-' if time.nil?
  time.strftime '%d/%m/%Y'
end

shell.say 'Populando base de dados do projeto'
shell.say ''

tokens = LAST_EXTRACTION_DATE.split '/'
diff_days = ((Time.now - Time.new(tokens[2], tokens[1], tokens[0])) / 60 / 60 / 24).to_i
if diff_days > 1
  puts "Ignorando povoamento da base de dados porque a extração de dados não foi feita nos dois últimos dias.\n" +
       "Data da última extração: #{LAST_EXTRACTION_DATE}. Diferença: #{diff_days} dias."
  Process.exit 0
end

shell.say "Carregando dados de 'concedentes' do arquivo 'concedentes_db.csv'"
data = load_data_from_csv 'db/concedentes_db.csv'

concedentes = {}
data.each {|row| concedentes[row['id']] = row['nome'] }

shell.say ''
shell.say "Removendo (se existir) registros da coleção 'programas'"
Programa.delete_all
shell.say ''

shell.say "Carregando dados de 'programas' do arquivo 'programas_db.csv'"
data = load_data_from_csv 'db/programas_db.csv'

data.each do |row|
  data_disponibilizacao = nil
  if row['data_disponibilizacao']
    tokens = row['data_disponibilizacao'].split '-'    
    data_disponibilizacao = Time.new(tokens[0], tokens[1], tokens[2])
  end
  
  tagged_orgs = []
  org_exe = concedentes[row['orgao_executor']]
  tags = get_tags_without_stopwords(org_exe)
  tagged_orgs << org_exe
  
  org_sup = concedentes[row['orgao_superior']]
  tags.concat get_tags_without_stopwords(org_sup) unless tagged_orgs.include? org_sup
  tagged_orgs << org_sup
  
  org_mand = concedentes[row['orgao_mandatario']]
  tags.concat get_tags_without_stopwords(org_mand) unless tagged_orgs.include? org_mand
  tagged_orgs << org_mand
  
  org_vin = concedentes[row['orgao_vinculado']]
  tags.concat get_tags_without_stopwords(org_vin) unless tagged_orgs.include? org_vin
  tagged_orgs << org_vin
  
  Programa.create(:id => row['cod_programa_siconv'].to_i,
                  :data_disponibilizacao => data_disponibilizacao, :data_fim_recebimento_propostas => row['data_fim_recebimento_propostas'],
                  :data_inicio_recebimento_propostas => row['data_inicio_recebimento_propostas'], :data_fim_beneficiario_especifico => row['data_fim_beneficiario_especifico'],
                  :data_inicio_beneficiario_especifico => row['data_inicio_beneficiario_especifico'], :data_fim_emenda_parlamentar => row['data_fim_emenda_parlamentar'],
                  :data_inicio_emenda_parlamentar => row['data_inicio_emenda_parlamentar'],
                  :nome => row['nome'], :obriga_plano_trabalho => row['obriga_plano_trabalho'],
                  :orgao_executor => org_exe, :orgao_mandatario => org_mand,
                  :orgao_superior => org_sup, :orgao_vinculado => org_vin,
                  :tags => tags)
end

shell.say ''
shell.say 'Povoamento da base de dados concluído'

if PADRINO_ENV == 'production'
  shell.say ''
  shell.say 'Publicando programas disponibilizados recentemente no Twitter'

  # https://github.com/sferik/twitter
  Twitter.configure do |config|
    config.consumer_key = ENV['CONSUMER_KEY']
    config.consumer_secret = ENV['CONSUMER_SECRET']
    config.oauth_token = ENV['OAUTH_TOKEN']
    config.oauth_token_secret = ENV['OAUTH_TOKEN_SECRET']
  end

  Twitter.update "Extração de dados de Programas do Governo Federal realizada em #{LAST_EXTRACTION_DATE}."
  last_days = 10

  fb_post = "Divulgando Programas do Governo Federal disponibilizados nos últimos #{last_days} dias.\n"
  fb_post << "Extração de dados de Programas do Governo Federal realizada em #{LAST_EXTRACTION_DATE}.\n"
  programas = Programa.most_up_to_date_programs :last_days => last_days
  
  (programas.size - 1).downto(0) do |i|
    nome = (programas[i].nome.size > 70) ? "#{programas[i].nome[0, 67]}..." : programas[i].nome
    tweet = "#{nome} - (http://novosprogramas.herokuapp.com/programa/#{programas[i].id})"
    Twitter.update tweet
    
    fb_post << "\nPrograma: #{programas[i].nome}\n"
    fb_post << "Órgão Executor: #{programas[i].orgao_executor}\n"
    fb_post << "Data de disponibilização: #{time_to_date_s programas[i].data_disponibilizacao}\n"
  end

  Twitter.update "Divulgando Programas do Governo Federal disponibilizados nos últimos #{last_days} dias."

  shell.say ''
  shell.say 'Publicação de programas no Twitter concluída'
  
  shell.say ''
  shell.say 'Publicando programas disponibilizados recentemente no Facebook'
  
  # https://github.com/arsduo/koala
  Koala.http_service.http_options = {
    :ssl => { :ca_path => "/etc/ssl/certs" }
  }
  graph = Koala::Facebook::API.new(ENV['FACEBOOK_ACCESS_TOKEN'])
  graph.put_connections('opendata.convenios', 'feed', :message => fb_post)
  
  shell.say
  shell.say 'Publicação de programas no Facebook concluída'
end
