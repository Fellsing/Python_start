#task.  Вывести студентов, которые сдавали дисциплину «Основы баз данных», указать дату попытки и результат. Информацию вывести по убыванию результатов тестирования.
select name_student, date_attempt, result from student inner join attempt using(student_id)
inner join subject using(subject_id)
where name_subject='Основы баз данных'
order by 3 desc;