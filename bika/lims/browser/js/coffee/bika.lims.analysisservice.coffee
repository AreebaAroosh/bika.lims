###* Please use this command to compile this file into the parent `js` directory:
#    coffee -w -o ../ -c bika.lims.analysisservice.coffee
###

###*
# Controller class for Analysis Service Edit view
###

window.AnalysisServiceEditView = ->
  that = this
  manual_fd = $('#archetypes-fieldname-ManualEntryOfResults')
  manual_chk = $('#archetypes-fieldname-ManualEntryOfResults #ManualEntryOfResults')
  instre_fd = $('#archetypes-fieldname-InstrumentEntryOfResults')
  instr_chk = $('#archetypes-fieldname-InstrumentEntryOfResults #InstrumentEntryOfResults')
  methods_fd = $('#archetypes-fieldname-Methods')
  methods_ms = $('#archetypes-fieldname-Methods #Methods')
  method_fd = $('#archetypes-fieldname-_Method')
  method_sel = $('#archetypes-fieldname-_Method #_Method')
  instrs_fd = $('#archetypes-fieldname-Instruments')
  instrs_ms = $('#archetypes-fieldname-Instruments #Instruments')
  instr_fd = $('#archetypes-fieldname-Instrument')
  instr_sel = $('#archetypes-fieldname-Instrument #Instrument')
  defcalc_chk = $('#archetypes-fieldname-UseDefaultCalculation #UseDefaultCalculation')
  calc_fd = $('#archetypes-fieldname-_Calculation')
  calc_sel = $('#archetypes-fieldname-_Calculation #_Calculation')
  acalc_fd = $('#archetypes-fieldname-DeferredCalculation')
  acalc_sel = $('#archetypes-fieldname-DeferredCalculation #DeferredCalculation')
  interim_fd = $('#archetypes-fieldname-InterimFields')
  interim_rw = $('#archetypes-fieldname-InterimFields tr.records_row_InterimFields')
  ldsel_chk = $('#archetypes-fieldname-DetectionLimitSelector #DetectionLimitSelector')
  ldman_fd = $('#archetypes-fieldname-AllowManualDetectionLimit')
  ldman_chk = $('#archetypes-fieldname-AllowManualDetectionLimit #AllowManualDetectionLimit')

  ###*
  # Entry-point method for AnalysisServiceEditView
  ###

  insert_manual_methods = ->
    $.ajax(
      url: window.portal_url + '/get_instrument_methods'
      type: 'POST'
      data:
        '_authenticator': $('input[name="_authenticator"]').val()
        'uid': $(instr_sel).val()
      dataType: 'json'
      async: false).done (data) ->
      $(method_sel).find('option').remove()
      # Handle multiple methods
      if data != null and data.methods.length > 0
        # Set the instrument's methods
        $.each data.methods, (index, value) ->
          uid = value.uid
          title = value.title
          console.debug 'Adding Method ' + title + ' to the Selection'
          option = '<option value="' + uid + '">' + title + '</option>'
          $(method_sel).append option
          $(method_sel).val uid
          return
      else
        # Oooopps. The instrument has no method assigned
        $(method_sel).append '<option value=\'\'>' + _('None') + '</option>'
        $(method_sel).val ''
      # Delegate the action to Default Calc change event
      $(defcalc_chk).change()
      return
    return

  catchOriginalValues = ->
    $(manual_chk).attr 'data-default', $(manual_chk).is(':checked')
    $(instr_chk).attr 'data-default', $(instr_chk).is(':checked')
    $(methods_ms).attr 'data-default', $(methods_ms).val()
    $(method_sel).attr 'data-default', $(method_sel).val()
    $(instrs_ms).attr 'data-default', $(instrs_ms).val()
    $(instr_sel).attr 'data-default', $(instr_sel).val()
    $(defcalc_chk).attr 'data-default', $(defcalc_chk).is(':checked')
    $(calc_sel).attr 'data-default', $(calc_sel).val()
    $(acalc_sel).attr 'data-default', $(acalc_sel).val()
    # Remove 'None' option from 'Methods' multi-select
    $(methods_ms).find('option[value=""]').remove()
    # Disable the default calculation selector
    $(calc_sel).focus (e) ->
      $(this).blur()
      return
    # Toggle default/alternative calculation
    if $(defcalc_chk).is(':checked')
      $(acalc_fd).hide()
      $(calc_fd).show()
    else
      $(calc_fd).hide()
      $(acalc_fd).show()
    # Save the manually entered interims to keep them if another
    # calculation is set. We need to know which interim fields
    # are from the current selected calculation and which of them
    # have been set manually.
    $('body').append '<input type=\'hidden\' id=\'temp_manual_interims\' value=\'[]\'>'
    rows = $('tr.records_row_InterimFields')
    originals = []
    if $(rows).length > 1
      i = $(rows).length - 2
      while i >= 0
        # Get the original values
        keyword = $($($(rows)[i]).find('td input')[0]).val()
        if keyword != ''
          title = $($($(rows)[i]).find('td input')[1]).val()
          value = $($($(rows)[i]).find('td input')[2]).val()
          unit = $($($(rows)[i]).find('td input')[3]).val()
          hidd = $($($(rows)[i]).find('td input')[4]).is(':checked')
          wide = $($($(rows)[i]).find('td input')[5]).is(':checked')
          originals.push [
            keyword
            title
            value
            unit
            hidd
            wide
          ]
        i--
    toremove = []
    calcuid = ''
    $(calc_sel).find('option').remove()
    if $(defcalc_chk).is(':checked')
      calcuid = $(calc_sel).attr('data-default')
    else
      calcuid = $(acalc_sel).attr('data-default')
    if calcuid != null and calcuid != ''
      request_data =
        catalog_name: 'bika_setup_catalog'
        UID: calcuid
      window.bika.lims.jsonapi_read request_data, (data) ->
        if data.objects.length > 0
          $(calc_sel).append '<option value="' + data.objects[0].UID + '">' + data.objects[0].Title + '</option>'
          $(calc_sel).val data.objects[0].UID
          i = 0
          while i < data.objects[0].InterimFields.length
            row = data.objects[0].InterimFields[i]
            toremove.push row.keyword
            i++
        else
          $(calc_sel).append '<option value="' + data + '">' + _('None') + '</option>'
          $(calc_sel).val ''
        manualinterims = originals.filter((el) ->
          toremove.indexOf(el[0]) < 0
        )
        # Save the manualinterims in some hidden place
        $('#temp_manual_interims').val $.toJSON(manualinterims)
        # Fire events cascade
        $(manual_chk).change()
        return
    else
      # Fire events cascade
      $(manual_chk).change()
    return

  ###*
  # Loads the Interim fields Widget for the specificied calculation
  ###

  loadInterims = (calcuid) ->
    $(interim_fd).hide()
    rows = undefined
    i = undefined
    if calcuid == null or calcuid == ''
      $('#InterimFields_more').click()
      # blank last row
      rows = $('tr.records_row_InterimFields')
      # Clear the rest
      if $(rows).length > 1
        i = $(rows).length - 2
        while i >= 0
          $($(rows)[i]).remove()
          i--
      $(interim_fd).hide()
      return
    request_data =
      catalog_name: 'bika_setup_catalog'
      UID: calcuid
    window.bika.lims.jsonapi_read request_data, (data) ->
      `var rows`
      `var i`
      `var i`
      # Clear rows
      rows = undefined
      i = undefined
      $('#InterimFields_more').click()
      # blank last row
      rows = $('tr.records_row_InterimFields')
      originals = []
      if $(rows).length > 1
        i = $(rows).length - 2
        while i >= 0
          # Save the original values
          keyword = $($($(rows)[i]).find('td input')[0]).val()
          if keyword != ''
            value = $($($(rows)[i]).find('td input')[2]).val()
            unit = $($($(rows)[i]).find('td input')[3]).val()
            hidd = $($($(rows)[i]).find('td input')[4]).is(':checked')
            wide = $($($(rows)[i]).find('td input')[5]).is(':checked')
            originals.push [
              keyword
              value
              unit
              hidd
              wide
            ]
          $($(rows)[i]).remove()
          i--
      if data.objects.length > 0
        $(interim_fd).fadeIn 'slow'
        $('[id^=\'InterimFields-keyword-\']').attr 'id', 'InterimFields-keyword-0'
        $('[id^=\'InterimFields-title-\']').attr 'id', 'InterimFields-title-0'
        $('[id^=\'InterimFields-value-\']').attr 'id', 'InterimFields-value-0'
        $('[id^=\'InterimFields-unit-\']').attr 'id', 'InterimFields-unit-0'
        i = 0
        while i < data.objects[0].InterimFields.length
          row = data.objects[0].InterimFields[i]
          original = null
          j = 0
          while j < originals.length
            if originals[j][0] == row.keyword
              original = originals[j]
              break
            j++
          $('#InterimFields-keyword-' + i).val row.keyword
          $('#InterimFields-title-' + i).val row.title
          if original == null
            $('#InterimFields-value-' + i).val row.value
            $('#InterimFields-unit-' + i).val row.unit
          else
            $('#InterimFields-value-' + i).val original[1]
            $('#InterimFields-unit-' + i).val original[2]
          $('#InterimFields_more').click()
          i++
      # Manually entered results?
      manualinterims = $.parseJSON($('#temp_manual_interims').val())
      if manualinterims.length > 0
        $(interim_fd).fadeIn 'slow'
        i = $('tr.records_row_InterimFields').length - 1
        k = 0
        while k < manualinterims.length
          $('#InterimFields-keyword-' + i).val manualinterims[k][0]
          $('#InterimFields-title-' + i).val manualinterims[k][1]
          $('#InterimFields-value-' + i).val manualinterims[k][2]
          $('#InterimFields-unit-' + i).val manualinterims[k][3]
          $('#InterimFields_more').click()
          i++
          k++
      return
    return

  ###*
  # Checks if the selected instruments aren't out-of-date and their
  # latest Internal Calibration Tests are valid. If an invalid
  # instrument gets selected, shows an alert to the user
  ###

  validateInstruments = ->
    $('#invalid-instruments-alert').remove()
    if $('#InstrumentEntryOfResults').is(':checked')
      window.jarn.i18n.loadCatalog 'bika'
      _ = window.jarn.i18n.MessageFactory('bika')
      insts = if $('#Instruments').val() then $('#Instruments').val() else []
      $.each insts, (index, value) ->
        # Is valid?
        request_data =
          catalog_name: 'uid_catalog'
          UID: value
        window.bika.lims.jsonapi_read request_data, (data) ->
          if data.objects[0].Valid != '1'
            title = data.objects[0].Title
            instrument_path = window.location.protocol + '//' + window.location.host + data.objects[0].path
            if $('#invalid-instruments-alert').length > 0
              $('#invalid-instruments-alert dd').first().append ', ' + title
            else
              errmsg = _('Some of the selected instruments are out-of-date or with failed calibration tests')
              html = '<div id=\'invalid-instruments-alert\' class=\'alert\'>' + '    <dt>' + errmsg + ':</dt>' + '    <dd> <a href=' + instrument_path + '>' + title + '</a></dd>' + '</div>'
              $('#analysisservice-base-edit').before html
          return
        return
    else
      loadEmptyInstrument()
    return

  updateContainers = (target, requestdata) ->
    $.ajax
      type: 'POST'
      url: window.location.href + '/getUpdatedContainers'
      data: requestdata
      success: (data) ->
        # keep the current selection if possible
        option = $(target).val()
        if option == null or option == undefined
          option = []
        $(target).empty()
        $.each data, (i, v) ->
          if $.inArray(v[0], option) > -1
            $(target).append '<option value=\'' + v[0] + '\' selected=\'selected\'>' + v[1] + '</option>'
          else
            $(target).append '<option value=\'' + v[0] + '\'>' + v[1] + '</option>'
          return
        return
      dataType: 'json'
    return

  applyStyles = ->
    $($(manual_fd)).after $(methods_fd)
    $(methods_fd).css('border', '1px solid #cfcfcf').css('background-color', '#efefef').css('padding', '10px').css 'margin-bottom', '20px'
    $(instrs_fd).css('border', '1px solid #cfcfcf').css('border-bottom', 'none').css('background-color', '#efefef').css('padding', '10px').css 'margin-bottom', '0px'
    $(instr_fd).css('border', '1px solid #cfcfcf').css('border-top', 'none').css('background-color', '#efefef').css('padding', '10px').css 'margin-bottom', '20px'
    $(acalc_fd).find('label').hide()
    $(calc_fd).find('label').hide()
    return

  that.load = ->
    # LIMS-1775 Allow to select LDL or UDL defaults in results with readonly mode
    # https://jira.bikalabs.com/browse/LIMS-1775
    $(ldsel_chk).change ->
      if $(this).is(':checked')
        $(ldman_fd).show()
      else
        $(ldman_fd).hide()
        $(ldman_chk).prop 'checked', false
      return
    $(ldsel_chk).change()
    # service defaults
    # update defalt Containers
    $('.portaltype-analysisservice #RequiredVolume, .portaltype-analysisservice #Separate').change ->
      separate = $('#Separate').prop('checked')
      if !separate
        $('[name=\'Preservation\\:list\']').prop 'disabled', false
      requestdata =
        'allow_blank': true
        'show_container_types': !separate
        'show_containers': separate
        '_authenticator': $('input[name=\'_authenticator\']').val()
      updateContainers '#Container\\:list', requestdata
      return
    # partition table -> separate checkboxes
    # partition table -> minvol field
    # update row's containers
    $('.portaltype-analysisservice [name^=\'PartitionSetup.separate\'],.portaltype-analysisservice [name^=\'PartitionSetup.vol\']').change ->
      separate = $(this).parents('tr').find('[name^=\'PartitionSetup.separate\']').prop('checked')
      if !separate
        $(this).parents('tr').find('[name^=\'PartitionSetup.preservation\']').prop 'disabled', false
      minvol = $(this).parents('tr').find('[name^=\'PartitionSetup.vol\']').val()
      target = $(this).parents('tr').find('[name^=\'PartitionSetup.container\']')
      requestdata =
        'allow_blank': true
        'minvol': minvol
        'show_container_types': !separate
        'show_containers': separate
        '_authenticator': $('input[name=\'_authenticator\']').val()
      updateContainers target, requestdata
      return
    # copy sampletype MinimumVolume to minvol when selecting sampletype
    $('.portaltype-analysisservice [name^=\'PartitionSetup.sampletype\']').change ->
      st_element = this
      request_data =
        catalog_name: 'uid_catalog'
        UID: $(this).val()
      window.bika.lims.jsonapi_read request_data, (data) ->
        minvol = data.objects[0].MinimumVolume
        target = $(st_element).parents('tr').find('[name^=\'PartitionSetup.vol\']')
        $(target).val minvol
        # trigger change on containers, in case SampleType volume rendered
        # the selected container too small and removed it from the list
        $(st_element).parents('tr').find('[name^=\'PartitionSetup.container\']').change()
        return
      return
    # handling of pre-preserved containers in the Default Container field
    # select the preservation and disable the input.
    $('.portaltype-analysisservice #Container').bind 'selected', ->
      container_uid = $(this).attr('uid')
      request_data =
        catalog_name: 'uid_catalog'
        UID: container_uid
      window.bika.lims.jsonapi_read request_data, (data) ->
        if data.objects.length < 1 or !data.objects[0].PrePreserved or !data.objects[0].Preservation
          $('#Preservation').val ''
          $('#Preservation').prop 'disabled', false
        else
          $('#Preservation').val data.objects[0].Preservation
          $('#Preservation').prop 'disabled', true
        return
      return
    # handling of pre-preserved containers in the per Sample-Type rows
    # select the preservation and disable the input.
    $('.portaltype-analysisservice [name^=\'PartitionSetup.container\']').change ->
      target = $(this).parents('tr').find('[name^=\'PartitionSetup.preservation\']')
      container_uid = $(this).val()
      if !container_uid or container_uid.length == 1 and !container_uid[0]
        $(target).prop 'disabled', false
        return
      container_uid = container_uid[0]
      request_data =
        catalog_name: 'uid_catalog'
        UID: container_uid
      window.bika.lims.jsonapi_read request_data, (data) ->
        if data.objects.length < 1 or !data.objects[0].PrePreserved or !data.objects[0].Preservation
          $(target).prop 'disabled', false
        else
          $(this).val container_uid
          # makes no sense to leave multiple items selected
          $(target).val data.objects[0].Preservation
          $(target).prop 'disabled', true
        return
      return
    # update on first load
    # $(".portaltype-analysisservice [name^='PartitionSetup.separate']").change();
    # $(".portaltype-analysisservice [name^='Container']").change();
    # $(".portaltype-analysisservice [name^='PartitionSetup.container']").trigger("selected");
    # initial setup - hide Interim widget if no Calc is selected
    if $('.portaltype-analysisservice #Calculation').val() == ''
      $('#InterimFields_more').click()
      # blank last row
      rows = $('tr.records_row_InterimFields')
      # Clear the rest
      if $(rows).length > 1
        i = $(rows).length - 2
        while i >= 0
          $($(rows)[i]).remove()
          i--
      $('#archetypes-fieldname-InterimFields').hide()
      return
    # Check if there is, at least, one instrument available
    if $(instrs_ms).find('option').length == 0
      # Ooops, there isn't any instrument!
      $(manual_chk).prop 'checked', true
      $(manual_chk).prop 'readonly', true
      $(instr_chk).prop 'checked', false
      $(instr_chk).prop 'readonly', true
      errmsg = _('No instruments available')
      title = _('Instrument entry of results option not allowed')
      html = '<div id=\'no-instruments-alert\' class=\'alert\'>' + '    <dt>' + errmsg + '</dt>' + '    <dd>' + title + '</dd>' + '</div>'
      $('#analysisservice-base-edit').before html
    # The 'Manual entry of results' value changes
    $(manual_chk).change ->
      if $(this).is(':checked')
        # Insert all methods without instruments into the
        # methods InOut options widget.
        insert_manual_methods()
        $(methods_fd).fadeIn 'slow'
        # Delegate remaining actions to Methods change event
        $(methods_ms).change()
      else
        # The method selection must be done by enabling the
        # 'Allow instrument entry of results'
        # Hide and clear the methods multiselector
        $(methods_fd).hide()
        $(methods_ms).find('option[selected]').prop 'selected', false
        $(methods_ms).val ''
        # Delegate remaining actions to Methods change event
        $(methods_ms).change()
        # Select instrument entry and fire event
        $(instr_chk).prop 'checked', true
      $(instr_chk).change()
      return
    # The 'Allow instrument entry of results' value changes
    $(instr_chk).change ->
      if $(this).is(':checked')
        # The user must select the instruments supported by
        # this Analysis Service. The default method will be
        # retrieved from the default instrument selected.
        # The user must be able to allow manual entry
        $(manual_chk).unbind 'click'
        # Show the instruments multiselector
        $(instrs_fd).fadeIn 'slow'
        # Remove the 'none' option from instruments multiselector
        $(instrs_ms).find('option[value=""]').remove()
        # Remove the 'none' option from def instrument selector
        $(instr_sel).find('option[value=""]').remove()
        # Show the default instrument selector
        $(instr_fd).fadeIn 'slow'
        # Disable the default method selector
        $(method_sel).focus (e) ->
          $(this).blur()
          return
        # Disable the default calculation selector
        $(calc_sel).focus (e) ->
          $(this).blur()
          return
        # Hide the alternate calculation selector
        $(acalc_fd).hide()
        # Delegate remaining actions to Instruments change event
        $(instrs_ms).change()
      else
        # The method selection must be done manually, by
        # selecting the methods for which this Analysis Service
        # has support.
        # Remove the invalid instrument alert (if exists)
        $('#invalid-instruments-alert').remove()
        # Hide the instruments multiselector and unselect all
        $(instrs_fd).hide()
        if $(instrs_ms).find('option[value=""]').length == 0
          $(instrs_ms).prepend '<option value="">None</option>'
        $(instrs_ms).val ''
        $(instrs_ms).find('option[value=""]').prop 'selected', true
        # Hide the default instrument selector
        $(instr_fd).hide()
        # Unselect the default instrument
        if $(instr_sel).find('option[value=""]').length == 0
          $(instr_sel).prepend '<option value="">None</option>'
        $(instr_sel).val ''
        $(instr_sel).find('option[value=""]').prop 'selected', true
        # The user mustn't be allowed to unset manual entry
        $(manual_chk).click (e) ->
          e.preventDefault()
          return
        # The user must be able to select the default method manualy
        $(methods_ms).change()
        $(method_sel).unbind 'focus'
        # If manual entry is not selected, select it and
        # fire event cascade
        if !$(manual_chk).is(':checked')
          $(manual_chk).prop 'checked', true
          $(manual_chk).change()
      return
    # The methods multiselect changes
    $(methods_ms).change (e) ->
      prevmethod = $(method_sel).val()
      prevmethodtxt = $(method_sel).find('option[value="' + prevmethod + '"]').html()

      ###if ($(this).val() == null) {
          // At least one method must be selected
          $(this).val($(this).find('option').first().val());
      }
      ###

      $(method_sel).find('option').remove()
      # Populate with the methods from the multi-select
      methods = $(methods_ms).val()
      if methods != null
        $.each methods, (index, value) ->
          option = $(methods_ms).find('option[value="' + value + '"]').clone()
          $(method_sel).append option
          return
      else
        $(method_sel).prepend '<option value="">' + _('None') + '</option>'
      # Select the previously selected method or the first one
      defoption = $(method_sel).find('option[value="' + $(method_sel).attr('data-default') + '"]')
      if defoption == null or defoption == ''
        defoption = $(method_sel).find('option[value="' + prevmethod + '"]')
        if defoption == null or defoption == ''
          defoption = $(method_sel).find('option').first()
      if !$(instr_chk).is(':checked')
        $(method_sel).val defoption.val()
      else
        if $(method_sel).find('option[value="' + prevmethod + '"]').length == 0
          $(method_sel).append '<option value="' + prevmethod + '">' + prevmethodtxt + '</option>'
        $(method_sel).val prevmethod
      # Delegate remaining actions to Method change event
      $(method_sel).change()
      return
    $(method_sel).change (e) ->
      # Delegate actions to Default Calculation change event
      $(defcalc_chk).change()
      return
    # The instruments multiselect changes
    $(instrs_ms).change (e) ->
      previnstr = $(instr_sel).val()
      if $(this).val() == null
        # At least one instrument must be selected
        $(this).val $(this).find('option').first().val()
      # Populate the default instrument list with the selected instruments
      $(instr_sel).find('option').remove()
      insts = $(instrs_ms).val()
      $.each insts, (index, value) ->
        option = $(instrs_ms).find('option[value="' + value + '"]').clone()
        $(instr_sel).append option
        return
      # Select the previously selected instrument or the first one
      defoption = $(instr_sel).find('option[value="' + previnstr + '"]')
      if defoption == null or defoption == ''
        defoption = $(instr_sel).find('option[value="' + $(instr_sel).attr('data-default') + '"]')
        if defoption == null or defoption == ''
          defoption = $(instr_sel).find('option').first()
      $(instr_sel).val $(defoption).val()
      # Check if out-of-date or QC-fail instruments have been
      # selected.
      $('#invalid-instruments-alert').remove()
      $.each insts, (index, value) ->
        # Is valid?
        if value != '' and $(instr_chk).is(':checked')
          request_data =
            catalog_name: 'uid_catalog'
            UID: value
          window.bika.lims.jsonapi_read request_data, (data) ->
            `var title`
            `var errmsg`
            `var html`
            if !$(instr_chk).is(':checked')
              $('#invalid-instruments-alert').remove()
            else if data.objects[0].Valid != '1'
              title = data.objects[0].Title
              instrument_path = window.location.protocol + '//' + window.location.host + data.objects[0].path
              if $('#invalid-instruments-alert').length > 0
                $('#invalid-instruments-alert dd').first().append ', ' + title
              else
                errmsg = _('Some of the selected instruments are out-of-date or with failed calibration tests')
                html = '<div id=\'invalid-instruments-alert\' class=\'alert\'>' + '    <dt>' + errmsg + ':</dt>' + '    <dd> <a href=' + instrument_path + '>' + title + '</a></dd>' + '</div>'
                $('#analysisservice-base-edit').before html
            return
        return
      # Delegate remaining actions to Instrument change event
      $(instr_sel).change()
      return
    # The instrument selector changes
    $(instr_sel).change ->
      # Clear and disable the method list and populate with the
      # method assigned to the selected instrument
      $(method_sel).find('option').remove()
      $(method_sel).append '<option value=\'\'>' + _('None') + '</option>'
      $(method_sel).val ''
      $.ajax(
        url: window.portal_url + '/get_instrument_methods'
        type: 'POST'
        data:
          '_authenticator': $('input[name="_authenticator"]').val()
          'uid': $(instr_sel).val()
        dataType: 'json'
        async: false).done (data) ->
        $(method_sel).find('option').remove()
        # Handle multiple methods
        if data != null and data.methods.length > 0
          # Set the instrument's methods
          $.each data.methods, (index, value) ->
            `var title`
            uid = value.uid
            title = value.title
            console.debug 'Adding Method ' + title + ' to the Selection'
            option = '<option value="' + uid + '">' + title + '</option>'
            $(method_sel).append option
            $(method_sel).val uid
            return
        else
          # Oooopps. The instrument has no method assigned
          $(method_sel).append '<option value=\'\'>' + _('None') + '</option>'
          $(method_sel).val ''
        # Delegate the action to Default Calc change event
        $(defcalc_chk).change()
        return
      return
    # The 'Default Calculation' checkbox changes
    $(defcalc_chk).change ->
      # Hide Calculation Interims widget
      #$(interim_fd).hide();
      if $(this).is(':checked')
        # Toggle default/alternative calculation
        $(acalc_fd).hide()
        $(calc_fd).show()
        $(calc_fd).prop 'disabled', true
        # Load the calculation for the selected method
        muid = $(method_sel).val()
        if muid != null and muid != ''
          # A valid method was selected
          $.ajax(
            url: window.portal_url + '/get_method_calculation'
            type: 'POST'
            data:
              '_authenticator': $('input[name="_authenticator"]').val()
              'uid': muid
            dataType: 'json').done (data) ->
            $(calc_sel).find('option').remove()
            if data != null and data['uid']
              $(calc_sel).prepend '<option value="' + data['uid'] + '">' + data['title'] + '</option>'
            else
              $(calc_sel).append '<option value="">' + _('None') + '</option>'
            $(calc_sel).val $(calc_sel).find('option').first().val()
            # Delegate the action to Default Calculation change event
            $(calc_sel).change()
            return
        else
          $(calc_sel).find('option').remove()
          $(calc_sel).append '<option value="">' + _('None') + '</option>'
          $(calc_sel).change()
      else
        $(calc_sel).find('option').remove()
        $(calc_sel).append '<option value="">' + _('None') + '</option>'
        $(calc_sel).val ''
        # Toggle default/alternative calculation
        $(calc_fd).hide()
        $(acalc_fd).show()
        # Delegate the action to Alternative Calculation change event
        $(acalc_sel).change()
      return
    # The 'Default calculation' changes
    $(calc_sel).change ->
      loadInterims $(this).val()
      return
    # The 'Alternative calculation' changes
    $(acalc_sel).change ->
      loadInterims $(this).val()
      return
    # Apply default styling
    applyStyles()
    # Grab original values
    catchOriginalValues()
    return

  return
