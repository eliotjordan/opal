desc "Ingest GIS Datasets from JSON file"
task ingest_datasets: :environment do
  user = User.all.first
  records = JSON.parse(File.open(ARGV[1]).read)
  records.each do |r|
    ds_base = "/mnt/data/GISdata"
    md_base = "/mnt/data/metadata"
    ds_path = "#{ds_base}#{r['data']}"
    md_path = "#{md_base}#{r['metadata']}"
    ark = "ark:/88435/#{r['ark']}"

    begin
      IngestDatasetJob.perform_later(md_path, ds_path, user, ark)
    rescue => e
      puts "Error: #{e.message}"
      puts e.backtrace
    end
  end
end

desc "Ingest single GIS Dataset"
task ingest_dataset: :environment do
  user = User.all.first

  logger = Logger.new(STDOUT)
  IngestDatasetJob.logger = logger
  logger.info "ingesting datasets files from: #{ARGV[1]}"
  logger.info "ingesting as: #{user.user_key} (override with USER=foo)"
  begin
    IngestDatasetJob.perform_later(ARGV[1], ARGV[2], user)
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace
  end
end