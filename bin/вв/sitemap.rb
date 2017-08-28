require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = 'https://yourhm.com.ua/'
SitemapGenerator::Sitemap.create do
  add '/pages', :changefreq => 'daily'
  add '/products', :changefreq => 'daily'
  add '/single', :changefreq => 'daily'
end
#  add '/pages', :changefreq => 'daily', :priority => 0.9
