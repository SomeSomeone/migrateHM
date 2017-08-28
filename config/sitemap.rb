require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = "https://yourhm.com.ua/"
SitemapGenerator::Sitemap.compress = false
SitemapGenerator::Sitemap.create do
  Category.all.where(category_id: [nil,0]).select(:id,:url).each{|cat0|
    add "/products/#{cat0.url}", :changefreq => 'daily'
    Category.all.where(category_id: cat0.id).each{|cat1|
      add "/products/#{cat0.url}/#{cat1.url}", :changefreq => 'daily'
      Category.all.where(category_id: cat1.id).each{|cat2|
        add "/products/#{cat0.url}/#{cat1.url}/#{cat2.url}", :changefreq => 'daily'
        Category.all.where(category_id: cat2.id).each{|cat3|
          add "/products/#{cat0.url}/#{cat1.url}/#{cat2.url}/#{cat3.url}", :changefreq => 'daily'
        }
      }
    }
  }
  ProductDatum.all.select(:article).each{ |pd|
    add "/single/hm-#{pd.article}", :changefreq => 'daily'
  }

end
