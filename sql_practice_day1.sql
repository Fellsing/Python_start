#there are most interesting tasks today
#task. Для каждой отдельной книги необходимо вывести информацию о количестве проданных экземпляров и их стоимости за 2020 и 2019 год .
#За 2020 год проданными считать те экземпляры, которые уже оплачены. Вычисляемые столбцы назвать Количество и Сумма. Информацию отсортировать по убыванию стоимости.
select title, sum(Количество) as Количество, sum(Сумма) as Сумма from (select book.title, sum(buy_book.amount) as Количество, sum(buy_book.amount*book.price) as Сумма
from book inner join buy_book using(book_id)
inner join buy_step using(buy_id)
where buy_step.step_id=1 and date_step_end is not null
group by 1
union
select book.title, sum(ba.amount) as Количество , sum(ba.amount*ba.price) as Сумма 
from buy_archive ba inner join book On ba.book_id=book.book_id
group by 1) as qr
group by 1
order by 3 desc;



#task2. Сравнить ежемесячную выручку от продажи книг за текущий и предыдущий годы. 
#Для этого вывести год, месяц, сумму выручки в отсортированном сначала по возрастанию месяцев, затем по возрастанию лет виде. Название столбцов: Год, Месяц, Сумма.
select year(date_step_beg) as Год, monthname(date_step_beg) as Месяц, sum(buy_book.amount*book.price) as Сумма
from book inner join buy_book using(book_id)
inner join buy_step using(buy_id)
where buy_step.step_id=1 and date_step_end is not null
group by 1,2
UNION
select year(date_payment) as Год, monthname(date_payment) as Месяц, sum(price*amount) as Сумма from buy_archive
group by 1,2
order by 2,1;


#task3. Вывести жанр (или жанры), в котором было заказано больше всего экземпляров книг, указать это количество . Последний столбец назвать Количество.
select name_genre, sum(buy_book.amount) as Количество from genre left join book using(genre_id)
left join buy_book using(book_id)
group by name_genre
having Количество=(select max(sm) from(select sum(buy_book.amount) as sm from genre left join book using(genre_id)
left join buy_book using(book_id) group by book.genre_id) as qr);


#select max(sm) from(select sum(book.amount) as sm from genre inner join book using(genre_id) group by book.genre_id) as qr;



#task4. Одно из применений left join. Посчитать, сколько раз была заказана каждая книга, для книги вывести ее автора (нужно посчитать, в каком количестве заказов фигурирует каждая книга).  
#Вывести фамилию и инициалы автора, название книги, последний столбец назвать Количество. Результат отсортировать сначала  по фамилиям авторов, а потом по названиям книг.
select name_author, title, count(buy_book_id) as Количество from
book left join author using(author_id)
left join buy_book on buy_book.book_id=book.book_id
group by name_author,title
order by 1,2;


#task5. Для книг, которые уже есть на складе (в таблице book), но по другой цене, чем в поставке (supply),  необходимо в таблице book увеличить количество на значение, указанное в поставке,  и пересчитать цену. А в таблице  supply обнулить количество этих книг.
update book
inner join author on author.author_id=book.author_id
inner join supply on supply.title=book.title and supply.author=author.name_author
set book.price = (book.price*book.amount+supply.price*supply.amount)/(supply.amount+book.amount), book.amount=book.amount+supply.amount, supply.amount=0
where book.price!=supply.price;

select * from book;
select * from supply;


#task6. Удаление записей, использование связанных таблиц. Удалить всех авторов, которые пишут в жанре "Поэзия". Из таблицы book удалить все книги этих авторов. В запросе для отбора авторов использовать полное название жанра, а не его id.
delete from author
using author inner join book using(author_id) inner join genre on genre.genre_id = book.genre_id
where genre.name_genre='Поэзия';
select * from author;
select * from book;