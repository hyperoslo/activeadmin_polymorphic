require 'rails_helper'
require 'rspec/mocks'

describe ActiveadminPolymorphic::FormBuilder do

  # Setup an ActionView::Base object which can be used for
  # generating the form for.
  let(:helpers) do
    view = action_view
    def view.articles_path
      "/articles"
    end

    def view.protect_against_forgery?
      false
    end

    def view.url_for(*args)
      if args.first == {action: "index"}
        articles_path
      else
        super
      end
    end

    def view.a_helper_method
      "A Helper Method"
    end

    view
  end

  def build_form(options = {}, form_object = Article.new, &block)
    options = {url: helpers.articles_path}.merge(options)

    form = render_arbre_component({form_object: form_object, form_options: options, form_block: block}, helpers) do
      active_admin_form_for(assigns[:form_object], assigns[:form_options], &assigns[:form_block])
    end.to_s

    Capybara.string(form)
  end

  context "in general" do
    context "it without custom settings" do
      let :body do
        build_form do |f|
          f.inputs do
            f.input :title
          end
        end
      end

      it "should generate a fieldset with a inputs class" do
        expect(body).to have_selector("fieldset.inputs")
      end
    end

    context "it with custom settings" do
      let :body do
        build_form do |f|
          f.inputs class: "custom_class" do
            f.input :title
          end
        end
      end

      it "should generate a fieldset with a inputs and custom class" do
        expect(body).to have_selector("fieldset.inputs.custom_class")
      end
    end
  end

  context "with polymorphic has many inputs" do
    describe "with simple block" do
      let :body do
        build_form builder: ActiveadminPolymorphic::FormBuilder do |f|
          section = f.object.sections.build
          section.sectionable = Image.new
          f.polymorphic_has_many :sections, :sectionable, types: [Image, Text]
        end
      end

      it "should render add section new button" do
        with_translation activerecord: {models: {section: {one: "Section", other: "Sections"}}} do
          expect(body).to have_selector("a", text: "Add New Section")
        end
      end

      it "should render the nested form" do
        expect(body).to have_selector("input[name='article[sections_attributes][0][sectionable_id]']")
        expect(body).to have_selector("input[name='article[sections_attributes][0][sectionable_type]']")
      end

      it "should add a link to remove new nested records" do
        expect(body).to have_selector(
          ".polymorphic_has_many_container > fieldset > ol > li > a.button.polymorphic_has_many_remove[href='#']", text: "Remove"
        )
      end
    end

    describe "sortable" do
      context "with new section" do
        let :body do
          build_form builder: ActiveadminPolymorphic::FormBuilder do |f|
            section = f.object.sections.build
            section.sectionable = Image.new
            f.polymorphic_has_many :sections, :sectionable, types: [Image, Text], sortable: :position
          end
        end

        it "shows the nested fields for unsaved records" do
          expect(body).to have_selector("input[name='article[sections_attributes][0][position]']")
        end

        it "shows the nested fields for unsaved records" do
          expect(body).to have_selector('.polymorphic_has_many_container[data-sortable=position]')
        end
      end
    end
  end
end
