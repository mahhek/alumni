module ManagedFormHelper
	
	def link_to_category(type, display, selected=false, extra="")
		%|
			<li class="#{selected ? "selected" : ""}" id="category_#{type}">
				<a class="#{extra}" href="#" onclick="go_to_category('#{type}', this); return false">#{display}</a>
			</li>
		|
	end
	
	def managed_section_header(display)
		%|
			<tr class="section_header_row">
				<th class="section_header" colspan="3">#{ display }</th>
			</tr>
		|
	end
	
	def managed_form_row(header, display, descr="")
		%|
			<tr>
				<th>#{ header }</th>
				<td class="form_content">#{ display }</td>
				<td class="form_description">#{ descr }</td>
			</tr>
		|
	end
	
	def managed_form_data_row(f, field, display, data, description="")
		managed_form_row(f.label(field, display+":"), data, description)
	end
	
	def managed_form_text_row(f, field, display, description="")
		managed_form_data_row(f, field, display, f.text_field(field), description)
	end
	
	def managed_form_radio_row(f, field, display, values, descr="")
		radios = f.radio_button(field, values[0][0], :class=>"input_radio") +
			f.label((field.to_s + "_" + values[0][0].to_s).to_sym, values[0][1]) +
			f.radio_button(field, values[1][0], :class=>"input_radio") +
			f.label((field.to_s + "_" + values[1][0].to_s).to_sym, values[1][1])
		managed_form_row(f.label(field, display+":"), radios, descr)
	end
	
	def managed_form_text_block_row(f, field, display, description="")
		managed_form_data_row(f, field, display, f.text_area(field), description)
	end
	
	def managed_form_text_block_row_no_rte(f, field, display, description="")
		managed_form_data_row(f, field, display, f.text_area(field, :class=>"mceNoEditor", :rows=>10, :cols=>46), description)
	end
	
	def managed_form_select_row(f, field, display, options, required=false)
		select_field = f.select(field, options) + ((required) ? " *" : "")
		managed_form_data_row(f, field, display, select_field)
	end
	
	def managed_form_submit(f, display)
		%|<tr><td colspan="3" style="text-align:center">#{ f.submit(display, :class=>"input_submit") }</td></tr>|
	end
end