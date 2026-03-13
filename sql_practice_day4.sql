#Вывести название образовательной программы и фамилию тех абитуриентов, которые подавали документы на эту образовательную программу, но не могут быть зачислены на нее. Эти абитуриенты имеют результат по одному или нескольким предметам ЕГЭ, необходимым для поступления на эту образовательную программу, меньше минимального балла. Информацию вывести в отсортированном сначала по программам, а потом по фамилиям абитуриентов виде.
#Например, Баранов Павел по «Физике» набрал 41 балл, а  для образовательной программы «Прикладная механика» минимальный балл по этому предмету определен в 45 баллов. Следовательно, абитуриент на данную программу не может поступить.
select distinct name_program, name_enrollee from enrollee inner join program_enrollee using(enrollee_id)
inner join program using(program_id)
inner join enrollee_subject on enrollee.enrollee_id=enrollee_subject.enrollee_id
inner join subject s using(subject_id)
inner join program_subject ps on ps.subject_id=s.subject_id and program.program_id=ps.program_id
where result<min_result
group by 1,2
order by 1,2;

#в данном случае, dictinct не является лишним, т.к. group by в некоторых конкретных случаях будет дублировать записи