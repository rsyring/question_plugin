class Question < ActiveRecord::Base
  unloadable
  TruncateTo = 120
  
  belongs_to :assigned_to, :class_name => "User", :foreign_key => "assigned_to_id"
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :issue
  belongs_to :journal
  
  validates_presence_of :author
  validates_presence_of :issue
  validates_presence_of :journal
  
  def for_anyone?
    self.assigned_to.nil?
  end
  
  def self.close!(qid, user, closing_journal=nil)
    q = Question.find(qid)
    if q
      if q.opened and q.assigned_to.id == user.id
        q.opened = false
        q.save!
        QuestionMailer.deliver_answered_question(q, closing_journal) if closing_journal
      end
    end
  end

  # TODO: refactor to named_scope
  def self.count_of_open_for_user(user)
    Question.count(:conditions => {:assigned_to_id => user.id, :opened => true})
  end

  def self.count_of_open_for_anyone()
    project_ids = User.current.projects.collect{|p| "#{p.id}"}.join(',')
    Question.count(:conditions => ["#{Question.table_name}.assigned_to_id IS NULL AND #{Project.table_name}.id IN (#{project_ids}) AND #{Question.table_name}.opened = ?",
                    true],
                   :include => [:issue => [:project]])
  end

  # TODO: refactor to named_scope
  def self.count_of_open_for_user_on_project(user, project)
    Question.count(:conditions => ["#{Question.table_name}.assigned_to_id = ? AND #{Project.table_name}.id = ? AND #{Question.table_name}.opened = ?",
                                   user.id,
                                   project.id,
                                   true],
                   :include => [:issue => [:project]])
  end

  def self.count_of_open_for_anyone_on_project(project)
    Question.count(:conditions => ["#{Question.table_name}.assigned_to_id IS NULL AND #{Project.table_name}.id = ? AND #{Question.table_name}.opened = ?",
                                   project.id,
                                   true],
                   :include => [:issue => [:project]])
  end
end