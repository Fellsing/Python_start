#task. Для каждого вопроса вывести процент успешных решений, то есть отношение количества верных ответов к общему количеству ответов, значение округлить до 2-х знаков после запятой. Также вывести название предмета, к которому относится вопрос, и общее количество ответов на этот вопрос. В результат включить название дисциплины, вопросы по ней (столбец назвать Вопрос), а также два вычисляемых столбца Всего_ответов и Успешность. Информацию отсортировать сначала по названию дисциплины, потом по убыванию успешности, а потом по тексту вопроса в алфавитном порядке.
#Поскольку тексты вопросов могут быть длинными, обрезать их 30 символов и добавить многоточие "...".

select name_subject, concat(left(name_question, 30), '...') as Вопрос, count(answer.answer_id) as Всего_ответов, round(sum(is_correct)/count(is_correct)*100,2) as Успешность
from student inner join attempt using(student_id)
inner join testing using(attempt_id)
inner join subject using(subject_id)
inner join question using(subject_id)
inner join answer on answer.question_id=question.question_id and answer.answer_id=testing.answer_id
group by 1,2
order by 1,4 desc,2;