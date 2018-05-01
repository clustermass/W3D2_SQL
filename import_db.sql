DROP TABLE IF EXISTS users;

CREATE TABLE users(
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions(
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,
  FOREIGN KEY (author_id) REFERENCES users(id)
);
DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows(
  id INTEGER PRIMARY KEY,
  user_id INT NOT NULL,
  question_id INT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies(
  id INTEGER PRIMARY KEY,
  body TEXT NOT NULL,
  ref_question_id INTEGER NOT NULL,
  ref_reply_id INTEGER,
  ref_user_id INTEGER NOT NULL,

  FOREIGN KEY (ref_question_id) REFERENCES questions(id),
  FOREIGN KEY (ref_reply_id) REFERENCES replies(id),
  FOREIGN KEY (ref_user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes(
  id INTEGER PRIMARY KEY,
  like_flag BOOLEAN NOT NULL,
  ref_user_id INTEGER NOT NULL,
  ref_question_id INTEGER NOT NULL,

  FOREIGN KEY (ref_user_id) REFERENCES users(id),
  FOREIGN KEY (ref_question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Mary', 'Poppins'),
  ('John', 'Smith'),
  ('Mike', "The Brick");

INSERT INTO
  questions(title, body, author_id)
VALUES
  ('HELP', 'My computer is broken',(SELECT id FROM users WHERE fname='John')),
  ('FYI','I found a phone',(SELECT id FROM users WHERE fname='Mary'));

INSERT INTO
question_follows(user_id,question_id)
VALUES
((SELECT id FROM users WHERE fname = 'Mike'),(SELECT id FROM questions WHERE title='FYI')),
((SELECT id FROM users WHERE fname = 'Mike'),(SELECT id FROM questions WHERE title='HELP'));

INSERT INTO
replies(body, ref_user_id,ref_reply_id,ref_question_id)
VALUES
('That''s my phone!',(SELECT id FROM users WHERE fname ='Mike'),NULL,(SELECT id FROM questions WHERE title='FYI')),
('Come get it!',(SELECT id FROM users WHERE fname='Mary'),1,(SELECT id FROM questions WHERE title='FYI'));

INSERT INTO
question_likes(like_flag,ref_user_id,ref_question_id)
VALUES
(1,(SELECT id FROM users WHERE fname='John'),(SELECT id FROM questions WHERE title='FYI'));
