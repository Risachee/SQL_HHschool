-- ============================================================
-- Домашнее задание к лекции «SQL. Введение»
-- Школа Аналитиков · учебная база hh_school
-- Автор: Боталова Валерия Владимировна
-- ============================================================
-- Формат: задания по порядку, каждое начинается с комментария
-- с номером; под каждым запросом — вывод (2–3 предложения).
-- Запрос без вывода не засчитывается.
-- ============================================================

SET search_path TO hh_school;

-- ============================================================
-- БЛОК А. Разминка: термины и структура (текстом)
-- ============================================================

-- ЗАДАНИЕ А1
-- 1. Категория и конкретный тип колонок:
--    vacancies.salary_from        — категория: числовой   тип: int4
--    vacancies.vacancy_name       — категория: текстовый   тип: text
--    vacancies.published_at       — категория: дата и время   тип: timestamp
--    employers.is_accredited_it   — категория: логический  тип: bool
--    responses.created_at         — категория: дата и время   тип: timestamp
--
-- 2. Первичные ключи таблиц:
--    areas: area_id
--    employers: employer_id
--    vacancies: vacancy_id
--    vacancy_details: vacancy_id (Первичный ключ этой таблицы ссылается на первичный ключ другой таблицы vacancies, благодаря чему связь между таблицами 1 к 1)
--    responses: response_id
--
-- 3. Почему vacancy_name не может быть первичным ключом:
--    Запрос для подтверждения числом:
-- запрос:

SELECT COUNT(DISTINCT vacancy_name) AS unic_by_name,
	   COUNT(DISTINCT vacancy_id) AS unic_by_id,
	   COUNT(*) AS vacancies_total
  FROM vacancies;

SELECT vacancy_name,
	   COUNT(*) AS vacancies_total
  FROM vacancies
 GROUP BY 1
 ORDER BY 2 DESC
 LIMIT 1
-- Вывод: 
--    Первичный ключ служит уникальным идентификатором строки. Результат запроса показывает, что уникальных вакансий по имени - 18,
--	  но в таблице содержится 52 вакансии. Это связано с тем, что в разных компаниях существуют одинаковые позиции, чьи названия
--	  совпадают. В таком случае стоит каждой вакансии присваивать отдельный id, учитывая все строки и значения вакансии.
--    Второй запрос показывает, что самое частое название вакансии - Стажер-аналитик.
-- 4. Что произойдёт при записи строки «по договорённости» в salary_from:
--    Значение salary_from числовое, при вводе текста произойдет ошибка. Такое поведение может предостеречь от ошибок в
--    работе с данными в статистических/математических вычислениях.


-- ============================================================
-- БЛОК Б. Первые запросы: SELECT, WHERE, ORDER BY
-- ============================================================

-- ЗАДАНИЕ Б1
-- Запрос: experience
SELECT 
  DISTINCT experience
  FROM vacancies;

-- Запрос: employment
SELECT 
  DISTINCT employment 
  FROM vacancies;

-- Запрос: professional_role
SELECT 
  DISTINCT professional_role 
  FROM vacancies;




-- Вывод:
-- Различных значений в:
-- experience - 3 (От 3 до 6 лет, Нет опыта, От 1 года до 3 лет), 
-- employment - 3 (Частичная занятость, Стажировка, Полная занятость),
-- professional_role - 5 (Дата-инженер, Разработчик, Продуктовый аналитик, Аналитик данных, Тестировщик)
-- Проблем с качеством данных нет, каждое значение описывает разные опыт, занятость, и роль, null значения отсутствуют.


-- ЗАДАНИЕ Б2
-- Запрос 1: стажировки в Москве без опыта, вакансия открыта
SELECT v.vacancy_id AS vacancy_id,
	   v.vacancy_name AS vacancy_name,
	   v.salary_from AS salary_from,
	   v.published_at::date AS published_date
  FROM vacancies AS v
  JOIN areas AS a 
	ON v.area_id = a.area_id
 WHERE a.area_name = 'Москва'
   AND v.employment = 'Стажировка'
   AND v.experience = 'Нет опыта'
   AND v.closed_at IS NULL
 ORDER BY published_at DESC;
-- Запрос 2: топ-10 вакансий по salary_from
-- C фильтром по Москве
SELECT v.vacancy_name AS vacancy_name,
	   v.professional_role AS professional_role,
	   v.salary_from AS salary_from
  FROM vacancies AS v
  JOIN areas AS a 
    ON v.area_id = a.area_id
 WHERE a.area_name = 'Москва'
   AND v.employment = 'Стажировка'
   AND v.experience = 'Нет опыта'
   AND v.closed_at IS NULL
   AND v.salary_from IS NOT NULL
 ORDER BY salary_from DESC
 LIMIT 10;
-- Без фильтра
SELECT v.vacancy_name AS vacancy_name,
  	   v.professional_role AS professional_role,
  	   v.salary_from AS salary_from
  FROM vacancies AS v
  JOIN areas AS a 
  	ON v.area_id = a.area_id
 WHERE v.employment = 'Стажировка'
   AND v.experience = 'Нет опыта'
   AND v.closed_at IS NULL
   AND v.salary_from IS NOT NULL
 ORDER BY
       salary_from DESC
 LIMIT 10;

-- Вывод:
-- Первый запрос нашел 7 вакансий, второй 9. Можно сделать вывод, что большая часть открытых стажировок без опыта 
-- находится в Москве, за её пределами всего 2 подходящие вакансии. 
-- Также количество вакансий делает ограничение по топ-10 малофункциональным, так как
-- общее количество вакансий под заданный фильтр меньше 10.


-- ЗАДАНИЕ Б3
-- Ловушка 1. NULL — выполнить и объяснить результат
SELECT COUNT(*)
  FROM vacancies
 WHERE closed_at = NULL;

SELECT COUNT(*)
  FROM vacancies
 WHERE closed_at IS NULL;

-- Ловушка 2. AND / OR — выполнить и объяснить результат
SELECT COUNT(*) 
  FROM vacancies
 WHERE area_id = 1 
	OR area_id = 2 
   AND experience = 'Нет опыта';

SELECT COUNT(*) 
  FROM vacancies
 WHERE (area_id = 1 OR area_id = 2) 
   AND experience = 'Нет опыта';

-- Вывод:
-- 1 ловушка:
-- null в колонке closed_at означает, что вакансия еще открыта. 
-- Так как null - это пустое/неизвестное значение, сравнение с чем угодно, даже с null, приведет к ответу 0/null, что может искривить значения и дать
-- некорректные данные, как в запросах выше. В таблице есть открытые вакансии, но при использовании оператора сравнения, количество таких вакансий равно 0. 
-- Поэтому важно использовать "is null" вместо "= null".
--2 ловушка:
-- Первый запрос составлял список вакансий ИЛИ из города 1, независимо от опыта, ИЛИ из города 2 обязательно без опыта. Это обоснованно приоритетом чтения and и or. 
-- And имеет более высокий приоритет и "слипает" условия рядом (правое и левое), если скобки отсутствуют.
-- Второй: вакансии без опыта из города 1 или 2.  
-- Для поиска вакансий из Питера/Москвы без опыта используется 2 запрос.
-- ============================================================
-- БЛОК В. Агрегации и метрики
-- ============================================================

-- ЗАДАНИЕ В1
-- Запрос 1: счётчики (строки, зарплата указана, направления, работодатели)
SELECT COUNT(*) AS 	row_total,
	   COUNT(salary_from) AS salary_from_vacancies_total,
	   COUNT(DISTINCT professional_role) AS professional_role_total,
	   COUNT(DISTINCT employer_id) AS employers_total
  FROM vacancies AS v;
-- Запрос 2: доля активных вакансий (без JOIN)
SELECT COUNT(closed_at) AS closed_vacancies_total,
	   (COUNT(*) - COUNT(closed_at)) AS open_vacancies_total,
	   round(100.0 * (COUNT(*) - COUNT(closed_at))/ COUNT(*), 1) AS open_vacancies_share
  FROM vacancies AS v;


-- Вывод:
-- Запрос 1: count(*) - считает все значения (null в том числе),
-- 			 count(column) - считает только известные значения (без null)
--			 count(distinct column) - считает только уникальные значения (без null)
-- По результатам запроса можно увидеть, что всего у нас вакансий (count(*)) 52,
-- вакансии с salary_from без null (count(salary_from)) 44 (то есть вакансий без нижней зп 8 (52 - 44)),
-- а уникальных значений (count(distinct professional_role)) 5.
-- Запрос 2:
-- На данный момент из 52 вакансий открыты 33, что равно 63% от всех вакансий. Закрыты 19 вакансий, это 37%.
-- ЗАДАНИЕ В2
-- Запрос 1: направления — вакансии, работодатели, средняя зарплата
SELECT professional_role AS professional_role,
	   COUNT(*) AS vacancies_total,
	   COUNT(DISTINCT employer_id) AS employers_total,
	   round(avg(salary_from), 0) AS avg_salary_from
  FROM vacancies AS v
 GROUP BY professional_role
 ORDER BY COUNT(*) DESC;
-- Запрос 2: то же, только направления с ≥ 5 открытыми вакансиями (WHERE + HAVING)
SELECT professional_role AS professional_role,
	   COUNT(*) AS vacancies_total,
	   COUNT(DISTINCT employer_id) AS employers_total,
	   round(avg(salary_from), 0) AS avg_salary_from
  FROM vacancies AS v
 WHERE closed_at IS NULL
 GROUP BY rofessional_role
HAVING COUNT(*) >= 5
 ORDER BY COUNT(*) DESC;

-- Вывод:
-- Выводы по 1 запросу:
-- "Больше половины рынка учебной базы занимают аналитики данных (11) и разработчики (8).
-- Самая высокая средняя нижняя граница у разрабочиков (95000), дата-инженеров (79000) и дата-аналитиков (74091)."
-- Но мы не знаем, как именно распределены вакансии по опыту, городам,типу занятости.
-- Выводы, которые я написала выше, не совсем релевантны для разных типов соискателей.
-- По ней не совсем корректно можно определить, какой рынок доступен соискателю. Для этого
-- стоило бы сделать групировку по городу, опыту, занятости, там же посчитать среднее для каждой группы.

--Выводы по 2 запросу:
-- Where - условия до агрегации, в having - после. Попытка подсчета в where приведет к ошибке,
-- т.к. where работает с полной таблицей и всеми значениями, не разделяя на группы.

-- Указанное среднее значение - это среднее во всей вакансии, среди всех групп, городов.
-- Оно не разделено по группам, и поэтому точно ответить, что значит это среднее на данном этапе сложно.
-- Если среди направления много вакансий на полной занятости и старших должностях, общее среднее будет больше,
-- чем если в другой сфере больше вакансий начального уровня и не на полную занятость.
	   
	 
-- ============================================================
-- БЛОК Г. Соединение таблиц
-- ============================================================

-- ЗАДАНИЕ Г1
-- Запрос: топ-5 по salary_from с названием компании и городом (псевдонимы таблиц)
SELECT v.vacancy_name,
	   e.employer_name,
	   a.area_name,
	   v.salary_from
  FROM vacancies AS v
	   JOIN areas a 
	   ON a.area_id = v.area_id
	   JOIN employers AS e 
	   ON e.employer_id = v.employer_id
 WHERE salary_from IS NOT NULL
 ORDER BY salary_from DESC
 LIMIT 5;
-- Вывод:
-- При вводе area_id возникнет ошибка: неоднозначная ссылка на столбец "area_id". Так происходит, потому что area_id в нескольких таблицах - vacancies, employers, areas
--
-- ЗАДАНИЕ Г2
-- Запрос 1: все работодатели, число вакансий и откликов (LEFT JOIN)
SELECT e.employer_name,
	   COUNT(DISTINCT v.vacancy_id ) AS vacancies_total,
	   COUNT(r.response_id) AS responses_total
  FROM employers AS e
	   LEFT JOIN vacancies AS v 
	   ON e.employer_id = v.employer_id
	   LEFT JOIN responses r 
	   ON r.vacancy_id = v.vacancy_id
 GROUP BY e.employer_name
 ORDER BY responses_total DESC;


-- Запрос 2: тот же запрос с INNER JOIN
SELECT e.employer_name,
	   COUNT(DISTINCT v.vacancy_id ) AS vacancies_total,
	   COUNT(r.response_id) AS responses_total
  FROM employers AS e
	   JOIN vacancies AS v 
	   ON e.employer_id = v.employer_id
	   JOIN responses AS r 
	   ON r.vacancy_id = v.vacancy_id
 GROUP BY e.employer_name
 ORDER BY responses_total DESC;


-- Вывод:
-- count(*) считает все строки после соединения, а одна вакансия может иметь несколько откликов, из-за чего количество строк будет больше, чем количество вакансий.
-- После inner join исчезает компания ГринЭнерго, так как у неё нет откликов. Это приводит к ошибке выжившего: видно только компании, собравшие отклики, партнеры без откликов теряются.
-- Для HR-отчета это критично, так как мы не можем диагностировать проблему неэффективных вакансий у молчащих работодателей.
-- В результат inner join попадают только те строки, для которых есть совпадение в обеих таблицах по заданному условию. Left join сохраняет все значения из левой таблицы, даже
-- если совпадений в правой не было.

-- ============================================================
-- БЛОК Д. Функции и финальный кейс
-- ============================================================

-- ЗАДАНИЕ Д1
-- Запрос: помесячная динамика откликов и конверсия
-- (месяц как дата, условный агрегат, nullif в знаменателе)
SELECT DATE_TRUNC('month', created_at)::date AS month,
       MIN(created_at)::date AS min_date,
       MAX(created_at)::date AS max_date,
	   COUNT(*) FILTER(WHERE status = 'invited') AS invitations_total,
	   COUNT(*) AS responses_count,
	   ROUND(100.0 * (COUNT(*) FILTER(WHERE status = 'invited'))/ NULLIF(COUNT(*), 0), 0) AS invitation_conversion,
	   ROUND(100.0 * (COUNT(*) FILTER(WHERE status = 'viewed'))/ NULLIF(COUNT(*), 0), 0) AS view_conversion,
	   ROUND(100.0 * (COUNT(*) FILTER(WHERE status = 'new'))/ NULLIF(COUNT(*), 0), 0) AS new_response_conversion,
	   ROUND(100.0 * (COUNT(*) FILTER(WHERE status = 'rejected'))/ NULLIF(COUNT(*), 0), 0) AS rejection_conversion
  FROM responses AS r
 GROUP BY 1
 ORDER BY 4 DESC;

-- Вывод: 
-- Больше всего конверсия в июне, она равна 19.5%.
-- Для более объективной оценки, я проверила конверсию отказов, новых откликов и просмотров. По результатом - в июне 
-- конверсия отказов на 2 месте по наименьшей. Следуя из этого, результатам можно доверять. Количество откликов приемлимое,
-- дополнительные проверки подтвердили этот вывод.
-- Правка: Проверила у каждого месяца дату первого отклика и последнего. 
-- В августе данные есть только за половину месяца, из-за чего данные использовать для анализа нельзя.


-- ЗАДАНИЕ Д2
-- Запрос: таблица по направлениям (вакансии, отклики, приглашения,
-- откликов на вакансию, конверсия)
SELECT v.professional_role,
	  COUNT(DISTINCT v.vacancy_id) AS vacancies_total,
	   COUNT(r.response_id) AS responses_count,
	   COUNT(*) FILTER(WHERE r.status = 'invited') AS invitations_total,
	   ROUND(COUNT(r.response_id)::NUMERIC / NULLIF(COUNT(DISTINCT v.vacancy_id), 0), 1) AS responses_per_vacancy,
	   ROUND(100.0 * (COUNT(r.response_id) FILTER(WHERE r.status = 'invited'))/ NULLIF(COUNT(r.response_id), 0), 1) AS invitation_conversion
  FROM vacancies AS v
	   LEFT JOIN responses AS r 
  	   ON r.vacancy_id = v.vacancy_id
 GROUP BY 1
 ORDER BY 3,4 DESC;
-- Письменные ответы:
-- 1. Совпадает ли направление с наибольшим числом вакансий с направлением
--    с наибольшей конверсией? 
-- Нет, не совпадает. Большее число вакансий у стажеров-аналитиков данных (6 вакансий), но большая конверсия у 
-- джунов-тестировщиков (50%).
-- 2. Какое направление выбрать и почему (опираясь на два столбца):
-- Для выбора направления я бы опиралась на количество откликов и конверсию приглашений. 
-- Опираться исключительно на конверсию не стоит, так как конверсия может быть большой, но не релевантной для анализа,
-- как получается с джуниор тестировщиками. Конверсия равна 50 - но вакансий всего 2, 1 из которых с приглашением. 
-- Нельзя сказать, что каждый второй получает приглашение.
-- 3. Оговорка к выводу:
-- Данные не учитывают качественную воронку (релевантность резюме кандидатов конкретным стекам внутри направлений), 
-- сезонность размещения вакансий и разницу в размере компаний-работодателей, 
-- что делает результат не совсем подходящим для решения о направлении откликов

-- ============================================================
-- БЛОК Е. Со звёздочкой
-- ============================================================

-- ЗАДАНИЕ Е1
-- Исходный запрос (выполнить и посмотреть результат):
-- SELECT v.professional_role,
-- count(*) AS vacancies,
-- sum(v.salary_from) AS total_salary,
-- count(r.response_id) / count(*) AS responses_per_vacancy
-- FROM vacancies v
-- JOIN responses r ON v.vacancy_id = r.vacancy_id
-- WHERE v.closed_at = NULL
-- GROUP BY 1;
--
-- Ошибки (минимум четыре):
-- 1. "= NULL" вместо "is NULL". Невозможно сравнить строку с неизвесностью.
-- 2. count(*) вместо count(distinct v.vacancy_id) для подсчета количества вакансий. После объединения таблиц 
-- строки повторяются и накладываются друг на друга (на одну вакансию может быть несколько откликов).
-- 3. join вместо "left join". Без left в результат не попадут должности без откликов, если таковые будут.
-- 4. count считает строки после JOIN, а не вакансии
-- 5. sum(salary_from) показывает сумму всех вакансий по направлению нижних порогов зарплаты. 
-- Для сравнения порогов направлений стоит использовать avg_salary_from. 
-- Эта метрика показывает среднюю нижнюю границу зарплаты среди открытых вакансий направления.
--
-- Исправленный запрос:

WITH responses_by_vacancy AS (
     SELECT vacancy_id,
	        COUNT(*) AS responses
	   FROM responses
	  GROUP BY vacancy_id
	  )
SELECT v.professional_role,
	   COUNT(DISTINCT(v.vacancy_id)) AS vacancies,
	   ROUND(AVG(v.salary_from), 0) AS avg_salary_from,
	   ROUND(AVG(COALESCE(r.responses, 0)), 0) AS responses_per_vacancy
  FROM vacancies v
	   LEFT JOIN responses_by_vacancy AS r 
	   ON r.vacancy_id = v.vacancy_id
 WHERE v.closed_at IS NULL
 GROUP BY 1;
-- Какие два правила из лекции защитили бы от этих ошибок при написании запроса:
-- 1. Сравнение с NULL никогда не истинно — пустоту проверяют оператором IS NULL
-- 2. LEFT JOIN сохраняет все строки левой таблицы: если совпадения нет, поля правой таблицы заполняются NULL

