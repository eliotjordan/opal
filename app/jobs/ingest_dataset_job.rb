class IngestDatasetJob < ActiveJob::Base
  queue_as :default

  def perform(md_path, ds_path, user, ark = nil)
    logger.info "Ingesting GIS Dataset #{ds_path}"
    @ark = ark
    @metadata = metadata(md_path)
    @user = user
    @resource = resource
    @md_fileset = md_fileset(md_path)
    @ds_fileset = ds_fileset(ds_path)
    attach_file_sets
  end

  def metadata(path)
    doc = Nokogiri::XML(File.open(path, 'r').read)
    out = GeoConcerns::Extractors::FgdcMetadataExtractor.new(doc)
    out.to_hash
  end

  def resource
    VectorWork.new.tap do |r|
      r.rights_statement = ['http://rightsstatements.org/vocab/NKC/1.0/']
      r.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      r.apply_depositor_metadata @user
      r.coverage = @metadata[:coverage]
      r.creator = @metadata[:creator]
      r.description = @metadata[:description]
      r.subject = @metadata[:subject]
      r.title = @metadata[:title]
      r.spatial = @metadata[:spatial]
      r.temporal = @metadata[:temporal]
      r.identifier = [@ark] if @ark
      r.save!
    end
  end

  def md_fileset(path)
    FileSet.new.tap do |f|
      f.title = ['test']
      f.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      f.geo_mime_type = 'application/xml; schema=fgdc'
      f.apply_depositor_metadata(@user)
      actor = GeoConcerns::Actors::FileSetActor.new(f, @user)
      actor.create_content(File.open(path))
      f.save!
    end
  end

  def ds_fileset(path)
    FileSet.new.tap do |f|
      f.title = ['file']
      f.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      f.geo_mime_type = 'application/zip; ogr-format="ESRI Shapefile"'
      f.apply_depositor_metadata(@user)
      actor = GeoConcerns::Actors::FileSetActor.new(f, @user)
      actor.create_content(File.open(path, 'rb'))
      f.save!
    end
  end

  def attach_file_sets
    ordered_members = []
    ordered_members << @md_fileset
    ordered_members << @ds_fileset
    @resource.ordered_members = ordered_members
    @resource.representative_id = @ds_fileset.id
    @resource.thumbnail_id = @ds_fileset.id
    @resource.save!
  end

  def trigger_events
    presenter = GeoConcerns::VectorWorkShowPresenter.new(SolrDocument.new(@resource.to_solr), nil)
    Messaging.messenger.record_updated(presenter)
  end
end
