#coding: utf-8
require 'bundler'
Bundler.require

require 'open-uri'
require 'pp'

require './GmailSend'
require './myid'

def main()
	url='https://www.grail-legends.com/rate/rate_index.html'

	html=getHtmlData(url)
	
	head=Array.new
	targetPriceList=Array.new
	
	#表のヘッドを取得
	html.xpath('//tr[@align="center" and @valign="middle"]/td').each_with_index do |data,i|
		head[i]=data.text
	end
	
	html.xpath('//tr[@align="center" and @bgcolor]').each_with_index do |data,i|
		targetPriceList[i]=Hash.new
		data.xpath('./td').each_with_index do |data,j|
			text=removeToken(data.text,["\n","\r","\t"])
			targetPriceList[i][head[j%6]]=text
		end
	end
	pp head
	pp targetPriceList

	gmailSend=GmailSend.new($senderAddress,$gmailPassword)
	html_body='<table border="1" rules="all">'+'<tr>'
	head.each do |data|
		html_body+='<td>'+data+'</td>'
	end
	html_body+='</tr>'
	targetPriceList.each do |data|
		html_body+='<tr>'
		data.each do |key,data1|
			html_body+='<td>'
			html_body+=data1
			html_body+='</td>'
		end
		html_body+='</tr>'
	end
	html_body+='</table>'

	text_html =Mail::Part.new do
		content_type 'text/html; charset=UTF-8'
		body html_body
	end
	gmailSend.setHtmlPart text_html
	gmailSend.sendMail('stockInfo589@gmail.com','目標株価',"a")
end

def getHtmlData(url)	
	html=open(url).read
	doc=Nokogiri::HTML.parse(html,nil,'utf-8')
	#p doc.title

	return doc
end

#deleteSymbolArrayで指定した複数の文字をtextから削除
#@params text 削除対象の文字列
#@params deleteSymbolArray 削除したい文字の配列
def removeToken(text,deleteSymbolArray=["\r","\n","\t"])
	deleteSymbolArray.each do |symbol|
		text.gsub!(symbol,"")
	end
	text.gsub!(/\u{00A0}/," ") #&nbsp;を削除
     
	return text
end

main()
