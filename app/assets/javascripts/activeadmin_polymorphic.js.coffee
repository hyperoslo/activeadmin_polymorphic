$ ->
  if $('.polymorphic_has_many_container').length
    form = $('#main_content').find('form:first')
    $(form).on 'submit', (e) ->
      submissions_counter = 0
      parentForm = @
      expect = $(@).find('form').length
      if submissions_counter < expect
        e.preventDefault()

      $(@).find('form').each ->
        remoteSubmit @, ->
          submissions_counter++
          if submissions_counter == expect
            $(form).find('form').remove()
            stripEmptyRelations()
            $(parentForm).submit()

  $(document).on "upload:start", "form", (event) ->
    form = $('#main_content').find('form:first')
    form.find("input[type=submit]").attr "disabled", true

  $(document).on "upload:complete", "form", (event) ->
    form = $('#main_content').find('form:first')

    unless form.find("input.uploading").length
      form.find("input[type=submit]").removeAttr "disabled"

  $('.polymorphic_has_many_fields').each (index, rapper) ->
    rapper = $ rapper

    hiddenField = rapper.find 'input[type=hidden][data-path]'
    formPath = hiddenField.data 'path'

    extractAndInsertForm formPath, rapper


  $(document).on 'click', 'a.button.polymorphic_has_many_remove', (e)->
    e.preventDefault()
    parent    = $(@).closest '.polymorphic_has_many_container'
    to_remove = $(@).closest 'fieldset'
    recompute_positions parent

    parent.trigger 'polymorphic_has_many_remove:before', [to_remove, parent]
    to_remove.remove()
    parent.trigger 'polymorphic_has_many_remove:after', [to_remove, parent]

  $(document).on 'click', 'a.button.polymorphic_has_many_add', (e)->
    e.preventDefault()
    parent = $(@).closest '.polymorphic_has_many_container'
    parent.trigger before_add = $.Event('polymorphic_has_many_add:before'), [parent]

    unless before_add.isDefaultPrevented()
      index = parent.data('polymorphic_has_many_index') || parent.children('fieldset').length - 1
      parent.data has_many_index: ++index

      regex = new RegExp $(@).data('placeholder'), 'g'
      html  = $(@).data('html').replace regex, index

      fieldset = $(html).insertBefore(@)
      recompute_positions parent
      parent.trigger 'polymorphic_has_many_add:after', [fieldset, parent]

  init_polymorphic_sortable()


  $('.polymorphic_has_many_container').on 'change', '.polymorphic_type_select', (event) ->
    fieldset = $(this).closest 'fieldset'

    selectedOption = $(this).find 'option:selected'
    formPath = selectedOption.data 'path'

    label = $(this).prev 'label'
    label.remove()

    hiddenField = $('<input type="hidden" />')
    hiddenField.attr 'name', $(this).attr('name')
    hiddenField.val $(this).val()

    $(this).replaceWith hiddenField

    newListItem = $ '<li>'

    extractAndInsertForm formPath, fieldset

init_polymorphic_sortable = ->
  elems = $('.polymorphic_has_many_container[data-sortable]:not(.ui-sortable)')

  elems.sortable
    axis: 'y'
    items: '> fieldset',
    handle: '> ol > .handle',
    stop:    recompute_positions
  elems.each recompute_positions

# Removes relations if id or type is not specified
# For example when user clicked add relation button, but didn't selected type
stripEmptyRelations = ->
  $('.polymorphic_has_many_fields input:hidden').each ->
    if $(@).val() == ""
      $(@).parents('.polymorphic_has_many_fields').remove()

recompute_positions = (parent)->
  parent     = if parent instanceof jQuery then parent else $(@)
  input_name = parent.data 'sortable'
  position   = parseInt(parent.data('sortable-start') || 0, 10)

  parent.children('fieldset').each ->
    # We ignore nested inputs, so when defining your has_many, be sure to keep
    # your sortable input at the root of the has_many block.
    destroy_input  = $(@).find "> ol > .input > :input[name$='[_destroy]']"
    sortable_input = $(@).find "> ol > .input > :input[name$='[#{input_name}]']"

    if sortable_input.length
      sortable_input.val if destroy_input.is ':checked' then '' else position++

window.extractAndInsertForm= (url, target)->
  target = $ target

  $.get url, (data)->
    elements = $(data)
    form = $('#main_content form', elements).first()
    $(form).find('.actions').remove()
    $(form).on 'submit', -> return false

    target.prepend form

window.loadErrors = (target) ->
  $(target).off('ajax:success') # unbind successfull action for json form
  $(target).trigger('submit.rails').on 'ajax:success', (event, data, result) ->
    # duplicates method above. refactor using callbacks
    elements = $(data)
    form = $('#main_content form', elements).first()
    $(form).find('.actions').remove()
    $(form).on 'submit', -> return false

    $(target).replaceWith(form)


window.remoteSubmit = (target, callback)->
  $(target).data('remote', true)
  $(target).removeAttr('novalidate')
  action = $(target).attr('action')
  $(target).find("input[type=file]").remove()
  # we gonna burn in hell for that
  # perhaps we can use ajax:before callback
  # to set type json
  action_with_json = action + '.json'
  $(target).attr('action', action_with_json)

  # unbind callbacks action for form if it was submitted before
  $(target).off('ajax:success').off('ajax:aborted:file').off('ajax:error')

  $(target).trigger('submit.rails')
    .on 'ajax:aborted:file', (inputs) ->
      false
    .on 'ajax:error', (event, response, status)->
      $(target).attr('action', action)
      if response.status == 422
        loadErrors(target)
    .on 'ajax:success', (event, object, status, response) ->
      $(target).attr('action', action)
      if response.status == 201 # created
        $(target).next().find('input:first').val(object.id)
        # replace new form with edit form
        # to update form method to PATCH and form action
        url = "#{action}/#{object.id}/edit"
        extractAndInsertForm(url, $(target).parent('fieldset'))
        $(target).remove()

      callback()

