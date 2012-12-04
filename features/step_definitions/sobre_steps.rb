# encoding: utf-8

Então /^eu devo ver a página de informações do projeto$/ do
  has_text? "Este sítio tem por objetivo viabilizar a consulta de programas de convênio disponibilizados no portal de convênios
do governo federal. Oferecer uma interface de consulta que possibilite encontrar os programas de convênio que foram
disponibilizados recentemente e um mecanismo de Feed. Os dados apresentados aqui foram retirados do <a href = 'http://www.convenios.gov.br'>Portal de
Convênios - Siconv</a>. Toda informação contida no Siconv é de caráter público e por isso pode e deve ser analisada pelos
cidadãos."
  has_text? "Desde 2008 está no ar o Portal de Convênios - Siconv. Sistema responsável pela tramitação de todo o processo de transferência voluntária."
  has_text? "Convênios são acordos, ajustes ou qualquer outro instrumento que discipline a transferência de recursos financeiros de dotações consignadas nos Orçamentos Fiscal e da Seguridade Social da União e tenha como participe, de um lado, órgão ou entidade da administração pública federal, direta ou indireta , ou ainda, entidades privadas sem fins lucrativos, visando a execução de programa de governo, envolvendo a realização de projeto, atividade, seviço, aquisição de bens ou evento de interesse recíproco, em regime de mútua cooperação."
  has_text? "Decreto nº 6.170, de 25 de julho de 2007"
  
  has_link? 'Voltar'
end