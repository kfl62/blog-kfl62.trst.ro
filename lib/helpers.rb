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
  date = item[:created_at]
  tags = item[:tags].join(" ,")
  sep = "&#149;"
  case item[:lang]
  when "ro"
    return ["Publicat la data de",date,sep,"în categoria",tags,sep].join(" ")
  when "hu"
    return ["Közzétéve",date,sep,"a",tags,"kategoriában",sep].join(" ")
  else
    return ["Published at",date,sep,"in",tags,sep].join(" ")
  end
end

def article_more(item)
  text = link = ""
  case item[:lang]
  when "ro"
    text = "Fragment: "
    link = "...articol complet..."
  when "hu"
    text = "Kivonat: "
    link = "...a cikk..."
  else
    text = "Excerpt: "
    link = "...read more..."
  end
  return "#{text} <span class=\"flri\"><a href=\"#{route_path(item)}\" title=\"#{item[:title]}\"}>#{link}</a></span>"
end

def article_excerpt(item)
  excerptize(item.compiled_content, {:length => 500})
end

# Creates in-memory tag pages from partial: layouts/_tag_page.haml
def create_tag_pages
  tag_set(items).each do |tag|
    items << Nanoc3::Item.new(
      "= render('_tag_page', :tag => '#{tag}')",           # use locals to pass data
      { :title => "Category: #{tag}", :is_hidden => true}, # do not include in sitemap.xml
      "/tags/#{tag}/",                                     # identifier
      :binary => false
    )
  end
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

