# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def page_title
    case params[:controller]
    when 'home'
      case params[:action]
      when 'people'
        return 'The People'
      when 'places'
        return 'The Places'
      when 'index'
        return 'Home'
      else
        return params[:action].humanize.capitalize
      end
    when 'places'
      if params[:id] && params[:action] == 'edit'
        return "Edit " + Place.find(params[:id]).name
      elsif params[:id]
        return Place.find(params[:id]).name
      else
        return 'Add Place'
      end
    when 'users'
      if params[:id] && params[:action] == 'edit'
        return "My Account"
      elsif params[:id]
        return User.find(params[:id]).short_name.titleize + "'s Profile"
      else
        return ''
      end
    when 'guide'
      if params[:general_category]
        return params[:general_category].humanize.titleize
      else
        return params[:action].humanize.titleize
      end
    when 'my_scene'
      if params[:action] == 'show'
        return 'My Scene'
      elsif params[:action].include? 'my'
        return params[:action].humanize.titleize
      else
        return 'My ' + params[:action].humanize.titleize
      end
    when 'daily_special'
      if params[:action] == 'list_for_all_places'
        return 'All Daily Specials'
      elsif params[:action] == 'list_for_place' && params[:id]
        return 'Daily Specials for ' + Place.find(params[:id]).name
      else
        return 'Daily Specials'
      end
    when 'reviews'
      if params[:id]
        return 'Review for ' + Review.find(params[:id]).place.name
      elsif params[:place_id]
        return 'Add Review for ' + Place.find(params[:place_id]).name
      else
        return 'Reviews'
      end
    when 'invitations'
      return 'Invite Friends'
    when 'place_photos'
      return 'Add Photo'
    else
      return nil
    end
  end

  def longer_date(date)
    # Apr. 15, 2009
    return date.strftime("%B %d at %I:%M %p").gsub( /0?(\d),/, '\1,' )
  end


  def value_for(model, field)
    obj = instance_variable_get("@" + model.to_s)
    obj.respond_to?(field) ? obj.send(field) : nil
  end

  def state_select_for(model, field = :state)
    states = %w(AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME
                MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN
                TX UT VA VT WA WI WV WY AA AE AP AS FM GU MH MP PR PW VI)
    select(model, field, states.map { |state| [state, state] },
      :selected => (value_for(model, field) || 'CA'))
  end

  def year_select_for(model, field = :expDateYear)
	this_year = Time.now.year
    years = (this_year..( this_year + 10 )).map(&:to_s)
    select(model, field, years.map { |y| [y, y] },
      :selected => (value_for(model, field) || this_year.to_s))
  end

  def month_select_for(model, field = :expDateMonth)
    months = %w(01 02 03 04 05 06 07 08 09 10 11 12)
    select(model, field, months.map { |m| [m, m] },
      :selected => (value_for(model, field) || months[Time.now.month - 1]))
  end

  def currency_select_for(model)
    currencies = %w(USD GBP EUR JPY CAD AUD)
    select(model, :currency, currencies.map { |currency| [currency, currency] }, {:selected => 'USD'})
  end
  def is_administrator?
    if is_logged_in? && @logged_in_user.has_role?('Administrator')
      return true
    end
    return false
  end

  def selected_campaign
    if logged_in_user
      id = session[:campaign_id]
      if (id)
        Campaign.find_by_id(id)
      end
    end
  end

  def base_url
    url_for(:controller => 'home', :action => 'index', :escape => false, :only_path => false)
  end
	
	
	def campaign_email_link(c)
		link_to("#{LocalURL}/#{c.url}.html", "#{LocalURL}/#{c.url}.html")
	end

  def sort_dir(col, default)
    default ||= 'asc'
    return default unless @sort
    current_col, current_dir = @sort.split(/ /)
    return default unless current_col == col
    current_dir == "asc" ? "desc" : "asc"
  end

  def sortable_column(title, col, options = {})
    dir = sort_dir(col, options[:default_dir])
    current_col, current_dir = @sort.split(/ /)
    title += (dir == 'asc' ? '&uarr;' : '&darr;') if col == current_col
    options = { :controller => params[:controller], :action => params[:action]}.merge(options)
    link_to title, "javascript:resort('#{col} #{dir}');", { :class => "sortable" }
  end

  def link_to_compose(user)
    link_to h(user.short_name), :controller => "messages", :action => "new_to_user", :user_id => user.id
  end


	def header_link_for(text, link, current, last=nil)
		class_name = []
		class_name << "current" if text == current
		class_name << "last" if last
		class_name = class_name.join(" ")
		if text == current
			%|<li class="#{class_name}">#{text}</li>|
		else
			%|<li class="#{class_name}"><a href="#{link}">#{text}</a></li>|
		end
	end

	def elide_to(s, n)
		return s if s.length < n
		s[0..n] + '&hellip;'
	end	
	
	# CMS
	
	def cms(tag, content, last=true)
		data = CMS.find_by_tag(tag)
		content = data.content if data
		if in_edit_mode
			display_html = cms_form_wrapper(tag, last,
				%|<textarea class="cms" name="cms[content]" id="#{tag}_form_value">#{content}</textarea>|)
			return display_html
		else
			return content
		end
	end
	
	def cms_form_wrapper(tag, last, content)
		html = %|<br>#{form_tag('/cms/edit')}
			#{content}
			<input type="hidden" value="#{request.request_uri}" name="goto">
			<input type="hidden" value="#{tag}" name="cms[tag]">
			<br>
			<input type="submit" value="save"> or 
			<a href="#{request.url.gsub(/\?+mode=edit|&+mode=edit/,'')}">cancel</a
			<br>
		</form>|
		html += %|<script>render_cms_editor();</script>| if last
		html
	end
	
	def cms_edit_link(tag)
		%|<a href="#" onclick="cms_swap('#{tag}');return false" class="cms_edit_link">(edit)</a>|
	end
	
	def cms_count_lines(content)
		lines = (content.size / 145) + content.scan(/(<\/(li)|<br)/).size + content.scan(/<\/(p|h|ul)/).size*2 + 2
		lines = 7 if lines <= 6
		lines
	end
	
	def in_edit_mode
		(is_administrator? && params[:mode] == "edit")
	end
	
	def js_write(eid, text)
		%|<script>document.getElementById('#{eid}').innerHTML = "#{simple_format(text).gsub(/"/, "\\\"")}";</script>|
	end
	
	def simple_format(string)
		string.gsub!(/(\r\n|\n|\r)/, '<br/>')
		string
	end
	
	def escape_js_string(str)
		str.gsub(/[']/, '\\\\\'')
	end

  def payment(fund_raiser_id)
    puts "=>>>#{fund_raiser_id}"
    payment = Payment.find_by_fund_raiser_id(fund_raiser_id)
    puts payment.inspect
    puts "---------------"
    payment.amount
  end

  def get_sum_payments_against_same_funds(campaign)
    Payment.find_by_sql("select sum(amount) as amount , fund_raiser_id  from payments where campaign_id = #{campaign.id} group by fund_raiser_id order by amount desc")
  end

    

 
end
