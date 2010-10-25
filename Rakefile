# encoding: utf-8
=begin
Some description here
=end

require 'rack'
require 'thin'
require 'bundler/setup'
require 'nanoc3/tasks'
require 'nanoc3/cli'
require 'compass'
require 'rdiscount'

Compass.add_project_configuration('./lib/compass.rb')

desc "Runs autocompile/preview"
task :preview do
  # Run base
  Nanoc3::CLI::Base.shared_base.run(["autocompile","--handler=thin"])
end

desc "Runs compile/generate"
task :build do
  # Run base
  Nanoc3::CLI::Base.shared_base.run(["compile"])
end

namespace :create do
  desc "Creates a new article"
  task :article do
    require 'active_support/core_ext'
    require 'active_support/multibyte'
    @ymd = Time.now.to_s(:db).split(' ')[0]
    @lang = ""
    if !ENV['title']
      $stderr.puts "\t[error] Missing title argument.\n\tusage: rake create:article title='article title'"
      exit 1
    end
    ["en","hu","ro"].each do |lang|
      @lang = lang
      title = ENV['title'].capitalize
      path, filename, full_path = calc_path(title)

      if File.exists?(full_path)
        $stderr.puts "\t[error] Exists #{full_path}"
        exit 1
      end

      template = <<TEMPLATE
---
title: "#{title.titleize}"
created_at: #{@ymd}
kind: article
publish: true
lang: #{@lang}
tags: [misc]
excerpt: 
---

#{initial_content(lang)}
TEMPLATE

      FileUtils.mkdir_p(path) if !File.exists?(path)
      File.open(full_path, 'w') { |f| f.write(template) }
      $stdout.puts "\t[ok] Edit #{full_path}"
    end
  end

  def calc_path(title)
    year, month_day = @ymd.split('-', 2)
    path = "content/#{@lang}/" + year + "/" 
    filename = month_day + "-" + title.parameterize('_') + ".md"
    [path, filename, path + filename]
  end

  def initial_content(lang)
    case lang
    when "en"
      return "TODO: Add content to....."
    when "hu"
      return "Sajnos még nincsen fordítás!<br><br>A cikkek eredetileg angol nyelven vannak írva, tehát angol nyelvű verzió biztosan létezik:). Esetleg megprobálhatja a román nyelvű verziót is!"
    when "ro"
      return "Din păcate pagina încă nu este tradusă!<br><br>Paginile sunt scrise iniţial în limba engleză, deci versiunea engleză există :). Eventual mai puteţi încerca versiunea în limba maghiară!"
    end
  end
end
