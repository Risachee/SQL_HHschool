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
-- ДОРАБОТКА
-- Проверка событий после окончания 7-дневного окна
SELECT
       COUNT(*) AS problem_count,
       STRING_AGG(c.call_id::TEXT, ', ' ORDER BY c.call_id) AS problem_ids
  FROM calls c
  JOIN responses r
    ON c.response_id = r.response_id
 WHERE c.call_at >= r.created_at + INTERVAL '7 days';

SELECT
       COUNT(*) AS problem_count,
       STRING_AGG(m.message_id::TEXT, ', ' ORDER BY m.message_id) AS problem_ids
  FROM messages m
  JOIN responses r
    ON m.response_id = r.response_id
 WHERE m.sent_at >= r.created_at + INTERVAL '7 days';

-- События после 7 дней не являются ошибкой исходных данных: они просто не должны
-- попадать в метрики, которые по условию считаются только в первые 7 дней после отклика.
-- События после окончания 7-дневного окна:
-- звонков: 75, call_id: 700003, 700006, 700016, 700017, 700020, 700025, 700027, 700035, 700037, 700038, 700040, 700044, 700047, 700050, 700058, 700060, 700064, 
-- 700066, 700068, 700069, 700075, 700076, 700077, 700079, 700088, 700091, 700096, 700097, 700099, 700104, 700107, 700111, 700114, 700117, 700121, 700122, 700123, 
-- 700127, 700129, 700130, 700133, 700134, 700137, 700145, 700148, 700150, 700154, 700159, 700160, 700168, 700175, 700180, 700181, 700187, 700189, 700190, 700193, 
-- 700198, 700203, 700204, 700210, 700216, 700217, 700218, 700222, 700224, 700228, 700229, 700230, 700235, 700236, 700237, 700238, 700240, 700241
-- сообщений: 886, message_id:800017, 800018, 800031, 800032, 800033, 800034, 800035, 800036, 800073, 800074, 800075, 800076, 800077, 800078, 800079, 
-- 800080, 800081, 800082, 800083, 800084, 800103, 800104, 800105, 800106, 800107, 800108, 800121, 800122, 800123, 800124, 800125, 800126, 800139, 
-- 800140, 800141, 800142, 800143, 800144, 800155, 800156, 800175, 800176, 800177, 800178, 800179, 800180, 800187, 800188, 800189, 800190, 800191, 
-- 800192, 800205, 800206, 800207, 800208, 800209, 800210, 800221, 800222, 800223, 800224, 800225, 800226, 800227, 800228, 800235, 800236, 800237, 
-- 800238, 800239, 800240, 800253, 800254, 800255, 800256, 800257, 800258, 800265, 800266, 800267, 800268, 800269, 800270, 800307, 800308, 800309, 
-- 800310, 800311, 800312, 800325, 800326, 800327, 800328, 800329, 800330, 800371, 800372, 800379, 800380, 800381, 800382, 800383, 800384, 800385, 
-- 800386, 800387, 800388, 800389, 800390, 800403, 800404, 800405, 800406, 800407, 800408, 800409, 800410, 800411, 800412, 800413, 800414, 800415, 
-- 800416, 800417, 800418, 800419, 800420, 800421, 800422, 800423, 800424, 800425, 800426, 800439, 800440, 800441, 800442, 800443, 800444, 800445, 
-- 800446, 800447, 800448, 800449, 800450, 800451, 800452, 800453, 800454, 800455, 800456, 800473, 800474, 800487, 800488, 800489, 800490, 800491, 
-- 800492, 800499, 800500, 800501, 800502, 800503, 800504, 800521, 800522, 800529, 800530, 800531, 800532, 800533, 800534, 800583, 800584, 800585, 
-- 800586, 800587, 800588, 800601, 800602, 800603, 800604, 800605, 800606, 800613, 800614, 800615, 800616, 800617, 800618, 800619, 800620, 800621, 
-- 800622, 800623, 800624, 800625, 800626, 800627, 800628, 800629, 800630, 800635, 800636, 800671, 800672, 800697, 800698, 800699, 800700, 800701, 
-- 800702, 800713, 800714, 800731, 800732, 800739, 800740, 800741, 800742, 800743, 800744, 800749, 800750, 800755, 800756, 800767, 800768, 800787, 
-- 800788, 800789, 800790, 800791, 800792, 800799, 800800, 800801, 800802, 800803, 800804, 800877, 800878, 800879, 800880, 800881, 800882, 800895, 
-- 800896, 800897, 800898, 800899, 800900, 800901, 800902, 800903, 800904, 800905, 800906, 800923, 800924, 800953, 800954, 800959, 800960, 801001, 
-- 801002, 801003, 801004, 801005, 801006, 801007, 801008, 801013, 801014, 801021, 801022, 801023, 801024, 801025, 801026, 801039, 801040, 801041, 
-- 801042, 801043, 801044, 801051, 801052, 801053, 801054, 801055, 801056, 801057, 801058, 801059, 801060, 801061, 801062, 801069, 801070, 801071, 
-- 801072, 801073, 801074, 801075, 801076, 801077, 801078, 801079, 801080, 801093, 801094, 801095, 801096, 801097, 801098, 801129, 801130, 801131, 
-- 801132, 801133, 801134, 801141, 801142, 801143, 801144, 801145, 801146, 801165, 801166, 801167, 801168, 801169, 801170, 801189, 801190, 801191, 
-- 801192, 801193, 801194, 801217, 801218, 801225, 801226, 801227, 801228, 801229, 801230, 801231, 801232, 801233, 801234, 801235, 801236, 801261, 
-- 801262, 801263, 801264, 801265, 801266, 801267, 801268, 801269, 801270, 801271, 801272, 801273, 801274, 801275, 801276, 801277, 801278, 801285, 
-- 801286, 801287, 801288, 801289, 801290, 801319, 801320, 801325, 801326, 801331, 801332, 801333, 801334, 801335, 801336, 801337, 801338, 801351, 
-- 801352, 801353, 801354, 801355, 801356, 801357, 801358, 801359, 801360, 801361, 801362, 801373, 801374, 801375, 801376, 801377, 801378, 801379, 
-- 801380, 801381, 801382, 801383, 801384, 801385, 801386, 801417, 801418, 801419, 801420, 801421, 801422, 801429, 801430, 801431, 801432, 801433, 
-- 801434, 801435, 801436, 801437, 801438, 801439, 801440, 801477, 801478, 801479, 801480, 801481, 801482, 801487, 801488, 801489, 801490, 801491, 
-- 801492, 801493, 801494, 801495, 801496, 801497, 801498, 801499, 801500, 801507, 801508, 801509, 801510, 801511, 801512, 801517, 801518, 801531, 
-- 801532, 801533, 801534, 801535, 801536, 801573, 801574, 801575, 801576, 801577, 801578, 801579, 801580, 801581, 801582, 801583, 801584, 801597, 
-- 801598, 801599, 801600, 801601, 801602, 801603, 801604, 801605, 801606, 801607, 801608, 801609, 801610, 801611, 801612, 801613, 801614, 801621, 
-- 801622, 801623, 801624, 801625, 801626, 801639, 801640, 801641, 801642, 801643, 801644, 801673, 801674, 801685, 801686, 801687, 801688, 801689, 
-- 801690, 801691, 801692, 801717, 801718, 801719, 801720, 801721, 801722, 801741, 801742, 801743, 801744, 801745, 801746, 801753, 801754, 801755, 
-- 801756, 801757, 801758, 801763, 801764, 801783, 801784, 801785, 801786, 801787, 801788, 801789, 801790, 801791, 801792, 801793, 801794, 801799, 
-- 801800, 801805, 801806, 801825, 801826, 801827, 801828, 801829, 801830, 801831, 801832, 801833, 801834, 801835, 801836, 801879, 801880, 801881, 
-- 801882, 801883, 801884, 801897, 801898, 801899, 801900, 801901, 801902, 801903, 801904, 801905, 801906, 801907, 801908, 801913, 801914, 801919, 
-- 801920, 801925, 801926, 801933, 801934, 801935, 801936, 801937, 801938, 801951, 801952, 801953, 801954, 801955, 801956, 801969, 801970, 801971, 
-- 801972, 801973, 801974, 801975, 801976, 801977, 801978, 801979, 801980, 801985, 801986, 802011, 802012, 802013, 802014, 802015, 802016, 802027, 
-- 802028, 802057, 802058, 802059, 802060, 802061, 802062, 802063, 802064, 802065, 802066, 802067, 802068, 802069, 802070, 802071, 802072, 802073, 
-- 802074, 802075, 802076, 802095, 802096, 802097, 802098, 802099, 802100, 802107, 802108, 802109, 802110, 802111, 802112, 802113, 802114, 802115, 
-- 802116, 802117, 802118, 802125, 802126, 802127, 802128, 802129, 802130, 802137, 802138, 802139, 802140, 802141, 802142, 802143, 802144, 802145, 
-- 802146, 802147, 802148, 802149, 802150, 802151, 802152, 802153, 802154, 802177, 802178, 802191, 802192, 802193, 802194, 802195, 802196, 802215, 
-- 802216, 802217, 802218, 802219, 802220, 802243, 802244, 802275, 802276, 802277, 802278, 802279, 802280, 802287, 802288, 802289, 802290, 802291, 
-- 802292, 802329, 802330, 802331, 802332, 802333, 802334, 802335, 802336, 802337, 802338, 802339, 802340, 802371, 802372, 802373, 802374, 802375, 
--802376, 802381, 802382, 802383, 802384, 802385, 802386, 802387, 802388, 802407, 802408, 802409, 802410, 802411, 802412, 802431, 802432, 802433, 
-- 802434, 802435, 802436, 802459, 802460, 802473, 802474, 802475, 802476, 802477, 802478, 802485, 802486, 802487, 802488, 802489, 802490, 802507, 
-- 802508, 802551, 802552, 802553, 802554, 802555, 802556, 802557, 802558, 802559, 802560, 802561, 802562, 802581, 802582, 802583, 802584, 802585, 
-- 802586, 802627, 802628, 802647, 802648, 802649, 802650, 802651, 802652, 802659, 802660, 802661, 802662, 802663, 802664, 802671, 802672, 802673, 
-- 802674, 802675, 802676, 802681, 802682, 802689, 802690, 802691, 802692, 802693, 802694, 802695, 802696, 802697, 802698, 802699, 802700, 802701, 
-- 802702, 802703, 802704, 802705, 802706, 802707, 802708, 802709, 802710, 802711, 802712, 802749, 802750, 802751, 802752, 802753, 802754, 802771, 
-- 802772, 802779, 802780, 802781, 802782, 802783, 802784, 802785, 802786, 802787, 802788, 802789, 802790, 802815, 802816, 802817, 802818, 802819, 
--802820, 802827, 802828, 802829, 802830, 802831, 802832, 802845, 802846, 802847, 802848, 802849, 802850, 802851, 802852, 802853, 802854, 802855, 
-- 802856, 802857, 802858, 802859, 802860, 802861, 802862
-- Это не ошибка исходных данных, но такие события исключаются из аналитического слоя,
-- поскольку условие ограничивает анализ первыми 7 днями после отклика.


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
-- максимальная обнаруженная длительность составляет 899 сек, это 14.9 мин.
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

-- ДОРАБОТКА

-- Вывод:
-- В аналитический слой включаю только успешные звонки работодателя: считаю их состоявшимся
-- контактом. Неуспешные и ошибочные звонки не считаю коммуникацией, поскольку по ним факт
-- состоявшегося контакта не подтверждён.
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
    ROUND(AVG(response_time_hours)::numeric, 2) AS avg_response_time_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY response_time_hours
    )::numeric, 2) AS median_response_time_hours,
    ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (
        ORDER BY response_time_hours
    )::numeric, 2) AS p90_response_time_hours
 FROM employer_replies
GROUP BY employer_id
ORDER BY median_response_time_hours;

-- ДОРАБОТКА
-- Вывод:
-- Всего найдено ответов работодателя после сообщения кандидата: 699.
-- Работодатель с минимальной медианой времени ответа: employer_id 107.
-- Медиана времени ответа employer_id 107: 3.93 часа.
-- Контрольные значения по работодателям (employer_id / количество ответов / среднее / медиана / P90):
-- 107 / 28 / 9.37 / 3.93 / 19.90
-- 108 / 8 / 6.38 / 4.12 / 13.36
-- 110 / 59 / 7.51 / 4.13 / 19.09
-- 109 / 35 / 6.93 / 4.42 / 17.88
-- 106 / 48 / 7.08 / 4.45 / 18.90
-- 104 / 85 / 7.39 / 4.58 / 18.98
-- 103 / 171 / 7.92 / 4.58 / 19.62
-- 105 / 6 / 6.15 / 4.58 / 12.95
-- 112 / 43 / 8.58 / 4.65 / 19.30
-- 101 / 161 / 7.43 / 4.67 / 18.68
-- 102 / 105 / 9.19 / 4.93 / 20.21
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
    ROUND(
        (COUNT(*) FILTER (WHERE is_read = false) * 100.0
        / NULLIF(COUNT(*) FILTER (WHERE is_read IS NOT NULL), 0))::numeric,
        2
    ) AS unread_share,
    COUNT(*) FILTER (
        WHERE attachments_count > 0
    ) AS messages_with_attachments,
    ROUND(
        (COUNT(*) FILTER (WHERE attachments_count > 0) * 100.0 / COUNT(*))::numeric,
        2
    ) AS attachment_share
FROM messages_meta_prepared
GROUP BY
    COALESCE(channel, 'unknown')
ORDER BY channel;
-- ДОРАБОТКА
-- Вывод:
-- mobile_app: 360 сообщений; 360 с известным признаком прочтения; 36 непрочитанных;
-- доля непрочитанных 10.00%; 14 сообщений с вложениями; доля сообщений с вложениями 3.89%.
-- web: 628 сообщений; 628 с известным признаком прочтения; 52 непрочитанных;
-- доля непрочитанных 8.28%; 25 сообщений с вложениями; доля сообщений с вложениями 3.98%.
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
--ДОРАБОТКА
-- Вывод:
-- Гипотеза 1: не подтверждается.
-- Доля откликов с коммуникацией у группы invited составляет 57.6%, среднее число коммуникаций — 1.60.
-- Для группы not_invited эти значения составляют 59.9% и 1.71 соответственно.
-- Разница небольшая, поэтому данные не подтверждают гипотезу о большей интенсивности коммуникации
-- по откликам, закончившимся приглашением.
-- Гипотеза 2: не подтверждается.
-- Медианное время до первой коммуникации у приглашенных кандидатов составило 52.5 часа,
-- а у остальных — 54.7 часа. Разница составляет около 2.2 часа и также небольшая,
-- поэтому данные не подтверждают гипотезу о более быстром первом контакте для группы invited.

--ЗАДАНИЕ 8

-- ДОРАБОТКА
-- Вывод:
-- В первые 7 дней после отклика работодатели совершили 1 066 коммуникаций по 374 из 628 откликов (59,6%): 988 сообщений и 78 успешных звонков, причём в 324 случаях первым контактом было сообщение и только в 50 — звонок (задания 2–3). Это указывает на преобладание переписки, однако по 254 откликам в рамках принятого определения контакта коммуникации не зафиксированы, что может быть важным направлением для улучшения процесса обратной связи. 
-- Сравнение по профессиональным направлениям выявило различия между работодателями: например, доля откликов с коммуникацией у работодателя 107 в направлении «Тестировщик» составила 88,2%, а у работодателя 106 в направлении «Дата-инженер» — 70,0% (задание 4). Работодатель 107 также показал минимальную медиану времени ответа на сообщения кандидатов — 3,93 часа по 28 измеренным ответам, хотя 90-й перцентиль составил 19,90 часа, что указывает на заметные различия во времени ожидания ответа. 
-- По метаданным сообщений доля непрочитанных составила 10,00% в `mobile_app` и 8,28% в `web`, тогда как доля сообщений с вложениями была практически одинаковой — 3,89% и 3,98% соответственно. Проверка гипотез не выявила более интенсивной коммуникации по откликам с приглашением: среднее число контактов составило 1,60 против 1,71 у остальных, а медианное время до первой коммуникации — 52,5 против 54,7 часа. 
-- Таким образом, в исследованной выборке не обнаружено подтверждения предположению, что приглашение сопровождается большим количеством коммуникаций или более ранним первым контактом, но эти результаты сами по себе не доказывают отсутствия связи между коммуникацией и приглашением. 
-- Важное ограничение анализа — он охватывает только выбранные типы контактов в первые 7 дней и не учитывает содержание сообщений, качество резюме и характеристики вакансий, которые могут влиять на поведение работодателя. Следующий шаг — проверить, как тип и последовательность коммуникаций, время первого ответа, профессиональное направление и характеристики вакансии связаны с вероятностью приглашения, а для этого дополнить данные содержанием сообщений и более подробной информацией о кандидатах и вакансиях.