module ProfilesHelper

    def profile_change_content(change_list)
      puts "========"
        all_html = ""
        local_user_id = logged_in_user.id
        current_date = nil
        changes = 0

        change_list.each do |change|
          
            ret_html = ""

            if change.alert_date.to_date == Date.today.to_date && current_date.nil?
                ret_html << "<div class='alert'><strong>Today</strong></div>"
                current_date = Date.today.to_date
            elsif change.alert_date.to_date  < Date.today.to_date && current_date != change.alert_date.to_date
                ret_html << "<div class='alert'><strong>#{change.day}</strong></div>"
                current_date = change.alert_date.to_date
            end
               case(change.alert_type)
               when SceneAlerts::INFO_CHANGED
                    #if change.user.id != local_user_id
                        if [Campaign::DELETED, Campaign::CLOSED].include? change.campaign.status 
						puts "1 2 ka 4"
            comment = %|<div class="alert-item"><span class="bolder"><a href="/#{change.campaign.url}.html">#{change.campaign.name}</a></span> was #{change.campaign.status_text.downcase}.</div>|
						else
              puts "4 2 ka 1"
							comment = %|<div class="alert-item">A change was made to <span class="bolder"><a href="/#{change.campaign.url}.html">#{change.campaign.name}</a></span></div>|
						end
						ret_html << comment
						
                    	changes = changes + 1
                    #end
               when SceneAlerts::MEMBER_ADDED
                    if change.user.id != local_user_id
                         ret_html << <<HTML
                         <div class="alert-item"><span class="bolder"> #{ link_to_compose( change.user ) } </span> was added to <span class="bolder"><a href="/#{change.campaign.url}.html" >#{change.campaign.name}</a></span></div>
HTML
                    changes = changes + 1
                    else
                         ret_html << <<HTML
                        <div class="alert-item"><span class="bolder"> #{ link_to_compose( change.user ) } </span> approved you as a member.</div>
HTML
                    changes = changes + 1
                    end
               when SceneAlerts::DONATION_MADE                 
                    ret_html << %|

                                    <div class="alert-item">
                                      #{change.donated_by_whom} has donated #{number_to_currency change.donation_amount} to the |

                                            unless change.campaign.fund_raiser.nil?
                                              puts "1"
                                              ret_html << %|#{change.campaign.fund_raiser.name}|
                                            else
                                              puts "2"
                                              ret_html << %|#{change.fund_name}|
                                            end
                                            
                                            ret_html << %|  fund of #{change.campaign.organization.name}.

                                    </div>|
          
                    changes = changes + 1
               end

               if changes > 0
                    all_html << ret_html
               end
          end
          all_html
          end


     def output_datatype_for_user(user_attribute)
          attribute = user_attribute.name
          data_type = user_attribute.data_type
          ret_string = ''
          case data_type
               when DataType::TEXT
                    if attribute == 'my_site_blog'
                         text_field :user, attribute, :maxlength=>30,:class=>user_attribute.css_class
                    else
                         text_field :user, attribute, :class=>user_attribute.css_class
                    end

               when DataType::CHECKBOX
                    check_box :user, attribute
               when DataType::RANGE
                    "Low: #{text_field :user, attribute + '_low',:size=>5 } &nbsp; High: #{text_field :user, attribute + '_high', :size=>5 }"
               when DataType::RADIO
                    List.find(User_attribute.list_name).each do |list_item|
                         ret_string << "<input type='radio' value='"+ list_item.value + "' name='user[" + attribute + "]' />"+ list_item.name
                    end
               when DataType::SELECT
                    select_items = List.get_list_with_default(user_attribute.list_name).collect {|list_item| [list_item.name,list_item.name]}
                    select(:user, attribute, select_items)
               when DataType::CHECKBOXLIST
                    value = @User.instance_eval(attribute)
                    value_list = []
                    if value
                         value_list = value.collect{|item| item.value }
                    end
                    List.get_list_with_default(User_attribute.list_name).each do |list_item|
                         ret_string << "<input type='checkbox' #{"checked='true'" if value_list.include?(list_item.name)  } value='"+ list_item.name + "' name='user[" + attribute + "][]' />&nbsp;"+ list_item.name + "<br/>"
                    end
                    ret_string
               when DataType::YESNO

          end
     end
end

   