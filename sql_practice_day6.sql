--Реализовать поиск по ключевым словам. Вывести шаги, с которыми связаны ключевые слова MAX и AVG одновременно. Для шагов указать id модуля, позицию урока в модуле, позицию шага в уроке через точку, после позиции шага перед заголовком - пробел. Позицию шага в уроке вывести в виде двух цифр (если позиция шага меньше 10, то перед цифрой поставить 0). Столбец назвать Шаг. Информацию отсортировать по первому столбцу в алфавитном порядке.
select distinct concat(module_id,'.', lesson_position, '.', if(step_position<10, concat('0',step_position), step_position),' ',step_name) as Шаг from module inner join lesson using(module_id)
inner join step using(lesson_id)
where step_id in (select distinct step_id from step_keyword sk inner join keyword using(keyword_id) where keyword_name in('MAX','AVG')
group by 1
having count(distinct keyword_name)=2)
order by 1;


--Отнести каждого студента к группе,  в зависимости от пройденных заданий:Пройденными считаются задания с хотя бы одним верным ответом. В таблице step_student сохраняются все попытки пользователей, следовательно, могут быть пользователи, у которых на одно задание есть несколько верных попыток.
--Посчитать, сколько студентов относится к каждой группе. Столбцы назвать Группа, Интервал, Количество. Указать границы интервала.
SELECT CASE
        WHEN rate <= 10 THEN "I"
        WHEN rate <= 15 THEN "II"
        WHEN rate <= 27 THEN "III"
        ELSE "IV"
    END AS Группа,
    case
        when rate <= 10 then 'от 0 до 10'
        when rate <= 15 then 'от 11 до 15'
        when rate <= 27 then 'от 16 до 27'
        else 'больше 27'
    end as Интервал,
    count(*) as Количество
FROM      
    (
     SELECT student_name, count(*) as rate
     FROM 
         (
          SELECT student_name, step_id
          FROM 
              student 
              INNER JOIN step_student USING(student_id)
          WHERE result = "correct"
          GROUP BY student_name, step_id
         ) query_in
     GROUP BY student_name 
     ORDER BY 2
    ) query_in_1
group by 1,2;


--Для каждого шага вывести процент правильных решений. Информацию упорядочить по возрастанию процента верных решений. Столбцы результата назвать Шаг и Успешность, процент успешных решений округлить до целого.
WITH get_count_correct (st_n_c, count_correct) 
  AS (
    SELECT step_name, count(*)
    FROM 
        step 
        INNER JOIN step_student USING (step_id)
    WHERE result = "correct"
    GROUP BY step_name
   ),
  get_count_wrong (st_n_w, count_wrong) 
  AS (
    SELECT step_name, count(*)
    FROM 
        step 
        INNER JOIN step_student USING (step_id)
    WHERE result = "wrong"
    GROUP BY step_name
   )  
SELECT st_n_c AS Шаг,
    if(ROUND(count_correct / (count_correct + count_wrong) * 100) is Null, 100,ROUND(count_correct / (count_correct + count_wrong) * 100) ) AS Успешность
FROM  
    get_count_correct 
    LEFT JOIN get_count_wrong ON st_n_c = st_n_w
UNION
SELECT st_n_w AS Шаг,
    if(ROUND(count_correct / (count_correct + count_wrong) * 100) is Null, 0,ROUND(count_correct / (count_correct + count_wrong) * 100) ) AS Успешность
FROM  
    get_count_correct 
    RIGHT JOIN get_count_wrong ON st_n_c = st_n_w
ORDER BY 2, 1 ;


--Вычислить прогресс пользователей по курсу. Прогресс вычисляется как отношение верно пройденных шагов к общему количеству шагов в процентах, округленное до целого. В нашей базе данные о решениях занесены не для всех шагов, поэтому общее количество шагов определить как количество различных шагов в таблице step_student.
--Тем пользователям, которые прошли все шаги (прогресс = 100%) выдать "Сертификат с отличием". Тем, у кого прогресс больше или равен 80% - "Сертификат". Для остальных записей в столбце Результат задать пустую строку ("").
--Информацию отсортировать по убыванию прогресса, затем по имени пользователя в алфавитном порядке.
set @all:=(select count(distinct step_id) from step_student );
with get_count_correct(student_name, cnt_c)
as ( 
    select student_name, count(distinct step_id) from step_student inner join student using(student_id)
    where result='correct'
    group by 1
),
get_res(Студент,Прогресс)
as (select student_name as Студент, round(cnt_c/@all*100) as Прогресс from get_count_correct)
select Студент,Прогресс, case
when Прогресс=100 then 'Сертификат с отличием'
when Прогресс>=80 then 'Сертификат'
else '' end as Результат from get_res
order by 2 desc, 1;

--Для студента с именем student_61 вывести все его попытки: название шага, результат и дату отправки попытки (submission_time). Информацию отсортировать по дате отправки попытки и указать, сколько минут прошло между отправкой соседних попыток. Название шага ограничить 20 символами и добавить "...". Столбцы назвать Студент, Шаг, Результат, Дата_отправки, Разница.
select student_name as Студент, concat(left(step_name,20),'...') as Шаг, result as Результат ,from_unixtime(submission_time) as Дата_отправки, sec_to_time(ifnull(submission_time-lag(submission_time) over (order by submission_time),0)) as Разница 
from student inner join step_student using(student_id)
inner join step using(step_id)
where student_name='student_61'
order by 4;


--Посчитать среднее время, за которое пользователи проходят урок по следующему алгоритму:

--для каждого пользователя вычислить время прохождения шага как сумму времени, потраченного на каждую попытку (время попытки - это разница между временем отправки задания и временем начала попытки), при этом попытки, которые длились больше 4 часов не учитывать, так как пользователь мог просто оставить задание открытым в браузере, а вернуться к нему на следующий день;
--для каждого студента посчитать общее время, которое он затратил на каждый урок;
--вычислить среднее время выполнения урока в часах, результат округлить до 2-х знаков после запятой;
--вывести информацию по возрастанию времени, пронумеровав строки, для каждого урока указать номер модуля и его позицию в нем.
--Столбцы результата назвать Номер, Урок, Среднее_время.
select row_number() over (order by Среднее_время) as Номер, Урок, Среднее_время
from (select Урок,round(avg(Среднее_время),2) as  Среднее_время from
(
select student_id,concat(module_id,'.',lesson_position,' ', lesson_name) as Урок,
sum((submission_time-attempt_time)/3600) as Среднее_время
from module inner join lesson using(module_id)
inner join step using(lesson_id)
inner join step_student se using(step_id)
where (se.submission_time-se.attempt_time)/3600<4
group by 1,2) as sq1 group by 1) as sq;
