module UsersHelper
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
