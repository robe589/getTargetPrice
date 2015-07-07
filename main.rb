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
	
	
	#表のヘッドを取得
	head=getHeadToSite(html)
	#表のデータ部分を取得
	targetPriceList=getDataToSite(html,head)
	pp head
	pp targetPriceList
	#gmailで送る表のHTMLソースを作成
	html_body=makeHtmlSourceMatrix(head,targetPriceList)	
	#gmailに組み込むhtmlソースを作成
	text_html =Mail::Part.new do
		content_type 'text/html; charset=UTF-8'
		body html_body
	end
	#メールで送信
	gmailSend=GmailSend.new($senderAddress,$gmailPassword)
	gmailSend.setHtmlPart text_html
	gmailSend.sendMail('stockInfo589@gmail.com','目標株価'," ")
end

def getHtmlData(url)	
	html=open(url).read
	doc=Nokogiri::HTML.parse(html,nil,'utf-8')
	#p doc.title

	return doc
end

#表のヘッドを取得
#@params html 表を取得するサイトのHTMLデータ
#return 取得したヘッドの配列
def getHeadToSite(html)
	head=Array.new
	#表のヘッドを取得
	html.xpath('//tr[@align="center" and @valign="middle"]/td').each_with_index do |data,i|
		head[i]=data.text
	end

	return head
end

#表のデータ部分を取得
#@params html 表を取得するサイトのHTMLデータ
#@params head 表のヘッド配列
#@return 取得した表データ
def getDataToSite(html,head)
	targetPriceList=Array.new
	#本日更新分のみ取得
	html.xpath('//tr[@align="center" and @bgcolor]').each_with_index do |data,i|
		targetPriceList[i]=Hash.new
		data.xpath('./td').each_with_index do |data,j|
			text=removeToken(data.text,["\n","\r","\t"])
			targetPriceList[i][head[j%6]]=text
		end
	end
	return targetPriceList
end

#HTMLの表を作成
#@params html 表を取得するサイトのHTMLデータ
#@params list 表のデータ配列
#@return 作成したHTMLソース
def makeHtmlSourceMatrix(head,list)
	htmlSource=String.new

	htmlSource+='<table border="1" rules="all">'+'<tr>'
	#表のヘッドを作成
	head.each do |data|
		htmlSource+='<td>'+data+'</td>'
	end
	#表のデータ部分を作成
	htmlSource+='</tr>'
	list.each do |data|
		htmlSource+='<tr>'
		data.each do |key,data1|
			htmlSource+='<td>'
			htmlSource+=data1
			htmlSource+='</td>'
		end
		htmlSource+='</tr>'
	end
	htmlSource+='</table>'
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
