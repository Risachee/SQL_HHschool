-- ============================================================
-- Домашнее задание к лекции «Продвинутый SQL»
-- Школа Аналитиков · учебная база hh_school
-- Автор: Боталова Валерия Владимировна
-- ============================================================

-- ============================================================
-- БЛОК А. Качество и подготовка данных 
-- ============================================================

--ЗАДАНИЕ 1

-- Связь без отклика
SELECT
       COUNT(*) AS problem_count,
       STRING_AGG(call_id::TEXT, ', ' ORDER BY call_id) AS problem_ids
  FROM calls
 WHERE response_id IS NULL;
-- 8 звонков без указанного отклика. Такие записи нельзя надёжно связать с конкретным откликом,
-- поэтому они не должны участвовать в анализе коммуникаций
SELECT
       COUNT(*) AS problem_count,
       STRING_AGG(message_id::TEXT, ', ' ORDER BY message_id) AS problem_ids
  FROM messages
  WHERE response_id IS NULL;
-- 0 сообщений без указанного отклика


-- Существование указанных откликов
SELECT
       COUNT(*) AS problem_count
  FROM calls c
  LEFT JOIN responses r
    ON c.response_id = r.response_id
 WHERE c.response_id IS NOT NULL
  AND r.response_id IS NULL;

SELECT
       COUNT(*) AS problem_count
  FROM messages m
  LEFT JOIN responses r
    ON m.response_id = r.response_id
 WHERE r.response_id IS NULL;
-- Все указанные отклики существуют

-- Соответствие идентификаторов

-- vacancy_id
SELECT
       COUNT(*) AS problem_count,
       STRING_AGG(c.call_id::TEXT, ', ' ORDER BY c.call_id) AS problem_ids
  FROM calls c
  JOIN responses r
    ON c.response_id = r.response_id
 WHERE c.vacancy_id <> r.vacancy_id;

SELECT
       COUNT(*) AS problem_count,
       STRING_AGG(m.message_id::TEXT, ', ' ORDER BY m.message_id) AS problem_ids
  FROM messages m
  JOIN responses r
    ON m.response_id = r.response_id
 WHERE m.vacancy_id <> r.vacancy_id;

-- employer_id
SELECT
       COUNT(*) AS problem_count,
       STRING_AGG(c.call_id::TEXT, ', ' ORDER BY c.call_id) AS problem_ids
  FROM calls c
  JOIN responses r
    ON c.response_id = r.response_id
  JOIN vacancies v
    ON r.vacancy_id = v.vacancy_id
 WHERE c.employer_id <> v.employer_id;

SELECT
       COUNT(*) AS problem_count,
       STRING_AGG(m.message_id::TEXT, ', ' ORDER BY m.message_id) AS problem_ids
  FROM messages m
  JOIN responses r
    ON m.response_id = r.response_id
  JOIN vacancies v
    ON r.vacancy_id = v.vacancy_id
 WHERE m.employer_id <> v.employer_id;
-- Несоответсвия между идентификаторами не обнаружены

-- Время отклика и связи
SELECT
       COUNT(*) AS problem_count,
       STRING_AGG(c.call_id::TEXT, ', ' ORDER BY c.call_id) AS problem_ids
  FROM calls c
  JOIN responses r
    ON c.response_id = r.response_id
 WHERE c.call_at < r.created_at;

SELECT
    COUNT(*) AS problem_count,
    STRING_AGG(m.message_id::TEXT, ', ' ORDER BY m.message_id) AS problem_ids
FROM messages m
JOIN responses r
    ON m.response_id = r.response_id
WHERE m.sent_at < r.created_at;

-- Временная последовательность для связанных звонков и сообщений корректна.

-- Пропуски и соответствия
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE response_id IS NULL) AS null_response_id,
    COUNT(*) FILTER (WHERE employer_id IS NULL) AS null_employer_id,
    COUNT(*) FILTER (WHERE applicant_id IS NULL) AS null_applicant_id,
    COUNT(*) FILTER (WHERE vacancy_id IS NULL) AS null_vacancy_id,
    COUNT(*) FILTER (WHERE call_at IS NULL) AS null_call_at,
    COUNT(*) FILTER (WHERE caller_role IS NULL) AS null_caller_role,
    COUNT(*) FILTER (WHERE status IS NULL) AS null_status,
    COUNT(*) FILTER (WHERE call_tags IS NULL) AS null_call_tags,
    COUNT(*) FILTER (WHERE call_duration IS NULL) AS null_call_duration
FROM calls;

SELECT
       call_id,
       status,
       call_duration
  FROM calls
 WHERE
       (status = 'successful' AND call_duration IS NULL)
    OR
       (status IN ('unsuccessful', 'error') AND call_duration IS NOT NULL);

SELECT
       call_id,
       call_duration
  FROM calls
 WHERE status = 'successful'
  AND (call_duration IS NULL OR call_duration <= 0);

-- Есть пропуски в response_id (уже обнаруженные раннее), а также в длительности звонков, 
-- это объясняется логикой поля. Проверим, пропуски по статусам следующим запросом.  
-- Противоречий между status и call_duration не обнаружено.
-- Для успешных звонков длительность заполнена, для unsuccessful/error длительность отсутствует.
-- Также длительность во всех строках положительная.

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE response_id IS NULL) AS null_response_id,
    COUNT(*) FILTER (WHERE employer_id IS NULL) AS null_employer_id,
    COUNT(*) FILTER (WHERE applicant_id IS NULL) AS null_applicant_id,
    COUNT(*) FILTER (WHERE vacancy_id IS NULL) AS null_vacancy_id,
    COUNT(*) FILTER (WHERE sent_at IS NULL) AS null_sent_at,
    COUNT(*) FILTER (WHERE sender_role IS NULL) AS null_sender_role,
    COUNT(*) FILTER (WHERE message_text IS NULL) AS null_message_text,
    COUNT(*) FILTER (WHERE message_meta IS NULL) AS null_message_meta
FROM messages;

-- Пропусков в проверяемых полях messages не обнаружено.

-- Длительность успешных звонков
WITH successful_calls AS (
    SELECT
           call_id,
           call_duration
      FROM calls
     WHERE status = 'successful'
       AND call_duration IS NOT NULL
),
duration_stats AS (
    SELECT
           AVG(call_duration) AS avg_duration,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY call_duration) AS median_duration,
           PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY call_duration) AS p99_duration
      FROM successful_calls
)
SELECT
       avg_duration,
       median_duration,
       p99_duration,
       COUNT(*) FILTER (WHERE sc.call_duration > ds.p99_duration) AS calls_above_p99,
       AVG(sc.call_duration) FILTER (WHERE sc.call_duration <= ds.p99_duration) AS avg_duration_without_p99
  FROM successful_calls sc
 CROSS JOIN duration_stats ds
 GROUP BY
       ds.avg_duration,
       ds.median_duration,
       ds.p99_duration;

-- Средняя длительность: 467.28 сек.
-- Медиана: 438 сек.
-- 99-й перцентиль: 890.4 сек.
-- Количество звонков выше P99: 2.
-- Средняя длительность без значений выше P99: 462.49 сек.

-- Значения выше P99 - допустимые выбросы, а не ошибки: 
-- максимальная обнаруженная длительность составляет 899 мс, это 14.9 мин.
-- При расчёте типичной длительности звонка значения выше P99 можно исключить как экстремальные наблюдения, но не удалять их из исходных данных.

-- ============================================================
-- БЛОК Б. История коммуникаций
-- ============================================================

--ЗАДАНИЕ 2
WITH calls_prepared AS (
	SELECT
		 c.response_id,
		 c.employer_id,
		 c.call_id AS event_id,
		 c.call_at AS event_at,
		 'call' AS event_type
	FROM calls c 
	JOIN responses r
	  ON r.response_id = c.response_id
   WHERE c.response_id IS NOT NULL 
     AND c.status = 'successful'
     AND c.caller_role = 'employer'
     AND c.call_at >= r.created_at
     AND c.call_at < r.created_at + INTERVAL '7 days'
),
messages_prepared AS (
	SELECT
		 m.response_id, 
		 m.employer_id,
		 m.message_id AS event_id,
		 m.applicant_id, 
		 m.sent_at as event_at,
		 'message' AS event_type
	FROM messages m
	JOIN responses r 
	  ON m.response_id = r.response_id
   WHERE m.response_id IS NOT NULL 
     AND m.sender_role = 'employer'
     AND m.sent_at >= r.created_at
     AND m.sent_at < r.created_at + INTERVAL '7 days'
),
events_table AS (
	SELECT	
          response_id,
          employer_id,
          event_id,
          event_at,
          event_type
     FROM calls_prepared
	UNION ALL
	SELECT
          response_id,
          employer_id,
          event_id,
          event_at,
          event_type
     FROM messages_prepared
)
SELECT 
	COUNT(*) AS event_total,
	COUNT(DISTINCT response_id) AS response_communication,
	COUNT(*) FILTER (WHERE event_type = 'call') AS call_total,
	COUNT(*) FILTER (WHERE event_type = 'message') AS message_total
FROM events_table;

-- Вывод:
-- Общее количество событий: 1066
-- Количество различных откликов с коммуникацией: 374
-- Количество звонков: 78
-- Количество сообщений: 988

--ЗАДАНИЕ 3
-- Слой уровня события
WITH calls_prepared AS (
    SELECT
          c.response_id,
          c.employer_id,
          c.call_id AS event_id,
          c.call_at AS event_at,
         'call' AS event_type
     FROM calls c
     JOIN responses r
       ON r.response_id = c.response_id
    WHERE c.response_id IS NOT NULL
      AND c.status = 'successful'
      AND c.caller_role = 'employer'
      AND c.call_at >= r.created_at
      AND c.call_at < r.created_at + INTERVAL '7 days'
),
messages_prepared AS (
    SELECT
          m.response_id,
          m.employer_id,
          m.message_id AS event_id,
          m.sent_at AS event_at,
         'message' AS event_type
     FROM messages m
     JOIN responses r
       ON m.response_id = r.response_id
    WHERE m.response_id IS NOT NULL
      AND m.sender_role = 'employer'
      AND m.sent_at >= r.created_at
      AND m.sent_at < r.created_at + INTERVAL '7 days'
),
events_table AS (
    SELECT
          response_id,
          employer_id,
          event_id,
          event_at,
          event_type
     FROM calls_prepared
    UNION ALL
    SELECT
          response_id,
          employer_id,
          event_id,
          event_at,
          event_type
     FROM messages_prepared
),
events_with_windows AS (
    SELECT
        response_id,
        employer_id,
        event_id,
        event_at,
        event_type,
        ROW_NUMBER() OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS event_number,
        LAG(event_at) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS previous_event_at,
        LEAD(event_type) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS next_event_type,
        COUNT(*) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS communication_number,
        FIRST_VALUE(event_type) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS first_event_type,
        LAST_VALUE(event_type) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_event_type
    FROM events_table
),
responses_base AS (
    SELECT
         r.response_id,
         v.employer_id,
         v.professional_role,
         r.status,
         r.created_at
    FROM responses r
    JOIN vacancies v
      ON r.vacancy_id = v.vacancy_id
),
response_vitrine AS (
    SELECT
         r.response_id,
         r.employer_id,
         r.professional_role,
         r.status,
         COUNT(e.event_id) AS communication_count,
         COUNT(e.event_id) FILTER (WHERE e.event_type = 'call') AS call_count,
         COUNT(e.event_id) FILTER (WHERE e.event_type = 'message') AS message_count,
         MIN(e.event_at) AS first_communication_at,
         MIN(e.event_type) FILTER (WHERE e.event_number = 1) AS first_communication_type,
         MIN(e.event_type) FILTER (WHERE e.event_number = 2) AS second_communication_type,
         MAX(e.event_type) FILTER (WHERE e.event_number = (
         								SELECT MAX(e2.event_number)
                						  FROM events_with_windows e2
                						 WHERE e2.response_id = r.response_id
    													  )
    							  ) AS last_communication_type,
        EXTRACT(EPOCH FROM (MIN(e.event_at) - r.created_at)) / 3600 AS hours_to_first_communication,
        MAX(EXTRACT(EPOCH FROM (e.event_at - e.previous_event_at)) / 3600) AS max_gap_hours
	FROM responses_base r
    LEFT JOIN events_with_windows e
      ON r.response_id = e.response_id
   GROUP BY
         r.response_id,
         r.employer_id,
         r.professional_role,
         r.status,
         r.created_at
)
SELECT
    COUNT(*) AS response_total,
    COUNT(*) FILTER (WHERE communication_count > 0) AS responses_with_communication,
    COUNT(*) FILTER (WHERE communication_count = 0) AS responses_without_communication,
    COUNT(*) FILTER (WHERE first_communication_type = 'message') AS first_message,
    COUNT(*) FILTER (WHERE first_communication_type = 'call') AS first_call
FROM response_vitrine;
-- Вывод:
-- количество строк: 628
-- количество откликов с коммуникацией: 374
-- количество откликов без коммуникации: 254
-- количество откликов, где первой коммуникацией было сообщение: 324
-- количество откликов, где первой коммуникацией был звонок: 50

-- ============================================================
-- БЛОК В. Сравнение работодателей 
-- ============================================================

--ЗАДАНИЕ 4
WITH calls_prepared AS (
    SELECT
          c.response_id,
          c.employer_id,
          c.call_id AS event_id,
          c.call_at AS event_at,
         'call' AS event_type
     FROM calls c
     JOIN responses r
       ON r.response_id = c.response_id
    WHERE c.response_id IS NOT NULL
      AND c.status = 'successful'
      AND c.caller_role = 'employer'
      AND c.call_at >= r.created_at
      AND c.call_at < r.created_at + INTERVAL '7 days'
),
messages_prepared AS (
    SELECT
          m.response_id,
          m.employer_id,
          m.message_id AS event_id,
          m.sent_at AS event_at,
         'message' AS event_type
     FROM messages m
     JOIN responses r
       ON m.response_id = r.response_id
    WHERE m.response_id IS NOT NULL
      AND m.sender_role = 'employer'
      AND m.sent_at >= r.created_at
      AND m.sent_at < r.created_at + INTERVAL '7 days'
),
events_table AS (
    SELECT
          response_id,
          employer_id,
          event_id,
          event_at,
          event_type
     FROM calls_prepared
    UNION ALL
    SELECT
          response_id,
          employer_id,
          event_id,
          event_at,
          event_type
     FROM messages_prepared
),
events_with_windows AS (
    SELECT
        response_id,
        employer_id,
        event_id,
        event_at,
        event_type,
        ROW_NUMBER() OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS event_number,
        LAG(event_at) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS previous_event_at,
        LEAD(event_type) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS next_event_type,
        COUNT(*) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS communication_number,
        FIRST_VALUE(event_type) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS first_event_type,
        LAST_VALUE(event_type) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_event_type
    FROM events_table
),
responses_base AS (
    SELECT
         r.response_id,
         v.employer_id,
         v.professional_role,
         r.status,
         r.created_at
    FROM responses r
    JOIN vacancies v
      ON r.vacancy_id = v.vacancy_id
),
response_vitrine AS (
    SELECT
         r.response_id,
         r.employer_id,
         r.professional_role,
         r.status,
         COUNT(e.event_id) AS communication_count,
         COUNT(e.event_id) FILTER (WHERE e.event_type = 'call') AS call_count,
         COUNT(e.event_id) FILTER (WHERE e.event_type = 'message') AS message_count,
         MIN(e.event_at) AS first_communication_at,
         MIN(e.event_type) FILTER (WHERE e.event_number = 1) AS first_communication_type,
         MIN(e.event_type) FILTER (WHERE e.event_number = 2) AS second_communication_type,
         MAX(e.event_type) FILTER (WHERE e.event_number = (
         								SELECT MAX(e2.event_number)
                						  FROM events_with_windows e2
                						 WHERE e2.response_id = r.response_id
    													  )
    							  ) AS last_communication_type,
        EXTRACT(EPOCH FROM (MIN(e.event_at) - r.created_at)) / 3600 AS hours_to_first_communication,
        MAX(EXTRACT(EPOCH FROM (e.event_at - e.previous_event_at)) / 3600) AS max_gap_hours
	FROM responses_base r
    LEFT JOIN events_with_windows e
      ON r.response_id = e.response_id
   GROUP BY
         r.response_id,
         r.employer_id,
         r.professional_role,
         r.status,
         r.created_at
),
employer_stats AS (
    SELECT
        professional_role,
        employer_id,
        COUNT(*) AS response_count,
        COUNT(*) FILTER (
            WHERE communication_count > 0
        ) AS responses_with_communication,
        COUNT(*) FILTER (
            WHERE communication_count > 0
        ) * 100.0 / COUNT(*) AS communication_rate,
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY hours_to_first_communication
        ) AS median_hours_to_first,
        PERCENTILE_CONT(0.9) WITHIN GROUP (
            ORDER BY hours_to_first_communication
        ) AS p90_hours_to_first,
        COUNT(*) FILTER (
            WHERE status = 'invited'
        ) * 100.0 / COUNT(*) AS invitation_conversion
    FROM response_vitrine
    GROUP BY
        professional_role,
        employer_id
    HAVING COUNT(*) >= 8
),
employer_ranking AS (
    SELECT
        professional_role,
        employer_id,
        response_count,
        responses_with_communication,
        communication_rate,
        median_hours_to_first,
        p90_hours_to_first,
        invitation_conversion,
        DENSE_RANK() OVER (
            PARTITION BY professional_role
            ORDER BY
                communication_rate DESC,
                median_hours_to_first ASC
        ) AS place
    FROM employer_stats
)
SELECT
    professional_role,
    place,
    employer_id,
    response_count,
    responses_with_communication,
    ROUND(communication_rate::numeric,1) AS communication_rate,
    ROUND(median_hours_to_first::numeric,1) AS median_hours_to_first,
    ROUND(p90_hours_to_first::numeric,1) AS p90_hours_to_first,
    ROUND(invitation_conversion::numeric,1) AS invitation_conversion
FROM employer_ranking
WHERE place <= 2
ORDER BY
    professional_role,
    place,
    employer_id;
-- Вывод:
-- Аналитик данных	1	109
-- Аналитик данных	2	103
-- Дата-инженер	1	106
-- Дата-инженер	2	101
-- Продуктовый аналитик	1	103
-- Продуктовый аналитик	2	102
-- Разработчик	1	112
-- Разработчик	2	104
-- Тестировщик	1	107
-- Тестировщик	2	108

--ЗАДАНИЕ 5
WITH messages_prepared AS (
    SELECT
           m.message_id,
           m.response_id,
           m.employer_id,
           m.sent_at,
           m.sender_role
      FROM messages m
      JOIN responses r
        ON m.response_id = r.response_id
     WHERE m.response_id IS NOT NULL
       AND m.sent_at >= r.created_at
       AND m.sent_at < r.created_at + INTERVAL '7 days'
),
messages_with_previous AS (
    SELECT
        message_id,
        response_id,
        employer_id,
        sent_at,
        sender_role,
        LAG(sender_role) OVER (
            PARTITION BY response_id
            ORDER BY sent_at, message_id
        ) AS previous_sender_role,
        LAG(sent_at) OVER (
            PARTITION BY response_id
            ORDER BY sent_at, message_id
        ) AS previous_sent_at
    FROM messages_prepared
),
employer_replies AS (
    SELECT
          response_id,
          employer_id,
          message_id,
          sent_at,
          previous_sent_at,
          EXTRACT(EPOCH FROM (sent_at - previous_sent_at)) / 3600 AS response_time_hours
     FROM messages_with_previous
    WHERE sender_role = 'employer'
      AND previous_sender_role = 'applicant'
)
SELECT
    employer_id,
    COUNT(*) AS measured_responses,
    AVG(response_time_hours) AS avg_response_time_hours,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY response_time_hours
    ) AS median_response_time_hours,
    PERCENTILE_CONT(0.9) WITHIN GROUP (
        ORDER BY response_time_hours
    ) AS p90_response_time_hours
 FROM employer_replies
GROUP BY employer_id
ORDER BY median_response_time_hours;
-- Вывод:
-- 107 3.9333333333333336
-- ============================================================
-- БЛОК Г. Сложные типы данных
-- ============================================================
--ЗАДАНИЕ 6
-- Теги звонков
WITH calls_prepared AS (
    SELECT
          c.call_id,
          c.response_id,
          c.employer_id,
          c.status,
          c.call_tags,
          c.call_at
     FROM calls c
     JOIN responses r
       ON r.response_id = c.response_id
    WHERE c.response_id IS NOT NULL
      AND c.caller_role = 'employer'
      AND c.call_at >= r.created_at
      AND c.call_at < r.created_at + INTERVAL '7 days'
),
valid_calls AS (
    SELECT *
    FROM calls_prepared
    WHERE
            (status = 'successful'
       AND 'connected' = ANY(call_tags))
        OR (status = 'unsuccessful' AND 'no_answer' = ANY(call_tags))
        OR (status = 'error' AND 'technical_error' = ANY(call_tags))
)
SELECT
    COUNT(*) FILTER (WHERE 'screening' = ANY(call_tags)) AS screening_count,
    COUNT(*) FILTER (WHERE 'interview' = ANY(call_tags)) AS interview_count,
    COUNT(*) FILTER (WHERE 'follow_up' = ANY(call_tags)) AS follow_up_count,
    COUNT(*) FILTER (WHERE 'details' = ANY(call_tags)) AS details_count,
    COUNT(*) FILTER (WHERE call_tags && ARRAY[
            'screening',
            'interview',
            'follow_up',
            'details'
        ]
    ) AS calls_with_business_tag,
    AVG(
        COALESCE(cardinality(call_tags), 0)
    ) AS avg_tags_per_call
FROM valid_calls;

-- screening - 25
-- interview - 31
-- follow_up - 29
-- details - 23
-- количество валидных звонков, содержащих хотя бы один из перечисленных бизнес-тегов - 108
-- среднее количество тегов на один валидный звонок - 4

-- Метаданные сообщений
WITH messages_prepared AS (
    SELECT
           m.message_id,
           m.response_id,
           m.employer_id,
           m.sent_at,
           m.message_meta
      FROM messages m
      JOIN responses r
        ON r.response_id = m.response_id
     WHERE m.response_id IS NOT NULL
       AND m.sender_role = 'employer'
       AND m.sent_at >= r.created_at
       AND m.sent_at < r.created_at + INTERVAL '7 days'
),
messages_meta_prepared AS (
    SELECT
        message_id,
        response_id,
        employer_id,
        message_meta ->> 'channel' AS channel,
        (message_meta ->> 'is_read')::boolean AS is_read,
        jsonb_array_length(
            message_meta -> 'attachments'
        ) AS attachments_count
    FROM messages_prepared
)
SELECT
    COALESCE(channel, 'unknown') AS channel,
    COUNT(*) AS message_count,
    COUNT(*) FILTER (WHERE is_read IS NOT NULL) AS read_count,
    COUNT(*) FILTER (WHERE is_read = false) AS unread_count,
    COUNT(*) FILTER (WHERE is_read = false) * 100.0/ NULLIF(COUNT(*) FILTER (WHERE is_read IS NOT NULL),0) AS unread_share,
    COUNT(*) FILTER (
        WHERE attachments_count > 0
    ) AS messages_with_attachments,
    COUNT(*) FILTER (
        WHERE attachments_count > 0
    ) * 100.0 / COUNT(*) AS attachment_share
FROM messages_meta_prepared
GROUP BY
    COALESCE(channel, 'unknown')
ORDER BY channel;
-- Вывод:

-- ============================================================
-- БЛОК Д. Самостоятельное исследование 
-- ============================================================
--ЗАДАНИЕ 7
-- Гипотеза про интенсивность:
-- Отклики с приглашением в среднем получают больше коммуникаций работодателя в первые 7 дней, чем отклики без приглашения.

-- Гипотеза про скорость:
-- По откликам, закончившимся приглашением, первая коммуникация работодателя происходит быстрее, чем по откликам без приглашения.
WITH calls_prepared AS (
    SELECT
          c.response_id,
          c.employer_id,
          c.call_id AS event_id,
          c.call_at AS event_at,
         'call' AS event_type
     FROM calls c
     JOIN responses r
       ON r.response_id = c.response_id
    WHERE c.response_id IS NOT NULL
      AND c.status = 'successful'
      AND c.caller_role = 'employer'
      AND c.call_at >= r.created_at
      AND c.call_at < r.created_at + INTERVAL '7 days'
),
messages_prepared AS (
    SELECT
          m.response_id,
          m.employer_id,
          m.message_id AS event_id,
          m.sent_at AS event_at,
         'message' AS event_type
     FROM messages m
     JOIN responses r
       ON m.response_id = r.response_id
    WHERE m.response_id IS NOT NULL
      AND m.sender_role = 'employer'
      AND m.sent_at >= r.created_at
      AND m.sent_at < r.created_at + INTERVAL '7 days'
),
events_table AS (
    SELECT
          response_id,
          employer_id,
          event_id,
          event_at,
          event_type
     FROM calls_prepared
    UNION ALL
    SELECT
          response_id,
          employer_id,
          event_id,
          event_at,
          event_type
     FROM messages_prepared
),
events_with_windows AS (
    SELECT
        response_id,
        employer_id,
        event_id,
        event_at,
        event_type,
        ROW_NUMBER() OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS event_number,
        LAG(event_at) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS previous_event_at,
        LEAD(event_type) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS next_event_type,
        COUNT(*) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS communication_number,
        FIRST_VALUE(event_type) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
        ) AS first_event_type,
        LAST_VALUE(event_type) OVER (
            PARTITION BY response_id
            ORDER BY event_at, event_type, event_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_event_type
    FROM events_table
),
responses_base AS (
    SELECT
         r.response_id,
         v.employer_id,
         v.professional_role,
         r.status,
         r.created_at
    FROM responses r
    JOIN vacancies v
      ON r.vacancy_id = v.vacancy_id
),
response_vitrine AS (
    SELECT
         r.response_id,
         r.employer_id,
         r.professional_role,
         r.status,
         COUNT(e.event_id) AS communication_count,
         COUNT(e.event_id) FILTER (WHERE e.event_type = 'call') AS call_count,
         COUNT(e.event_id) FILTER (WHERE e.event_type = 'message') AS message_count,
         MIN(e.event_at) AS first_communication_at,
         MIN(e.event_type) FILTER (WHERE e.event_number = 1) AS first_communication_type,
         MIN(e.event_type) FILTER (WHERE e.event_number = 2) AS second_communication_type,
         MAX(e.event_type) FILTER (WHERE e.event_number = (
         								SELECT MAX(e2.event_number)
                						  FROM events_with_windows e2
                						 WHERE e2.response_id = r.response_id
    													  )
    							  ) AS last_communication_type,
        EXTRACT(EPOCH FROM (MIN(e.event_at) - r.created_at)) / 3600 AS hours_to_first_communication,
        MAX(EXTRACT(EPOCH FROM (e.event_at - e.previous_event_at)) / 3600) AS max_gap_hours
	FROM responses_base r
    LEFT JOIN events_with_windows e
      ON r.response_id = e.response_id
   GROUP BY
         r.response_id,
         r.employer_id,
         r.professional_role,
         r.status,
         r.created_at
),
response_groups AS (
    SELECT
           response_id,
           status,
      CASE
            WHEN status = 'invited' THEN 'invited'
            ELSE 'not_invited'
        END AS invitation_group,
            communication_count,
            hours_to_first_communication
    FROM response_vitrine
),
group_stats AS (
    SELECT
           invitation_group,
           COUNT(*) AS response_count,
           COUNT(*) FILTER (WHERE communication_count > 0) * 100.0 / COUNT(*) AS communication_share,
           AVG(communication_count) AS avg_communications,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY hours_to_first_communication) AS median_hours_to_first,
           COUNT(*) FILTER (WHERE hours_to_first_communication <= 24) * 100.0 / COUNT(*) AS communication_within_24h_share
      FROM response_groups
     GROUP BY invitation_group
)
SELECT *
  FROM group_stats
 ORDER BY invitation_group;
-- Вывод:
-- Гипотеза 1: не подтверждается.
-- Анализ показал, что доля откликов с коммуникацией у группы invited составляет 57.6% (при средней интенсивности 1.60 сообщения/звонка), 
-- что практически не отличается от группы not_invited — 59.9% и 1.71 коммуникации. 
-- Работодатели тратят одинаковый объем усилий на первичное взаимодействие независимо от финального приглашения.
-- Гипотеза 2: не подтверждается.
-- Медианное время до первой коммуникации у приглашенных кандидатов составило 52.5 часа, 
-- а у остальных 54.7 часа. Разница в 2 часа статистически незначима, 
-- что опровергает предположение о том, что работодатели спешат отвечать только тем, кому планируют дать оффер.

--ЗАДАНИЕ 8

-- Вывод:
-- В рамках исследования коммуникаций после отклика была проанализирована активность работодателей за первые 7 дней.
-- Аудит качества данных выявил 8 звонков без связи с откликом и зафиксировал среднюю длительность успешного звонка на уровне 467.3 секунды.
-- Построение единого слоя и витрины показало, что из 628 откликов коммуникация велась по 374 (всего 1066 событий, из которых 988 — сообщения), причем в 324 случаях первой коммуникацией выступало сообщение.
-- Сравнение работодателей внутри профессиональных направлений выявило, что лидеры обрабатывают более 80% откликов со средним временем ответа менее суток.
-- Самостоятельное исследование показало, что интенсивность (1.60 против 1.71 коммуникаций) и медианное время ответа (52.5 против 54.7 часов) практически идентичны для групп invited и not_invited.
-- Это свидетельствует о том, что само наличие или скорость первичного контакта не предопределяют успех кандидата, так как работодатели ведут стандартный диалог-скрининг со всеми релевантными откликами.
-- Главным ограничением проведенного анализа является отсутствие контент-анализа текстовой составляющей сообщений и качества резюме кандидатов.
-- В качестве следующего исследовательского вопроса рекомендуется изучить, влияет ли наличие тегов звонков (например, interview или screening) на финальную конверсию в найм.
