#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(term, url)
  noko = noko_for(url)
  noko.xpath('//h2[span]').each do |party|
    break if party.text.to_s.include? 'Se även'
    ul = party.xpath('following-sibling::h2 | following-sibling::ul').slice_before { |e| e.name != 'ul' }.first.first
    ul.css('li').each do |li|
      data = { 
        name: li.at_css('a').text.tidy,
        wikiname: li.xpath('.//a[not(@class="new")][1]/@title').text,
        party: party.css('span.mw-headline').text.tidy,
        party_wikiname: party.xpath('.//span[@class="mw-headline"]/a[not(@class="new")]/@title').text,
        term: term,
      }
      ScraperWiki.save_sqlite([:name, :party, :term], data)
    end
  end
end

scrape_list("2007", 'https://sv.wikipedia.org/wiki/Lista_%C3%B6ver_ledam%C3%B6ter_av_%C3%85lands_lagting_2007-2011')
scrape_list("2011", 'https://sv.wikipedia.org/wiki/Lista_%C3%B6ver_ledam%C3%B6ter_av_%C3%85lands_lagting_2011-2015')
