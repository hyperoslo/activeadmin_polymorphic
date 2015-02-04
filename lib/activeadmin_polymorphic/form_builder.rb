module ActiveadminPolymorphic
  class FormBuilder < ::ActiveAdmin::FormBuilder
    def polymorphic_has_many(assoc, poly_name, options = {}, &block)
      custom_settings = :new_record, :allow_destroy, :heading, :sortable, :sortable_start, :types, :path_prefix
      builder_options = {new_record: true, path_prefix: :admin}.merge! options.slice  *custom_settings

      options         = {for: assoc      }.merge! options.except *custom_settings
      options[:class] = [options[:class], "polymorphic_has_many_fields"].compact.join(' ')
      sortable_column = builder_options[:sortable]
      sortable_start  = builder_options.fetch(:sortable_start, 0)

      html = "".html_safe
      html << template.capture do
        contents = "".html_safe

        block = polymorphic_form(poly_name, builder_options)

        template.assign('polymorphic_has_many_block' => true)
        contents = without_wrapper { inputs(options, &block) }

        if builder_options[:new_record]
          contents << js_for_polymorphic_has_many(
            assoc, poly_name, template, builder_options, options[:class]
          )
        else
          contents
        end
      end

      tag = @already_in_an_inputs_block ? :li : :div
      html = template.content_tag(tag, html, class: "polymorphic_has_many_container #{assoc}", 'data-sortable' => sortable_column, 'data-sortable-start' => sortable_start)
      template.concat(html) if template.output_buffer
      html
    end

    protected

    def polymorphic_has_many_actions(has_many_form, builder_options, contents)
      if has_many_form.object.new_record?
        contents << template.content_tag(:li) do
          template.link_to I18n.t('active_admin.has_many_remove'),
            "#", class: 'button polymorphic_has_many_remove'
        end
      elsif builder_options[:allow_destroy]
        contents << has_many_form.input(:_destroy, as: :boolean,
                            wrapper_html: {class: 'polymorphic_has_many_delete'},
                            label: I18n.t('active_admin.has_many_delete'))
      end

      if builder_options[:sortable]
        contents << has_many_form.input(builder_options[:sortable], as: :hidden)

        contents << template.content_tag(:li, class: 'handle') do
          ::ActiveAdmin::Iconic.icon :move_vertical
        end
      end

      contents
    end

    def js_for_polymorphic_has_many(assoc, poly_name, template, builder_options, class_string)
      new_record = builder_options[:new_record]
      assoc_reflection = object.class.reflect_on_association assoc
      assoc_name       = assoc_reflection.klass.model_name
      placeholder      = "NEW_#{assoc_name.to_s.underscore.upcase.gsub(/\//, '_')}_RECORD"

      text = new_record.is_a?(String) ? new_record : I18n.t('active_admin.has_many_new', model: assoc_name.human)
      form_block = polymorphic_form(poly_name, builder_options, true)

      opts = {
        for: [assoc, assoc_reflection.klass.new],
        class: class_string,
        for_options: { child_index: placeholder }
      }

      html = "".html_safe
      html << template.capture do
        inputs_for_nested_attributes opts, &form_block
      end

      template.link_to text, '#', class: "button polymorphic_has_many_add", data: {
        html: CGI.escapeHTML(html).html_safe, placeholder: placeholder
      }
    end

    def polymorphic_options(builder_options)
      # add internationalization
      builder_options[:types].each_with_object([]) do |model, options|
        options << [
          model.model_name.human, model,
          {"data-path" => form_new_path(model, builder_options) }
        ]
      end
    end

    def polymorphic_form(poly_name, builder_options, for_js = false)
      proc do |f|
        html = "".html_safe
        html << f.input("#{poly_name}_id", as: :hidden)

        if f.object.send(poly_name).nil?
          html << f.input("#{poly_name}_type", input_html: { class: 'polymorphic_type_select' }, as: :select, collection: polymorphic_options(builder_options))
        else
          html << f.input(
            "#{poly_name}_type", as: :hidden,
            input_html: {"data-path" =>  form_edit_path(f.object.send(poly_name), builder_options) }
          )
        end

        html << polymorphic_has_many_actions(f, builder_options, "".html_safe)

        html
      end
    end

    def form_new_path(object, builder_options)
      "/#{builder_options[:path_prefix]}/#{ActiveModel::Naming.plural(object)}/new"
    end

    def form_edit_path(object, builder_options)
      "/#{builder_options[:path_prefix]}/#{ActiveModel::Naming.plural(object)}/#{object.id}/edit"
    end
  end
end
