# encoding: utf-8
=begin
Some description here
=end

include Nanoc3::Helpers::Blogging
include Nanoc3::Helpers::Rendering
include Nanoc3::Helpers::Text
include Nanoc3::Helpers::XMLSitemap

def route_path(item)
  # in-memory items have not file
  return item.identifier + "index.html" if item[:content_filename].nil?

  url = item[:content_filename].gsub(/^content/, '')

  # determine output extension
  extname = '.' + item[:extension].split('.').last
  outext = '.haml'
  if url.match(/(\.[a-zA-Z0-9]+){2}$/) # => *.html.erb, *.html.md ...
    outext = '' # remove 2nd extension
  elsif extname == ".sass"
    outext = '.css'
  else
    outext = '.html'
  end
  url.gsub!(extname, outext)

  if url.include?('-')
    url = url.split('-').join('/')  # /2010/01/01-some_title.html -> /2010/01/01/some_title.html
  end

  url
end

def translate_path(lang,item)
  "/#{lang}#{route_path(item).gsub(/^\/\w{2}\//,"/")}"
end

def article_meta(item)
  I18n.locale = item[:lang]
  date = item[:created_at]
  category = item[:category]
  sep = "&#149;"
  return [t('article.meta_01'),date,sep,t('article.meta_02'),"<b>#{category}</b>",t('article.meta_03'),sep].join(" ")
end

def article_more(item)
  I18n.locale = item[:lang]
  return "#{t('article.excerpt_01')} <span class=\"flri\"><a href=\"#{route_path(item)}\" title=\"#{item[:title]}\"}>#{t('article.excerpt_02')}</a></span>"
end

def article_excerpt(item,length=500)
  excerptize(item.compiled_content, {:length => length})
end

def create_tag_pages
  %w{ro hu en}.each do |lang|
    I18n.locale = lang
    tag_set(articles_in_lang(lang)).each do |tag|
      items << Nanoc3::Item.new(
        "= render('/shared/08_tag_page', :tag => '#{tag}')",
        { :title => "#{t('tags.title')}: #{tag}", :is_hidden => true, :lang => lang},
        "/#{lang}/tags/#{tag}/",
        :binary => false
      )
    end
  end
end

def articles_in_lang(lang)
  retval = []
  sorted_articles.each do |a|
    retval << a if a[:lang] == lang
  end
  retval
end

def add_update_item_attributes
  changes = Blog::FileChanges.new

  items.each do |item|
    # do not include assets or xml files in sitemap
    if item[:content_filename]
      ext = File.extname(route_path(item))
      item[:is_hidden] = true if item[:content_filename] =~ /assets\// || ext == '.xml'
    end

    if item[:kind] == "article"
      # filename might contain the created_at date
      item[:created_at] ||= derive_created_at(item)
      # sometimes nanoc3 stores created_at as Date instead of String causing a bunch of issues
      item[:created_at] = item[:created_at].to_s if item[:created_at].is_a?(Date)

      # sets updated_at based on content change date not file time
      change = changes.status(item[:content_filename], item[:created_at], item.raw_content)
      item[:updated_at] = change[:updated_at].to_s
    end
  end
end

def partial(identifier_or_item)
  item = !item.is_a?(Nanoc3::Item) ? identifier_or_item : item_by_identifier(identifier_or_item)
  item.compiled_content(:snapshot => :pre)
end

def item_by_identifier(identifier)
  items ||= @items
  items.find { |item| item.identifier == identifier }
end

#=> { 2010 => { 12 => [item0, item1], 3 => [item0, item2]}, 2009 => {12 => [...]}}
def articles_by_year_month
  result = {}
  current_year = current_month = year_h = month_a = nil

  sorted_articles.each do |item|
    d = Date.parse(item[:created_at])
    if current_year != d.year
      current_month = nil
      current_year = d.year
      year_h = result[current_year] = {}
    end

    if current_month != d.month
      current_month = d.month
      month_a = year_h[current_month] = []
    end

    month_a << item
  end

  result
end

def articles_nr_year(lang)
  nr = 0
  articles_by_year_month.each do |y,mh|
    mh.each do |m,aa|
      aa.each do |a|
        if lang == a[:lang]
          nr += 1
        end
      end
    end
  end
  return nr
end

def articles_nr_month(year,month,lang)
  nr = 0
  articles_by_year_month[year][month].each do |a|
    if lang == a[:lang]
      nr += 1
    end
  end
  return nr
end

def articles_by_category(lang)
  result = {}
  a = nil
  articles.each do |article|
    if lang == article[:lang]
      current_category = article[:category]
      if result[current_category].nil?
        a = result[current_category] = []
      else
        a = result[current_category]
      end
      a << article
    end
  end
  result
end

def tags_cloud(lang)
  retval = []
  tags = count_tags(articles_in_lang(lang))
  tags.sort_by{|k,v| k}.each do |tag|
    retval << "<a href='/#{lang}/tags/#{tag[0]}/'>#{tag[0]}(#{tag[1]})</a>"
  end
  retval
end

def is_front_page?
    @item.identifier == '/'
end

def site_name
  @config[:site_name]
end

def pretty_time(time)
  Time.parse(time).strftime("%b %d, %Y") if !time.nil?
end

def excerpt_count
  @config[:excerpt_count].to_i
end

def disqus_shortname
  @config[:disqus_shortname]
end

def disqus_developer
  @config[:disqus_developer]
end

def to_month_s(month)
  Date.new(2010, month).strftime("%B")
end

def t(string, options={})
  I18n.translate(string,options)
end

def gist(id,file=nil)
  src = "http://gist.github.com/#{id.to_s}.js"
  src += "?file=#{file}" unless file.nil?
  "<script src=\"#{src}\"></script>"
end

private

def derive_created_at(item)
  parts = item.identifier.gsub('-', '/').split('/')[1,3]
  date = '1980/1/1'
  begin
    Date.strptime(parts.join('/'), "%Y/%m/%d")
    date = parts.join('/')
  rescue
  end
  date
end

