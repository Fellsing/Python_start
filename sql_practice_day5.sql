--task. Повысить итоговые баллы абитуриентов в таблице applicant на значения дополнительных баллов
update applicant inner join (select enrollee_id, if(sum(bonus) is null, 0 , sum(bonus)) as Бонус from enrollee left join enrollee_achievement using(enrollee_id)
left join achievement using(achievement_id)
group by 1
order by 1) as bonuses using(enrollee_id)
set itog= itog+Бонус;


--task2. Занести в столбец str_id таблицы applicant_order нумерацию абитуриентов, которая начинается с 1 для каждой образовательной программы.
set @pr:=0;
set @numer:=1;
update applicant_order ao
inner join (select *,if(program_id<>@pr,@numer:=1, @numer:=@numer+1) as strr_id, @pr:=program_id as pr_id from applicant_order) t on ao.program_id=t.pr_id and ao.enrollee_id=t.enrollee_id
set ao.str_id=t.strr_id;
select * from applicant_order;


--task3. Отобрать все шаги, в которых рассматриваются вложенные запросы (то есть в названии шага упоминаются вложенные запросы). Указать к какому уроку и модулю они относятся. Для этого вывести 3 поля:
--в поле Модуль указать номер модуля и его название через пробел;
--в поле Урок указать номер модуля, порядковый номер урока (lesson_position) через точку и название урока через пробел;
--в поле Шаг указать номер модуля, порядковый номер урока (lesson_position) через точку, порядковый номер шага (step_position) через точку и название шага через пробел.
--Длину полей Модуль и Урок ограничить 19 символами, при этом слишком длинные надписи обозначить многоточием в конце (16 символов - это номер модуля или урока, пробел и  название Урока или Модуля,к ним присоединить "..."). Информацию отсортировать по возрастанию номеров модулей, порядковых номеров уроков и порядковых номеров шагов.
select concat(left(concat(module_id,' ',module_name),16),'...') as Модуль,concat(left(concat(module_id,'.',lesson_position,' ', lesson_name),16),'...') as Урок,
concat(module_id,'.',lesson_position,'.',step_position,' ', step_name) as Шаг from module inner join lesson using(module_id) inner join step using(lesson_id)
where step_name like('%Вложенн%запрос%') or step_name like('%вложенн%запрос%')
order by module_id, lesson_id,step_id ;


--task4. Заполнить таблицу step_keyword следующим образом: если ключевое слово есть в названии шага, то включить в step_keyword строку с id шага и id ключевого слова. 
insert into step_keyword(step_id,keyword_id)
select distinct step.step_id, keyword.keyword_id from step, keyword
where step_name regexp concat('\\b', keyword_name,'\\b')
and (step_id,keyword_id) not in (select step_id,keyword_id from step_keyword);
select * from step_keyword;