# Анализ бизнес-показателей 
Код проекта:


<kbd> <br> [Jupyter notebook on GitHub](https://github.com/SiriusSergio/portfolio/blob/eb185368273815c6cb9d04894634479a59d25ee6/Marketing%20Analysis/Marketing%20Analysis.ipynb) <br> </kbd>  <kbd> <br> [NBviewer](https://nbviewer.org/github/SiriusSergio/portfolio/blob/eb185368273815c6cb9d04894634479a59d25ee6/Marketing%20Analysis/Marketing%20Analysis.ipynb#plan) <br> </kbd>
# Описание проекта

**Проблема и актуальность**

Заказчик - развлекательное приложение Procrastinate Pro+. Несмотря на огромные вложения в рекламу, последние несколько месяцев компания терпит убытки. 

**Цель**

Разобраться в причинах убытков и помочь компании выйти в плюс.

**Задачи**

+ откуда приходят пользователи и какими устройствами они пользуются,
+ сколько стоит привлечение пользователей из различных рекламных каналов;
+ сколько денег приносит каждый клиент,
+ когда расходы на привлечение клиента окупаются,
+ какие факторы мешают привлечению клиентов.


# Выводы
Выводы по пользователям:
* Чаще всего платящие пользователи пользуются техникой Apple, но эти пользователи не окупаются. 
* Удержание платящих пользователей падает с середины года 
* Самая низкая конверсия у пользователей PC, однако удержание самое высокое 
* Пользователи из США конвертируются лучше всех, но удерживаются хуже всех 

Выводы по рекламным каналам:
* Общая сумма расходов на маркетинг составила  💲105,497

* На данный момент компания платит по  💲2,7 за клиента в источнике TipTop с конверсией в 9,6%
* А канал FaceBoom приносит клиента за  💲1,1 при конверсии в 12,1%
* Эти два источника являются приоритетными у компании, на них выделяется более 80% маркетингового бюджета. И расходы постепенно растут с каждым месяцем
* AdNonSence, LabmdaMediaAds, FaceBoom, TipTop - это топовые каналы по конверсии
* Однако, AdNonSence и FaceBoom показывают ужасное удержание - почти на нуле
* Стоимость привелечения по каналу TipTop стабильно и резко растет
* Три канала убыточны: TipTop, FaceBoom, AdNonSence. По остальным каналам возврат на инвестиции выше уровня окупаемости.

Таким образом, три канала из четырех топовых приносят убытки для компании. Единственный канал, который окупается - это **LabmdaMediaAds**. 

Общие выводы
* Реклама не окупается. ROI для 14 дня почти пересекает линию окупаемости, но так до нее и не доходит
* LTV пользователей стабильно растет, значит качество пользователей - это не причина неокупаемости рекламы
* CAC резко растет, рекламный бюджет регулярно увеличивают.

**Рекомендации:**
* Диверсифицировать рекламные каналы
* Источник lambdaMediaAds приносит клиента в среднем по 💲0,7. Конверсия составляет 10,5%. Источник окупается.  Это потенциально эффективный источник для рекламы. 
* **Стоит обратить внимание на канал FaceBoom: калал приводит пользователя за 💲1,1 с конверсией в 12%. Однако удержание пользователей с этого канала очень низкое. Стоит обратить внимание на этот фактор и попробовать улучшить показатель** 
