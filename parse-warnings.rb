require 'nokogiri'
require 'open-uri'
require 'json'

helpers do
  def parse_latest_warning()
    warning = {}
    doc = get_warning_web_page()

    warning["title"] = get_warning_title(doc)
    warning["attributes"] = get_warning_attributes(warning["title"])
    warning["link"] = get_warning_link(doc)

    doc_detail = get_warning_detail_web_page(warning["link"])
    warning["detail"] = get_warning_detail_content(doc_detail)
    warning["img"] = get_warning_detail_img(doc_detail)

    warning
  end

  def parse_warning_history()
    doc = get_warning_web_page()
    warning_history = get_list_of_warnings(doc)
    warning_history
  end

  def parse_active_warnings()
    warnings = get_warnings_from_first_two_pages
    grouped_actions = group_actions_by_index(warnings)
    active_warning_indexes = get_active_warning_indexes(grouped_actions)
    merged_warnings = merge_warnings_by_index(warnings)
    get_active_warnings(active_warning_indexes, merged_warnings)
  end

  def get_warnings_from_first_two_pages
    first_page = get_web_page("http://www.cdmb.gov.cn/index.php/Alarm/alarmlist/id/23/p/1.html")
    second_page = get_web_page("http://www.cdmb.gov.cn/index.php/Alarm/alarmlist/id/23/p/2.html")

    warnings_in_first_page = get_list_of_warnings(first_page)
    warnings_in_second_page = get_list_of_warnings(second_page)

    warnings = []
    warnings << warnings_in_first_page
    warnings << warnings_in_second_page

    warnings.flatten!.uniq
  end

  def group_actions_by_index(warnings)
    grouped_actions = {}

    return grouped_actions if warnings.nil?

    warnings.each { |item|
      index = extract_index(item["title"])
      grouped_actions[index] = [] unless grouped_actions.key?(index)
      grouped_actions[index] << extract_action(item["title"])
    }

    grouped_actions
  end

  def get_active_warning_indexes(grouped_actions)
    indexes = []
    grouped_actions.each_pair { |index, actions|
      indexes << index if actions.first != '解除'
    }
    indexes
  end

  def merge_warnings_by_index(warnings)
    merged_warnings = {}
    return merged_warnings if warnings.nil?

    warnings.each { |item|
      index = extract_index(item["title"])
      if !merged_warnings.key?(index)
        attributes = get_warning_attributes(item["title"])
        attributes["date"] = item["date"]
        attributes["link"] = item["link"]
        merged_warnings[index] = attributes
      end
    }

    merged_warnings
  end

  def get_active_warnings(active_indexes, merged_warnings)
    active_warnings = []

    active_indexes.each { |index|
      warning = merged_warnings.fetch(index)
      active_warnings << warning unless warning.nil?
    }

    active_warnings
  end

  def get_warning_web_page
    get_web_page("http://www.cdmb.gov.cn/alarm/alarmlist/")
  end

  def get_web_page(uri)
    Nokogiri::HTML(open(uri))
  end

  def get_warning_title(doc)
    doc.search('/html/body/div[2]/div[1]/div/div/div[2]/ul/li[1]/a')[0].content
  end

  def get_warning_attributes(title)
    attributes = {}
    attributes["action"] = extract_action(title)
    attributes["index"] = extract_index(title)
    attributes["kind"] = extract_kind(title)
    attributes["level"] = extract_level(title)
    attributes["additional"] = extract_additional_info(title)

    attributes
  end

  def extract_action(title)
    title.scan(/市.*?第/)[0][1..-2]
  end

  def extract_index(title)
    title.scan(/\d+/)[0]
  end

  def extract_kind(title)
    title.scan(/号.*色/)[0][1..-3]
  end

  def extract_level(title)
    title.scan(/.色/)[0]
  end

  def extract_additional_info(title)
    additional_info = title.scan(/信号.*/)[0][3..-3]
    additional_info = "" if additional_info.nil?

    additional_info
  end

  def get_warning_link(doc)
    doc.search('/html/body/div[2]/div[1]/div/div/div[2]/ul/li[1]/a')[0]['href']
  end


  def get_warning_detail_web_page(url)
    Nokogiri::HTML(open(url))
  end

  def get_warning_detail_content(doc_detail)
    doc_detail.search('/html/body/div[2]/div[1]/div/div/div[2]/div/div[2]/p[2]')[0].content.strip
  end

  def get_warning_detail_img(doc_detail)
    doc_detail.search('/html/body/div[2]/div[1]/div/div/div[2]/div/div[2]/p[3]/img')[0]['src']
  end

  def get_list_of_warnings(doc)
    warning_titles = doc.search('/html/body/div[2]/div[1]/div/div/div[2]/ul/li/a')
    warning_dates = doc.search('/html/body/div[2]/div[1]/div/div/div[2]/ul/li/span')

    history_list = []
    warning_titles.each_with_index { |item, index|
      history_item = {}
      history_item["title"] = item.content
      history_item["date"] = warning_dates[index].content
      history_item["link"] = item['href']
      history_list << history_item
    }

    history_list
  end
end
