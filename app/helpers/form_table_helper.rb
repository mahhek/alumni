module FormTableHelper
	
	def form_section_divider
		%|<tr class="section_header_divider"><td colspan="2" /></tr>|
	end
	
	def form_section_header(display)
		%|
			#{form_section_divider}
			<tr class="section_header_row">
				<th></th>
				<th class="section_header">#{ display }</th>
			</tr>
		|
	end
	
	def form_row(header, display)
		%|
			<tr>
				<th>#{ header }</th>
				<td>#{ display }</td>
			</tr>
		|
	end
	
	def form_data_row(f, field, display, data, options={})
		form_row(f.label(field, display+":", options), data)
	end
	
	def form_row_block(f, field, display, options={}, &block)
		concat(form_data_row(f, field, display, capture(&block), options), block.binding)
	end
	
	def form_row_raw_block(display="", &block)
		concat(form_row(display, capture(&block)), block.binding)
	end
	
	def form_text_row(f, field, display, required=false)
		text_field = f.text_field(field) + ((required) ? " *" : "")
		form_data_row(f, field, display, text_field)
	end
	
	def form_text_block_row(f, field, display, value="")
		form_data_row(f, field, display, f.text_area(field, :value=>value))
	end
	
	def form_select_row(f, field, display, options, required=false)
		select_field = f.select(field, options) + ((required) ? " *" : "")
		form_data_row(f, field, display, select_field)
	end
	
	def form_submit(f, display)
		form_section_explanation f.submit(display)
	end
	
	def form_section_explanation(display)
		form_row "", display
	end
	
	def form_file_row(f, field, display, explanation="")
		form_data_row(f, field, display, f.file_field(field) + "<div class='explanation'>#{explanation}</div>")
	end
end