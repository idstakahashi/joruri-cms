# encoding: utf-8
class Faq::Script::RecentDocsController < Cms::Controller::Script::Publication
  def publish
    uri  = @node.public_uri.to_s
    path = @node.public_path.to_s
    publish_page(@node, uri: "#{uri}index.rss", path: "#{path}index.rss", dependent: :rss)
    publish_page(@node, uri: "#{uri}index.atom", path: "#{path}index.atom", dependent: :atom)
    publish_more(@node, uri: uri, path: path, first: 2, dependent: :more)

    render text: 'OK'
  end
end
