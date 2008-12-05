require_dependency "query"

module QuestionQueryPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)
    
    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      
      alias_method :redmine_available_filters, :available_filters
      alias_method :available_filters, :question_available_filters

      alias_method :redmine_sql_for_field, :sql_for_field
      alias_method :sql_for_field, :question_sql_for_field
    end

  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    
    # Wrapper around the +available_filters+ to add a new Question filter
    def question_available_filters
      @available_filters = redmine_available_filters
      
      user_values = []
      user_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
      if project
        user_values += project.users.sort.collect{|s| [s.name, s.id.to_s] }
      else
        user_values += User.current.projects.collect(&:users).flatten.uniq.sort.collect{|s| [s.name, s.id.to_s] }
      end

      question_filters = { "question_assigned_to_id" => { :type => :list, :order => 14, :values => user_values }}
      
      return @available_filters.merge(question_filters)
    end
    
    # Wrapper for +sql_for_field+ so Questions can use a different table than Issues
    def question_sql_for_field(field, v, db_table, db_field, is_custom_filter)
      if field == "question_assigned_to_id"
        v = values_for(field).clone

        db_table = Question.table_name
        db_field = 'assigned_to_id'
        
        # "me" value subsitution
        v.push(User.current.logged? ? User.current.id.to_s : "0") if v.delete("me")
        
        case operator_for field
        when "="
          sql = "#{db_table}.#{db_field} IN (" + v.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
        when "!"
          sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + v.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + "))"
        end

        return sql
        
      else
        return redmine_sql_for_field(field, v, db_table, db_field, is_custom_filter)
      end
      
    end
    
  end  
end

Query.send(:include, QuestionQueryPatch)
