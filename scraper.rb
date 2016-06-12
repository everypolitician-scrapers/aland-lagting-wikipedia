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
  Nokogiri::HTML(open(URI.encode(URI.decode(url))).read)
end

def scrape_list(term, url)
  noko = noko_for(url)
  noko.xpath('//h2[span]').each do |party|
    break if party.text.to_s.include? 'Se även'
    ul = party.xpath('following-sibling::h2 | following-sibling::ul').slice_before { |e| e.name != 'ul' }.first.first
    ul.css('li').each do |li|
      li.css('sup').remove
      expected = li.text.include?('Suppleant') ? 2 : 1
      links = li.css('a')
      abort "Unexpected number of people in #{li.text}" unless links.count == expected
      links.each do |a|
        data = {
          name: a.text.tidy,
          wikiname: a.attr('class') == 'new' ? '' : a.attr('title'),
          party: party.css('span.mw-headline').text.tidy,
          party_wikiname: party.xpath('.//span[@class="mw-headline"]/a[not(@class="new")]/@title').text,
          term: term,
        }
        ScraperWiki.save_sqlite([:name, :party, :term], data)
      end
    end
  end
end

scrape_list("2015", 'https://sv.wikipedia.org/wiki/Lista_över_ledamöter_av_Ålands_lagting_2015–2019')
scrape_list("2011", 'https://sv.wikipedia.org/wiki/Lista_%C3%B6ver_ledam%C3%B6ter_av_%C3%85lands_lagting_2011-2015')
scrape_list("2007", 'https://sv.wikipedia.org/wiki/Lista_%C3%B6ver_ledam%C3%B6ter_av_%C3%85lands_lagting_2007-2011')
