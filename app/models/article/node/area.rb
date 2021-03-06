# encoding: utf-8
class Article::Node::Area < Cms::Node
  def list_types
    [['タイトル一覧（標準）', 'titles'], %w(ブログ形式 blog)]
  end

  def validate_settings
    return if in_settings['list_count'].blank?

    if in_settings['list_count'] !~ /^[0-9]+$/
      errors.add(:base,"#{self.class.human_attribute_name :list_count} #{errors.generate_message(:base, :not_a_number)}")
    end
  end

  def setting_label(name)
    value = setting_value(name)

    case name
    when :list_type
      list_types.each { |c| return c[0] if c[1].to_s == value.to_s }
    end

    value
  end
end
