class QuestionIssueHooks < QuestionHooksBase
  # Applies the question class to each journal div if they are questions
  def view_issues_history_journal_bottom(context = { })
    o = ''
    if context[:journal] && context[:journal].question && context[:journal].question.opened?
      question = context[:journal].question
      
      if question.assigned_to
        html = assigned_question_html(question)
      else
        html = unassigned_question_html(question)
      end

      o += <<JS
<script type='text/javascript'>
   $('change-#{context[:journal].id}').addClassName('question');
   $$('#change-#{context[:journal].id} h4 div').each(function(ele) { ele.insert({ top: ' #{html} ' }) });
</script>
JS
      
    end
    return o
  end
  
  def view_issues_edit_notes_bottom(context = { })
    f = context[:form]
    @issue = context[:issue]
    @user = User.current
    o = ''
    # put the field that allows the user to select the question they want to answer
    if @issue.pending_question?(@user)
      questions = @issue.pending_questions(@user)
      o << content_tag(:p,
                    "<label>#{l(:field_question_to_answer)}</label> " +
                    select_tag('question_to_answer', options_for_select([[]] + questions.collect {|q| [truncate(q.journal.notes, Question::TruncateTo), q.id]}))
                    )
    end
    o << content_tag(:p, 
                     "<label>#{l(:field_question_assign_to)}</label> " +
                     text_field_tag('note[question_assigned_to]', nil, :size => "40"))

    o << content_tag(:div,'', :id => "note_question_assigned_to_choices", :class => "autocomplete")
    o << javascript_tag("new Ajax.Autocompleter('note_question_assigned_to', 'note_question_assigned_to_choices', '#{ url_for(:controller => 'questions', :action => 'autocomplete_for_user_login', :id => @issue.project, :issue_id => @issue) }', { minChars: 1, frequency: 0.5, paramName: 'user', select: 'field' });")
    return o
  end
  
  def controller_issues_edit_before_save(context = { })
    params = context[:params]
    journal = context[:journal]
    issue = context[:issue]
    if params[:note] && !params[:note][:question_assigned_to].blank?
      unless journal.question # Update handled by Journal hooks
        # New
        journal.question = Question.new(
                                        :author => User.current,
                                        :issue => journal.issue
                                        )
        if params[:note][:question_assigned_to].downcase != 'anyone'
          # Assigned to a specific user
          assign_question_to_user(journal, User.find_by_login(params[:note][:question_assigned_to]))
        end
      end
    end
    
    if params[:question_to_answer] and !params[:question_to_answer].empty?
      Question.close!(params[:question_to_answer], User.current, journal)
    end
    
    return ''
  end
  
  def view_issues_sidebar_issues_bottom(context = { })
    project = context[:project]
    if project
      question_count = Question.count_of_open_for_user_on_project(User.current, project)
    else
      question_count = Question.count_of_open_for_user(User.current)
    end
    retval = ''
    if question_count > 0
      retval += link_to(l(:text_questions_for_me) + " (#{question_count})",
                     {
                       :controller => 'questions',
                       :action => 'my_issue_filter',
                       :project => project,
                       :only_path => true
                     },
                     { :class => 'question-link' }
                     ) + '<br />'
    end
    if project
      question_count = Question.count_of_open_for_anyone_on_project(project)
    else
      question_count = Question.count_of_open_for_anyone()
    end
    if question_count > 0
      retval += link_to(l(:text_questions_for_anyone) + " (#{question_count})",
                     {
                       :controller => 'questions',
                       :action => 'anyone_issue_filter',
                       :project => project,
                       :only_path => true
                     },
                     { :class => 'question-link' }
                     ) + '<br />'
    end
    return retval
  end

  private
  
  def assign_question_to_user(journal, user)
    journal.question.assigned_to = user
  end
end
