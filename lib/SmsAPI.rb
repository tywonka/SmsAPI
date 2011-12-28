# encoding: utf-8
require "SmsAPI/version"
require "builder"
require "rest_client"
require "simple_xml"

module SmsAPI
  	class SmsAPI

  		# Функция проверки баланса
	  	def self.getBalance(login, password)
		    xml = Builder::XmlMarkup.new( :indent => 2 )
		    xml.instruct! :xml, :encoding => "utf-8"
			xml.request { |b| b.security { |x| x.login("value" => login); 
				x.password("value" => password) } }
			response = RestClient.post 'http://xml.sms16.ru/xml/balance.php', 
			xml.target!, {:content_type => "text/xml; charset=utf-8"}
			doc = REXML::Document.new(response)
			h = Hash.new()
			if doc.elements.each('response/error').length > 0
				raise "Ошибка проверки баланса: " + 
					doc.elements.each('response/error').first.text
			end
			doc.elements.each('response/money') do |ele|
				h["money"] = ele.text + " " + ele.attributes["currency"]
			end
			doc.elements.each('response/sms') do |ele|
				h[ele.attributes["area"]] = ele.text
			end
			return h
	  	end

	  	# Функция получения списка отправителей
	  	def self.getSenders(login, password)
		    xml = Builder::XmlMarkup.new( :indent => 2 )
		    xml.instruct! :xml, :encoding => "utf-8"
			xml.request { |b| b.security { |x| x.login("value" => login); 
				x.password("value" => password) } }
			response = RestClient.post 'http://xml.sms16.ru/xml/originator.php', 
			xml.target!, {:content_type => "text/xml; charset=utf-8"}
			doc = REXML::Document.new(response)
			h = Hash.new()
			if doc.elements.each('response/error').length > 0
				raise "Ошибка получения списка отправителей: " + 
					doc.elements.each('response/error').first.text
			end
			doc.elements.each('response/any_originator') do |ele|
				h["Любой отправитель"] = ele.text
			end
			doc.elements.each('response/list_originator/originator') do |ele|
				h[ele.text] = ele.attributes["state"]
			end
			return h
	  	end

	  	# Функция получения входящих сообщений
	  	def self.getIncomingMsgs(login, password, startDate, endDate)
		    xml = Builder::XmlMarkup.new( :indent => 2 )
		    xml.instruct! :xml, :encoding => "utf-8"
			xml.request { |b| b.security { |x| x.login("value" => login); 
				x.password("value" => password) }; 
				b.time("start" => startDate, "end" => endDate) }
			response = RestClient.post 'http://xml.sms16.ru/xml/incoming.php', 
			xml.target!, {:content_type => "text/xml; charset=utf-8"}
			doc = REXML::Document.new(response)
			msgs = Array.new()
			if doc.elements.each('response/error').length > 0
				raise "Ошибка получения входящих сообщений: " + 
					doc.elements.each('response/error').first.text
			end
			if doc.elements.each('response/sms').length == 0
				raise "Входящих сообщений нет"
			end
			doc.elements.each('response/sms') do |ele|
				incMsg = Hash.new()
				incMsg["date_receive"] = ele.attributes["date_receive"]
				incMsg["phone"] = ele.attributes["phone"]
				incMsg["originator"] = ele.attributes["originator"]
				incMsg["text"] = ele.text
				msgs.put(incMsg)
			end
			return msgs
	  	end

	  	# Функция проверки состояния отправленных сообщений
	  	def self.getStates(login, password, smsIds)
	  		if (smsIds.length == 0)
	  			raise "Нет сообщений для проверки состояния. Необходимо отправить смс."
	  		end
		    xml = Builder::XmlMarkup.new( :indent => 2 )
		    xml.instruct! :xml, :encoding => "utf-8"
			xml.request { |b| b.security { |x| x.login("value" => login); 
				x.password("value" => password) };
				b.get_state { |s| smsIds.each { |m| s.id_sms(m) } } }
			response = RestClient.post 'http://xml.sms16.ru/xml/state.php', 
			xml.target!, {:content_type => "text/xml; charset=utf-8"}
			doc = REXML::Document.new(response)
			h = Hash.new()
			if doc.elements.each('response/error').length > 0
				raise "Ошибка проверки состояния отправленных сообщений: " + 
					doc.elements.each('response/error').first.text
			end
			doc.elements.each('response/state') do |ele|
				h[ele.attributes["id_sms"]] = ele.text
			end
			return h
	  	end

	  	# Функция отправки сообщения
	  	def self.sendMessage(login, password, type, sender, text, recs, vcard)
		    xml = Builder::XmlMarkup.new( :indent => 2 )
		    xml.instruct! :xml, :encoding => "utf-8"
			xml.request { |b| 
				b.message("type" => type) { |mes| mes.sender(sender); 
				mes.text(text); 
				if (type == "wappush" || type == "vcard")
					mes.url(vcard["url"]);
					mes.name(vcard["name"]);
					mes.phone("cell" => vcard["cell"], "work" => vcard["work"], "fax" => vcard["fax"]);
					mes.email(vcard["email"]);
					mes.position(vcard["position"]);
					mes.organization(vcard["organization"]);
					mes.address("post_office_box" => vcard["post_office_box"], 
					"street" => vcard["street"], "city" => vcard["city"],
					"region" => vcard["region"], "postal_code" => vcard["postal_code"],
					"country" => vcard["country"]);
					mes.additional(vcard["additional"]);
				end
				recs.each do |rec| 
					mes.abonent("phone" => rec["phone"], "number_sms" => 1 + recs.index(rec), 
					"client_id_sms" => Time.now.to_i + recs.index(rec), 
					"time_send" => "", "validity_period" => "" );
				end
				};
				b.security { |x| x.login("value" => login); 
				x.password("value" => password) } }
			response = RestClient.post 'http://xml.sms16.ru/xml/', 
			xml.target!, {:content_type => "text/xml; charset=utf-8"}
			doc = REXML::Document.new(response)
			states = Array.new()
			if doc.elements.each('response/error').length > 0
				raise "Ошибка отправки сообщения: " + 
					doc.elements.each('response/error').first.text
			end
			doc.elements.each('response/information') do |ele|
				state = Hash.new()
				state[ele.attributes["id_sms"]] = ele.text
				states.push(state)
			end
			return states
	  	end
  	end
end