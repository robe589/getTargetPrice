#coding: utf-8
require 'bundler'
Bundler.require

require 'open-uri'
require 'pp'

require './GmailSend'
require './myid'

def main()
	url='https://www.grail-legends.com/rate/rate_index.html'
	gmailSend=GmailSend.new($senderAddress,$gmailPassword)

	#サイトからソースを取得
	html=getHtmlData(url)
	#表のヘッドを取得
	head=getHeadToSite(html)
	#表のデータ部分を取得
	targetPriceList=getDataToSite(html,head)
	#表に現在の株価を追加
	insertNowPrice(head,targetPriceList)
	pp head
	pp targetPriceList
	#本日の更新分がないとき
	if targetPriceList==nil 
		text="本日更新のレーティング情報はありません\n"
		gmailSend.sendMail('stockInfo589@gmail.com','目標株価',text)
		return -1
	end
	#gmailで送る表のHTMLソースを作成
	html_body=makeHtmlSourceMatrix(head,targetPriceList)	
	#gmailに組み込むhtmlソースを作成
	uext_html =Mail::Part.new do
		content_type 'text/html; charset=UTF-8'
		body html_body
	end
	#メールで送信
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
	head[5]='目標株価'
	return head
end

#表のデータ部分を取得
#@params html 表を取得するサイトのHTMLデータ
#@params head 表のヘッド配列
#@return 取得した表データ
def getDataToSite(html,head)
	targetPriceList=Array.new
	today=Time.now.strftime("%-m/%-d")
	#本日更新分のみ取得
	html.xpath('//tr[@align="center" and @bgcolor]').each_with_index do |data,i|
		targetPriceList[i]=Hash.new
		data.xpath('./td').each_with_index do |data,j|
			text=removeToken(data.text,["\n","\r","\t"])
			#本日分のもののみ格納
			if head[j%6]=='日付' and today !=text
				return nil
			end
			targetPriceList[i][head[j%6]]=text
		end
	end
	return targetPriceList
end

#現在の株価をリストに追加
#@params head 表のヘッド配列
#@params targetPriceList 表のデータ配列
def insertNowPrice(head,targetPriceList)
	codeList=Array.new
	targetPriceList.each do |data|
		codeList.push data['コード']
	end
	pp codeList
	
	priceList=JpStock.price(:code=>codeList)
	pp priceList
	
	head.push "現在株価"
	priceList.each_with_index do |price,i|
		targetPriceList[i]["現在株価"]=price.close.to_s
	end
end

uHTMLの表を作成
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
