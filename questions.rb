require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :fname, :lname
  attr_reader :id

  def initialize(user_info)
      @fname = user_info['fname']
      @lname = user_info['lname']
      @id = user_info['id']
  end

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL,id)
    SELECT
    id,fname,lname
    FROM
    users
    WHERE
    id = ?
    SQL
    raise "No such user" if reply.first.emty?
    reply.map {|user_hash| User.new(user_hash)}
  end

  def self.find_by_name(fname, lname)
    reply = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
    SQL

    reply.map{|user| User.new(user) }
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def save
    if @id
      update
    else
      QuestionsDatabase.instance.execute(<<-SQL,@fname,@lname)
      INSERT INTO
          users (fname,lname)
      VALUES
          (?,?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL,@fname,@lname,@id)
    UPDATE
      users
    SET
      fname = ?, lname = ?
    WHERE
      users.id = ?
    SQL  
  end
end

class Question
  attr_accessor :body, :title
  attr_reader :id, :author_id
  def initialize(question_hash)
    @title = question_hash['title']
    @body = question_hash['body']
    @id = question_hash['id']
    @author_id = question_hash['author_id']
  end

  def self.find_by_author_id(author_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      id,title, body
    FROM
      questions
    WHERE
      author_id = ?
      SQL
    reply.map {|question| Question.new(question)}
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def author
    reply = QuestionsDatabase.instance.execute(<<-SQL,@author_id)
    SELECT
      id, fname, lname
    FROM
      users
    WHERE
      id = ?
    SQL
    User.new(reply.first)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end
end

class QuestionFollow
  def self.followers_for_question_id(question_id) #TA
    reply = QuestionsDatabase.instance.execute(<<-SQL,question_id)
    SELECT
    users.id,fname,lname
    FROM
    users
    JOIN question_follows ON question_follows.user_id = users.id
    WHERE
    question_follows.question_id = ?
    SQL
    reply.map {|user| User.new(user)}
  end

  def self.followed_questions_for_user_id(user_id) #TA
    reply = QuestionsDatabase.instance.execute(<<-SQL,user_id)
    SELECT
      *
    FROM
    questions
    JOIN question_follows ON question_follows.question_id = questions.id
    WHERE
    question_follows.user_id = ?
    SQL
    reply.map{|question| Question.new(question)}
  end

  def self.most_followed_questions(n)
    reply = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      *
    FROM
      questions
      JOIN
        question_follows ON questions.id = question_follows.question_id
    GROUP BY
      question_follows.question_id
    ORDER BY
      COUNT(question_follows.question_id) DESC
    LIMIT
      ?
    SQL

    reply.map {|question| Question.new(question)}
  end
end

class Reply
  def initialize(rep_hash)
    @id = rep_hash['id']
    @body = rep_hash['body']
    @ref_question_id = rep_hash['ref_question_id']
    @ref_reply_id = rep_hash['ref_reply_id']
    @ref_user_id = rep_hash['ref_user_id']
  end

  def self.find_by_user_id(user_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      replies
    WHERE
      ref_user_id = ?
    SQL
    reply.map {|rep| Reply.new(rep) }
  end

  def self.find_by_question_id(question_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL,question_id)
    SELECT
      *
    FROM
    replies
    WHERE
    ref_question_id = ?
    SQL
    reply.map {|rep| Reply.new(rep)}
  end

  def author
    reply = QuestionsDatabase.instance.execute(<<-SQL,@ref_user_id)
    SELECT
      *
    FROM
    users
    WHERE
    id = ?
    SQL
    User.new(reply.first)
  end

  def question
    reply = QuestionsDatabase.instance.execute(<<-SQL,@ref_question_id)
    SELECT
      *
    FROM
    questions
    WHERE
    id = ?
    SQL
    Question.new(reply.first)
  end

  def parent_reply
    reply = QuestionsDatabase.instance.execute(<<-SQL, @ref_reply_id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL

    Reply.new(reply.first)
  end

  def child_replies
    reply = QuestionsDatabase.instance.execute(<<-SQL, @id)
    SELECT
      *
    FROM
      replies
    WHERE
      ref_reply_id = ?
      SQL
  end

end

class QuestionLike
  def self.likers_for_question_id(question_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      users
    JOIN
      question_likes ON question_likes.ref_user_id = users.id
    WHERE
      question_likes.ref_question_id = ?
    SQL
    reply.map{|user| User.new(user)}
  end


  def self.num_likes_for_question_id(question_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      COUNT(*)
    FROM
      question_likes
    WHERE
      question_likes.ref_question_id = ?
    SQL
    reply.first.values.first
  end


  def self.liked_questions_for_user_id(user_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      questions
      JOIN
        question_likes ON question_likes.ref_question_id = questions.id
    WHERE
      ? = question_likes.ref_question_id
    SQL

    reply.map {|question| Question.new(question) }
  end

  def self.most_liked_questions(n)
    reply = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      *
    FROM
      questions
      JOIN
        question_likes ON question_likes.ref_question_id = questions.id
    GROUP BY
      question_likes.ref_question_id
    ORDER BY
      COUNT(questions.id) DESC
    LIMIT ?
    SQL
    reply.map {|question| Question.new(question)}
  end


end
