require_dependency 'journal'

class JournalQuestionsObserver < ActiveRecord::Observer
  observe :journal
  
  def after_create(journal)
    if journal.question
      journal.question.save
      QuestionMailer.deliver_asked_question(journal)
    end
  end
end
