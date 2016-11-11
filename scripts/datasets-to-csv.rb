require 'nokogiri'
require 'byebug'
require 'csv'
require 'json'
require 'pg'
require 'ezid-client'

##
# Instructions from command line
# irb -r ./datasets-to-csv.rb
# x = Pulmap::MetadataFiles.new('./metadata')
# x.to_json
module Pulmap
  class Config
    attr_reader :md_base_path, :ds_base_path

    def md_base_path
      '/metadata/'
    end

    def ds_base_path
      '/data/'
    end

    def pg
      {
        host: 'host',
        port: '5432',
        dbname: 'db',
        user: 'user',
        password: 'pass'
      }
    end
  end

  class Metadata
    attr_reader :doc, :path, :arks

    def initialize(path, arks)
      @path = path
      @arks = arks
      @config = Pulmap::Config.new
    end

    def doc
      @doc ||= Nokogiri::XML(File.open(path).read)
    end

    def to_hash
      return nil unless download?
      {
        guid: guid.upcase,
        data: data_path,
        metadata: metadata_path,
        ark: ark
      }
    end

    def onlink
      result = doc.at_xpath('//idinfo/citation/citeinfo/onlink')
      return result.text if result
    end

    def download?
      return true if /download/.match(onlink)
      return true if /publicdata/.match(onlink)
      false
    end

    def data_path
      return unless onlink
      rel_path = onlink.gsub('http://map.princeton.edu/download/data/', '').gsub('http://map.princeton.edu/publicdata/', '')
      "#{@config.ds_base_path}#{rel_path}"
    end

    def metadata_path
      ext = File.extname(path)
      "#{@config.md_base_path}#{guid}#{ext}"
    end

    def guid
      File.basename(path, File.extname(path))
    end

    def ark
      rows = arks.rows.select { |h| h['guid'] == guid.upcase }
      ark = rows.first['ark'] unless rows.empty?
      return ark unless ark.nil?
      arks.mint
    end
  end

  class MetadataFiles
    attr_reader :dir, :ext, :file_paths
    def initialize(dir, ext = '*')
      @dir = dir
      @ext = ext
    end

    def to_csv
      docs = build
      return if docs.empty?
      column_names = docs.first.keys
      out = CSV.generate do |csv|
        csv << column_names
        docs.each do |x|
          csv << x.values
        end
      end
      File.write('metadata.csv', out)
    end

    def to_json
      docs = build
      return if docs.empty?
      File.write('metadata.json', docs.to_json)
    end

    private

    def file_paths
      @files ||= Dir["#{dir}/#{ext}"]
    end

    def build
      docs = []
      arks = Pulmap::Arks.new
      file_paths.each do |file_path|
        h =  Pulmap::Metadata.new(file_path, arks).to_hash
        next if h.nil?
        docs << h
        puts h
      end
      docs
    end
  end

  class Arks
    attr_reader :arks
    def initialize
      @config = Pulmap::Config.new
    end

    def rows
      @rows ||= query
    end

    def mint
      arks.pop
    end

    private

    def query
      conn ||= PGconn.connect(@config.pg)
      res = conn.exec("SELECT guid, ark FROM geodata WHERE item_type = 'dataset'")
      rows = []
      res.each do |row|
        rows << row
      end
      rows
    end

    def arks
      @arks ||= JSON.parse(File.open('arks/arks-full.json').read)
    end
  end
end
