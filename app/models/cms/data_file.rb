# encoding: utf-8
class Cms::DataFile < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Base::File
  include Sys::Model::Rel::Unid
  include Sys::Model::Rel::Creator
  include Cms::Model::Rel::Site
  include Cms::Model::Rel::Concept
  include Cms::Model::Auth::Concept

  include StateText

  belongs_to :concept, foreign_key: :concept_id, class_name: 'Cms::Concept'
  belongs_to :site, foreign_key: :site_id, class_name: 'Cms::Site'
  belongs_to :node, foreign_key: :node_id, class_name: 'Cms::DataFileNode'

  attr_accessor :in_resize_size, :in_thumbnail_size

  validates :concept_id, presence: true

  before_save :set_published_at
  after_save :upload_public_file
  after_destroy :remove_public_file

  scope :published, -> {
    where(arel_table[:state].eq('public'))
  }

  scope :search, -> (params) {
    rel = all

    data_files = arel_table

    params.each do |n, v|
      next if v.to_s == ''

      case n
      when 's_node_id'
        rel = rel.where(data_files[:node_id].eq(v))
      when 's_name_or_title'
        rel = rel.where(data_files[:title].matches("%#{v}%")
                        .or(data_files[:name].matches("%#{v}%")))
      end
    end if params.size != 0

    rel
  }

  def states
    [%w(公開 public), %w(非公開 closed)]
  end

  def public_path
    return nil unless site
    dir = Util::String::CheckDigit.check(format('%07d', id)).gsub(/(.*)(..)(..)(..)$/, '\1/\2/\3/\4/\1\2\3\4')
    "#{site.public_path}/_files/#{dir}/#{escaped_name}"
  end

  def public_uri
    dir = Util::String::CheckDigit.check(format('%07d', id))
    "/_files/#{dir}/#{escaped_name}"
  end

  def public_thumbnail_uri
    uri = public_uri
    ::File.dirname(uri) + '/thumb/' + ::File.basename(uri)
  end

  def public_full_uri
    "#{site.full_uri}#{public_uri.sub(/^\//, '')}"
  end

  def public_thumbnail_full_uri
    "#{site.full_uri}#{public_thumbnail_uri.sub(/^\//, '')}"
  end

  def publishable?
    return false unless editable?
    !public?
  end

  def closable?
    return false unless editable?
    public?
  end

  def public?
    !published_at.nil?
  end

  def has_thumbnail?
    !thumb_size.blank?
  end

  def duplicated?
    files = self.class.where(concept_id: concept_id)
                      .where(name: name)

    files = files.where.not(id: id) if id

    if node_id
      files = files.where(node_id: node_id)
    else
      files = files.where(node_id: nil)
    end

    !files.empty?
  end

  private

  def set_published_at
    self.published_at = (state == 'public') ? Core.now : nil
  end

  def upload_public_file
    remove_public_file

    if state == 'public'
      upl_path = upload_path
      pub_path = public_path

      if ::Storage.exists?(upl_path)
        ::Storage.mkdir_p(::File.dirname(pub_path))
        ::Storage.cp(upl_path, pub_path)
      end

      upl_path = ::File.dirname(upload_path) + '/thumb.dat'
      pub_path = ::File.dirname(public_path) + '/thumb/' + ::File.basename(public_uri)

      if ::Storage.exists?(upl_path)
        ::Storage.mkdir_p(::File.dirname(pub_path))
        ::Storage.cp(upl_path, pub_path)
      end
    end
    true
  end

  def remove_public_file
    dir = ::File.dirname(public_path)
    ::Storage.rm_rf(dir) if ::Storage.exists?(dir)
    true
  end
end
