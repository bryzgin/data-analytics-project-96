select
    visitor_id,
    date_trunc('day', visit_date) as visit_date,
    case source
        when 'Yandex' then 'Переходы из поисковых систем'
        when 'admitad' then 'Партнерские программы'
        when 'baidu.com' then 'Переходы из поисковых систем'
        when 'bing.com' then 'Переходы из поисковых систем'
        when 'botmother' then 'Переходы из социальных сетей'
        when 'dzen' then 'Переходы из социальных сетей'
        when 'facebook' then 'Переходы из социальных сетей'
        when 'facebook.com' then 'Переходы из социальных сетей'
        when 'go.mail.ru' then 'Переходы из поисковых систем'
        when 'google' then 'Переходы из поисковых систем'
        when 'instagram' then 'Переходы из социальных сетей'
        when 'mytarget' then 'Переходы по рекламе'
        when 'organic' then 'Прямые заходы'
        when 'partners' then 'Партнерские программы'
        when 'podcast' then 'Переходы по ссылкам на сайтах'
        when 'public' then 'Переходы из поисковых систем'
        when 'rutube' then 'Переходы по ссылкам на сайтах'
        when 'search.ukr.net' then 'Переходы по ссылкам на сайтах'
        when 'slack' then 'Переходы из социальных сетей'
        when 'social' then 'Переходы из социальных сетей'
        when 'telegram' then 'Переходы из социальных сетей'
        when 'telegram Этот курс побеждён! 💪💪💪 Было круто! 🚀'
            then 'Переходы из социальных сетей'
        when 'telegram.me' then 'Переходы из социальных сетей'
        when 'tg' then 'Переходы из социальных сетей'
        when 'timepad' then 'Переходы по ссылкам на сайтах'
        when 'tproger' then 'Переходы по ссылкам на сайтах'
        when 'twitter' then 'Переходы из социальных сетей'
        when 'twitter.com' then 'Переходы из социальных сетей'
        when 'vc' then 'Переходы по ссылкам на сайтах'
        when 'vk' then 'Переходы из социальных сетей'
        when 'vk-group' then 'Переходы из социальных сетей'
        when 'vk-senler' then 'Переходы из социальных сетей'
        when 'vk.com' then 'Переходы из социальных сетей'
        when 'vkontakte' then 'Переходы из социальных сетей'
        when 'yandex' then 'Переходы из поисковых систем'
        when 'yandex-direct' then 'Переходы по рекламе'
        when 'yandex.com' then 'Переходы из поисковых систем'
        when 'zen' then 'Переходы из социальных сетей'
        when 'zen_from_telegram' then 'Переходы из социальных сетей'
    end as source
from sessions;

with ads as (
    select
        to_char(vk.campaign_date, 'DD-MM-YYYY') as campaign_date,
        vk.utm_source,
        vk.utm_medium,
        vk.utm_campaign,
        sum(vk.daily_spent) as total_cost
    from vk_ads as vk
    group by
        to_char(vk.campaign_date, 'DD-MM-YYYY'),
        vk.utm_source,
        vk.utm_medium,
        vk.utm_campaign
    union
    select
        to_char(ya.campaign_date, 'DD-MM-YYYY') as campaign_date,
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign,
        sum(ya.daily_spent) as total_cost
    from ya_ads as ya
    group by
        to_char(ya.campaign_date, 'DD-MM-YYYY'),
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign
)

select
    utm_source,
    campaign_date,
    sum(total_cost) as total_cost
from ads
group by
    campaign_date,
    utm_source
order by
    utm_source,
    campaign_date;

with query as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        row_number()
            over (
                partition by s.visitor_id
                order by s.visit_date desc
            )
        as visit_rank
    from sessions as s
    where s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

lpc as (
    select
        q.visitor_id,
        q.utm_source,
        q.utm_medium,
        q.utm_campaign,
        l.lead_id,
        l.amount,
        l.closing_reason,
        l.status_id,
        to_char(q.visit_date, 'DD-MM-YYYY') as visit_date,
        to_char(l.created_at, 'DD-MM-YYYY') as created_at
    from query as q
    left join leads as l
        on
            q.visitor_id = l.visitor_id
            and q.visit_date <= l.created_at
    where q.visit_rank = 1
    order by
        l.amount desc nulls last,
        q.visit_date asc,
        q.utm_source asc,
        q.utm_medium asc,
        q.utm_campaign asc
),

click_to_lead as (
    select
        cast(count(distinct visitor_id) as numeric) as visits_count,
        cast(count(distinct lead_id) as numeric) as leads_count
    from lpc
)

select
    visits_count,
    leads_count,
    round(leads_count / visits_count * 100, 2) as conv
from click_to_lead;

with query as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        row_number()
            over (
                partition by s.visitor_id
                order by s.visit_date desc
            )
        as visit_rank
    from sessions as s
    where s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

lpc as (
	select
	    q.visitor_id,
	    to_char(q.visit_date, 'DD-MM-YYYY') as visit_date,
	    q.utm_source,
	    q.utm_medium,
	    q.utm_campaign,
	    l.lead_id,
	    to_char(l.created_at, 'DD-MM-YYYY') as created_at,
	    l.amount,
	    l.closing_reason,
	    l.status_id
	from query as q
	left join leads as l
	    on
	        q.visitor_id = l.visitor_id
	        and q.visit_date <= l.created_at
	where q.visit_rank = 1
	order by
	    l.amount desc nulls last,
	    q.visit_date asc,
	    q.utm_source asc,
	    q.utm_medium asc,
	    q.utm_campaign asc
),

lead_to_purchase as (
	select 
		cast(count(distinct lead_id) as numeric) as leads_count,
		cast(count(distinct lead_id) filter (where closing_reason = 'Успешно реализовано' or lpc.status_id = 142) as numeric) as purchases_count
	from lpc
)

select 
	leads_count,
	purchases_count,
	round(purchases_count / leads_count * 100, 2) as conv
from lead_to_purchase;