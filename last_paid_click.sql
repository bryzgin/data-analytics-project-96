/* формирование витрины last_paid_click.csv */
with q1 as (
    select
        s.visitor_id as visitor_id,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        s.content as utm_content,
        max(s.visit_date) as visit_date
    from sessions as s
    where s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
    group by
        visitor_id,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content
)

select
    q1.visitor_id,
    q1.utm_source,
    q1.utm_medium,
    q1.utm_campaign,
    l.lead_id,
    l.amount,
    l.closing_reason,
    l.status_id,
    to_char(l.created_at, 'YYYY-MM-DD HH24:MI:SS.MS') as created_at,
    to_char(q1.visit_date, 'YYYY-MM-DD HH24:MI:SS.MS') as visit_date
from q1
left join leads as l
    on
        q1.visitor_id = l.visitor_id
        and q1.visit_date >= l.created_at
order by
    l.amount desc nulls last,
    q1.visit_date asc,
    q1.utm_source asc,
    q1.utm_medium asc,
    q1.utm_campaign asc
limit 10;