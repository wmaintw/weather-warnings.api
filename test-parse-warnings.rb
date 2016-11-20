require 'nokogiri'
require 'open-uri'
require 'json'

warning = {}
warning_attributes = {}

uri = "http://www.cdmb.gov.cn/alarm/alarmlist/"

doc = Nokogiri::HTML(open(uri))
latest_warning = doc.search('/html/body/div[2]/div[1]/div/div/div[2]/ul/li[1]/a')

warning_title = latest_warning[0].content
warning["title"] = warning_title

puts "#{warning_title}"
puts "------------------------------"
warning_action = warning_title.scan(/市.*第/)[0][1..-2]
warning_attributes["action"] = warning_action
puts "#{warning_action}"

warning_index = warning_title.scan(/\d+/)[0]
warning_attributes["index"] = warning_index
puts "第#{warning_index}号"

warning_kind = warning_title.scan(/号.*色/)[0][1..-3]
warning_attributes["kind"] = warning_kind
puts "#{warning_kind}"

warning_level = warning_title.scan(/.色/)[0]
warning_attributes["level"] = warning_level
puts "#{warning_level}"

warning_link = latest_warning[0]['href']
warning_attributes["link"] = warning_link
puts "#{warning_link}"

warning["attributes"] = warning_attributes

latest_warning_date = doc.search('/html/body/div[2]/div[1]/div/div/div[2]/ul/li[1]/span')
warning_date = latest_warning_date[0].content
warning["date"] = warning_date
puts "#{warning_date}"

puts "------------------------------"

uri_detail = latest_warning[0]['href']
doc_detail = Nokogiri::HTML(open(uri_detail))

warning_content = doc_detail.search('/html/body/div[2]/div[1]/div/div/div[2]/div/div[2]/p[2]')
warning_content_text = warning_content[0].content.strip
warning["detail"] = warning_content_text
puts "#{warning_content_text}"


warning_img  = doc_detail.search('/html/body/div[2]/div[1]/div/div/div[2]/div/div[2]/p[3]/img')
warning_img_link = warning_img[0]['src']
warning["img"] = warning_img_link
puts "#{warning_img_link}"

puts "------------------------------"
warning_list = doc.search('/html/body/div[2]/div[1]/div/div/div[2]/ul/li/a')
warning_list_date = doc.search('/html/body/div[2]/div[1]/div/div/div[2]/ul/li/span')

history_list = []
warning_list.each_with_index { |item, index|
  history_item = {}
  history_item["index"] = index + 1
  history_item["title"] = item.content
  history_item["date"] = warning_list_date[index].content
  history_list << history_item
  puts "#{index} - #{item.content} #{warning_list_date[index].content}"
}

warning["history"] = history_list

puts "------------------------------"
puts "#{warning}"