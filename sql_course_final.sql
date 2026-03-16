--Вычислить рейтинг каждого студента относительно студента, прошедшего наибольшее количество шагов в модуле (вычисляется как отношение количества пройденных студентом шагов к максимальному количеству пройденных шагов, умноженное на 100). Вывести номер модуля, имя студента, количество пройденных им шагов и относительный рейтинг. Относительный рейтинг округлить до одного знака после запятой. Столбцы назвать Модуль, Студент, Пройдено_шагов и Относительный_рейтинг  соответственно. Информацию отсортировать сначала по возрастанию номера модуля, потом по убыванию относительного рейтинга и, наконец, по имени студента в алфавитном порядке.
with get_rate_stud(mod_id,stud, steps)
as
(
select module_id, student_name, count(distinct step_id) FROM student INNER JOIN step_student USING(student_id)
                INNER JOIN step USING (step_id)
                INNER JOIN lesson USING (lesson_id)
where result='correct'
group by 1,2
)
select mod_id as Модуль, stud as Студент, steps as Пройдено_шагов, round(steps/max(steps) over (partition by mod_id)*100,1) as Относительный_рейтинг 
from get_rate_stud
order by 1, 4 desc, 2;




--Проанализировать, в каком порядке и с каким интервалом пользователь отправлял последнее верно выполненное задание каждого урока. Учитывать только студентов, прошедших хотя бы один шаг из всех трех уроков. В базе занесены попытки студентов  для трех уроков курса, поэтому анализ проводить только для этих уроков.
--
--Для студентов прошедших как минимум по одному шагу в каждом уроке, найти последний пройденный шаг каждого урока - крайний шаг, и указать:
--
--имя студента;
--номер урока, состоящий из номера модуля и через точку позиции каждого урока в модуле;
--время отправки  - время подачи решения на проверку;
--разницу во времени отправки между текущим и предыдущим крайним шагом в днях, при этом для первого шага поставить прочерк ("-"), а количество дней округлить до целого в большую сторону.
--Столбцы назвать  Студент, Урок,  Макс_время_отправки и Интервал  соответственно. Отсортировать результаты по имени студента в алфавитном порядке, а потом по возрастанию времени отправки.
with get_res(stud, lesson, att_time)
as
(
select  student_name, concat( module_id,'.', lesson_position), max(submission_time) 
from lesson inner join step using(lesson_id)
inner join step_student using(step_id)
inner join student using(student_id)
where result='correct'
group by 1,2
),
get_final_res(stud)
as
(
select stud from get_res
group by 1
having count(distinct lesson)=3
)
select stud as Студент, lesson as Урок, from_unixtime(att_time) as Макс_время_отправки,
case 
when att_time-lag(att_time) over (partition by stud order by att_time) is null then '-'
else ceil((att_time-lag(att_time) over (partition by stud order by att_time))/86400.0) end as Интервал
from get_res
where stud in (select stud from get_final_res)
order by 1, 3;

--Для студента с именем student_59 вывести следующую информацию по всем его попыткам:

--информация о шаге: номер модуля, символ '.', позиция урока в модуле, символ '.', позиция шага в модуле;
--порядковый номер попытки для каждого шага - определяется по возрастанию времени отправки попытки;
--результат попытки;
--время попытки (преобразованное к формату времени) - определяется как разность между временем отправки попытки и времени ее начала, в случае если попытка длилась более 1 часа, то время попытки заменить на среднее время всех попыток пользователя по всем шагам без учета тех, которые длились больше 1 часа;
--относительное время попытки  - определяется как отношение времени попытки (с учетом замены времени попытки) к суммарному времени всех попыток  шага, округленное до двух знаков после запятой.
--Столбцы назвать  Студент,  Шаг, Номер_попытки, Результат, Время_попытки и Относительное_время. Информацию отсортировать сначала по возрастанию id шага, а затем по возрастанию номера попытки (определяется по времени отправки попытки).
--
--Важно. Все вычисления производить в секундах, округлять и переводить во временной формат только для вывода результата.
with get_res(stid,stud,shag,rn,res,att_time) as
(
select step_id,student_name,concat(module_id,'.',lesson_position,'.',step_position),row_number() over (partition by step_id order by submission_time),result,submission_time-attempt_time
from student inner join step_student using(student_id)
inner join step using(step_id)
inner join lesson using(lesson_id)
where student_name='student_59'
),
get_time (avg_time) as
(
select avg(att_time)
from get_res where att_time<=3600
),
get_final_res as
(
select *, case
when att_time>3600 then (select avg_time from get_time)
else att_time end as new_time from get_res
)
select stud as Студент,shag as Шаг, rn as Номер_попытки, res as Результат, sec_to_time(round(new_time)) as Время_попытки, round(new_time/sum(new_time) over (partition by shag)*100,2) as Относительное_время
from get_final_res
order by stid,3;


--Выделить группы обучающихся по способу прохождения шагов:
--I группа - это те пользователи, которые после верной попытки решения шага делают неверную (скорее всего для того, чтобы поэкспериментировать или проверить, как работают примеры);
--II группа - это те пользователи, которые делают больше одной верной попытки для одного шага (возможно, улучшают свое решение или пробуют другой вариант);
--III группа - это те пользователи, которые не смогли решить задание какого-то шага (у них все попытки по этому шагу - неверные).
--Вывести группу (I, II, III), имя пользователя, количество шагов, которые пользователь выполнил по соответствующему способу. Столбцы назвать Группа, Студент, Количество_шагов. Отсортировать информацию по возрастанию номеров групп, потом по убыванию количества шагов и, наконец, по имени студента в алфавитном порядке.
select 'I' as Группа,student_name as Студент, sum( case when result='correct' and new_res='wrong' then 1 else 0 end) as Количество_шагов from ( select student_name, result, lead(result) over (partition by student_id,step_id order by submission_time) as new_res from student inner join step_student using(student_id) )as sq
group by 1,2
having sum( case when result='correct' and new_res='wrong' then 1 else 0 end)>0
UNION
select distinct 'II' as Группа,student_name as Студент, count(step_id) as Количество_шагов from
(select student_name, step_id from student inner join step_student using(student_id)
where result='correct'
group by 1,2
having count(*)>1) as sq
group by 1,2
UNION
select distinct 'III' as Группа,student_name as Студент, count(step_id) as Количество_шагов from 
(select student_name, step_id from student inner join step_student using(student_id)
group by 1,2
having sum(if(result='correct',1,0))=0) as sq2
group by 1,2
order by 1, 3 desc, 2